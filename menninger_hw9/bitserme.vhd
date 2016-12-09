-- bring in the necessary packages
library  ieee;
use  ieee.std_logic_1164.all;
use  ieee.numeric_std.all;
use  ieee.std_logic_unsigned.all;

---------------------------------------------------------------------------------------------
--
--  n-bit Bit-Serial Multiplier
--
--  This is an implementation of an n-bit bit serial multiplier.  The
--  calculation will take 2n^2 clocks after the START signal is activated.
--  The multiplier is implemented with a single adder.  This file contains
--  only the entity declaration for the multiplier.
--
--  Parameters:
--      numbits - number of bits in the multiplicand and multiplier (n)
--
--  Inputs:
--      A       - n-bit unsigned multiplicand
--      B       - n-bit unsigned multiplier
--      START   - active high signal indicating a multiplication is to start
--      CLK     - clock input (active high)
--
--  Outputs:
--      Q       - (2n-1)-bit product (multiplication result)
--      DONE    - active high signal indicating the multiplication is complete
--                and the Q output is valid
--
--
--  Revision History:
--      7 Apr 00  Glen George       Initial revision.
--     12 Apr 00  Glen George       Changed Q to be type buffer instead of
--                                  type out.
--     21 Nov 05  Glen George       Changed nobits to numbits for clarity
--                                  and updated comments.
--      7 Dec 16  Tim Menninger     Implemented serial multiplier state machine
--
---------------------------------------------------------------------------------------------

entity  BitSerialMultiplier  is

    generic (
        numbits  :  integer := 8    -- number of bits in the inputs
    );

    port (
        A      :  in      std_logic_vector((numbits - 1) downto 0);     -- multiplicand
        B      :  in      std_logic_vector((numbits - 1) downto 0);     -- multiplier
        START  :  in      std_logic;                                    -- start calculation
        CLK    :  in      std_logic;                                    -- clock
        Q      :  buffer  std_logic_vector((2 * numbits - 1) downto 0); -- product
        DONE   :  out     std_logic                                     -- calc completed
    );

end  BitSerialMultiplier;

--
-- DataFlow architecture
--
-- Defines the state machine that performs the n-bit serial multiplier.
--
-- Inputs:  A - Multiplicand
--          B - Multiplier
--          START - Goes active when multiplication should start
--
-- Outputs: Q - Product of A and B
--          DONE - Set when the Q output is valid.
--
architecture DataFlow of BitSerialMultiplier is

    --
    -- Types
    --
    -- state: State machine for serial multiplier.
    --      states:
    --          idle     - Holds the output Q value, and asserts DONE.
    --          setup    - Sets up local signals in preparation for serial multiplication
    --          adder    - Full adder, used to compute carry bits and sum bits
    --          multiply - Puts the low bit of the sum into the output and multiplies the
    --                     multiplicand by next bit in multiplier
    --
    type multiplyState is (idle, setup, adder, multiply);

    --
    -- Signals
    --
    -- currentState (state): State machine controlling multiplication
    -- Y (std_logic_vector): A copy of the original input, B, that we use to generate each
    --      partial product.
    -- carryBits (std_logic_vector): Contains the carry bits generated from the full adder
    --      on each bit.  The low bit will always be 0, which helps facilitate adding the
    --      low bit using the same full adder.
    -- sumBits (std_logic_vector): Contains the sum bits generated from the full adder.  For
    --      the first iteration, this will contain A.  After each set of full-adding, the
    --      low bit of this is put into the output and then this is shifted right, leaving
    --      the high bit 0 for the next addition.
    -- partial (std_logic_vector): Contains the partial product, which is A if the current
    --      bit in B (a.k.a Y) is 1, and 0 otherwise.
    -- bitsAdded (integer): Counts how many of the bits we have full-added on a given
    --      iteration.  On each addition, we need numbits full adder iterations.
    -- bitsMultiplied (integer): Counts how many bits in the product have been set.  This
    --      will count to 2*numbits.
    --
    signal currentState                 : multiplyState;
    signal Y                            : std_logic_vector((numbits - 1) downto 0);
    signal carryBits, sumBits, partial  : std_logic_vector(numbits downto 0);
    signal bitsAdded                    : integer range 0 to numbits;
    signal bitsMultiplied               : integer range 0 to 2*numbits;

begin
    --
    -- multiplyBits process
    --
    -- This process takes care of the state machine state and the DONE signal.  Whenever the
    -- state machien is in its idle state, DONE is active.  The way to get out of this state
    -- is if START is active.  It then goes to setup to initialize values, then for each
    -- of 2*numBits multiply state occurrences (one for each product bit), it goes through
    -- numBits+1 adder states with DONE inactive.  After the last multiply state, it goes
    -- back to the idle state.  There is no reset.  Once the state machine leaves idle,
    -- it will go through all states.  States only change on the rising edge of the global
    -- CLK input.
    --
    -- This is the state machine that does multiplication.  It defines each state.  It is
    -- left to another process to define when to be in which state.  The definition of each
    -- state can be found in the state type header.
    --
    -- Inputs:  CLK - State machine only changes values on rising edge of CLK
    --          A - Multiplicand for product
    --          B - Multiplier for product
    --
    -- Outputs: Q - The product of A and B is generated and output in Q.
    --
    multiplyBits: process (CLK, A, B) is
    begin
        -- Only active on rising edge of CLK
        if (rising_edge(CLK)) then
            -- State machine
            case currentState is
                ---------------------------
                -- idle state
                ---------------------------
                when idle =>
                    DONE <= '1';
                    -- Maintain Q
                    Q <= Q;
                    -- Using low 2 bits of B in partial products, so shift right twice before
                    -- loading into Y register as initial value
                    Y((numbits-3) downto 0) <= B((numbits-1) downto 2);
                    Y((numbits-1) downto (numbits-2)) <= "00";
                    -- Initialize everything else to 0, although values don't really matter
                    carryBits <= std_logic_vector(to_unsigned(0, numbits+1));
                    sumBits <= std_logic_vector(to_unsigned(0, numbits+1));
                    partial <= std_logic_vector(to_unsigned(0, numbits+1));
                    -- Set these to initial values
                    bitsAdded <= 0;
                    bitsMultiplied <= 0;
                    -- Stay in idle state until START goes active
                    if (START = '1') then
                        currentState <= setup;
                    else
                        currentState <= idle;
                    end if;
                ---------------------------
                -- setup state
                ---------------------------
                when setup =>
                    DONE <= '0';
                    -- Initialize Q output to all 0s
                    Q <= std_logic_vector(to_unsigned(0, 2*numbits));
                    -- Same initial value as in idle
                    Y((numbits-3) downto 0) <= B((numbits-1) downto 2);
                    Y((numbits-1) downto (numbits-2)) <= "00";
                    -- Nothing carried yet
                    carryBits <= (numbits downto 0 => '0');
                    -- Sum bits will be partial product from low bit of B
                    sumBits(numbits) <= '0';
                    if (B(0) = '0') then
                        sumBits((numbits - 1) downto 0) <=
                            A and std_logic_vector(to_unsigned(0, numbits));
                    else
                        sumBits((numbits - 1) downto 0) <=
                            A and std_logic_vector(to_unsigned(-1, numbits));
                    end if;
                    -- Partial bits will be partial product from second-lowest bit of B
                    if (B(1) = '0') then
                        partial(numbits downto 1) <=
                            A and std_logic_vector(to_unsigned(0, numbits));
                    else
                        partial(numbits downto 1) <=
                            A and std_logic_vector(to_unsigned(-1, numbits));
                    end if;
                    partial(0) <= '0';
                    -- Only stay in setup state for one clock
                    currentState <= adder;
                    -- Initial values
                    bitsAdded <= 0;
                    bitsMultiplied <= 0;
                ---------------------------
                -- adder state
                ---------------------------
                when adder =>
                    DONE <= '0';
                    -- Maintaining Q and Y
                    Q <= Q;
                    Y <= Y;
                    -- Rotate carry and sum for next full adder iteration
                    carryBits((numbits-1) downto 0) <= carryBits(numbits downto 1);
                    sumBits((numbits-1) downto 0) <= sumBits(numbits downto 1);
						  partial((numbits-1) downto 0) <= partial(numbits downto 1);
                    -- Cout of full adder of partial products (one of which is sum).  Cin for
                    -- the full adder comes from the carryBits vector.  This will be loaded
                    -- into the carryBits vector
                    carryBits(numbits) <= (carryBits(0) and (sumBits(0) or partial(0))) or
                                          (sumBits(0) and partial(0));
                    -- Sum of full adder of partial products (one of which is sum).  Cin for
                    -- the full adder comes from the carryBits vector.  This will be loaded
                    -- into the sumBits vector
                    sumBits(numbits) <= carryBits(0) xor sumBits(0) xor partial(0);
						  partial(numbits) <= '0';
                    -- Maintain value for next round of multiply state
                    bitsMultiplied <= bitsMultiplied;
                    -- Stay in adder state for numbits iterations before moving to multiply
                    if (bitsAdded = numbits) then
                        currentState <= multiply;
                        bitsAdded <= 0;
                    else
                        currentState <= adder;
                        bitsAdded <= bitsAdded + 1;
                    end if;
                ---------------------------
                -- multiply state
                ---------------------------
                when multiply =>
                    DONE <= '0';
                    -- Rotate product for next multiply state
                    Q((2*numbits-2) downto 0) <= Q((2*numbits-1) downto 1);
                    -- Load low bit of sum into product
                    Q(2*numbits-1) <= sumBits(0);
                    -- Shift sum bits for next adder
                    sumBits((numbits-1) downto 0) <= sumBits(numbits downto 1);
                    sumBits(numbits) <= '0';
                    -- Load next partial prodcut
                    if (Y(0) = '0') then
                        partial(numbits downto 1) <=
                            A and std_logic_vector(to_unsigned(0, numbits));
                    else
                        partial(numbits downto 1) <=
                            A and std_logic_vector(to_unsigned(-1, numbits));
                    end if;
                    partial(0) <= '0';
                    -- Rotate B input for next partial product
                    Y((numbits-2) downto 0) <= Y((numbits-1) downto 1);
                    Y(numbits-1) <= '0';
                    -- Initial state of bitsAdded before moving back to adder state
                    bitsAdded <= 0;
                    -- Stay in multiply for one clock.  If done multiplication, move back
                    -- to idle.  Otherwise, go for next round of adder
                    if (bitsMultiplied = 2*numbits - 1) then
                        currentState <= idle;
                        bitsMultiplied <= 0;
                    else
                        currentState <= adder;
                        bitsMultiplied <= bitsMultiplied + 1;
                    end if;
            end case;
        end if;
    end process;

end DataFlow;
