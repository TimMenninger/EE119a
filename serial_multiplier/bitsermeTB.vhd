---------------------------------------------------------------------------------------------
--
--  Test Bench for BitSerialMultiplier
--
--  This is a test bench for the BitSerialMultiplier entity.  The test bench tests
--  the multiplication of 0 in both the multiplicand and the multiplier.  It also multipleis
--  255 by 255 (this assumes the number of bits is set to 8), which shows that there is no
--  overflow.  Finally, it multiples 15 by 15 to show that leftmore zeroes still appear in
--  the output.
--
--
--  Revision History:
--      4/11/00  Automated/Active-VHDL    Initial revision.
--      4/11/00  Glen George              Modified to add documentation and
--                                           more extensive testing.
--      4/12/00  Glen George              Added more complete testing.
--      4/16/02  Glen George              Updated comments.
--      4/18/04  Glen George              Updated comments and formatting.
--     11/21/05  Glen George              Updated comments and formatting.
--     12/08/16  Tim Menninger            Copied from RLLEncTB and adapted to test bitserme
--
---------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity bitserialmultiplier_tb is
    generic (
        numTests : integer := 5,
        numBits  : integer := 8
    );
end bitserialmultiplier_tb;

architecture TB_ARCHITECTURE of bitserialmultiplier_tb is
    -- Component declaration of the tested unit
    component BitSerialMultiplier
        port(
            A      :  in      std_logic_vector((numbits - 1) downto 0);     -- multiplicand
            B      :  in      std_logic_vector((numbits - 1) downto 0);     -- multiplier
            START  :  in      std_logic;                                    -- start calculation
            CLK    :  in      std_logic;                                    -- clock
            Q      :  buffer  std_logic_vector((2 * numbits - 1) downto 0); -- product
            DONE   :  out     std_logic
        );
    end component;

    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  A      :  std_logic_vector((numbits - 1) downto 0);     -- multiplicand
    signal  B      :  std_logic_vector((numbits - 1) downto 0);     -- multiplier
    signal  START  :  std_logic;                                    -- start calculation
    signal  CLK    :  std_logic;                                    -- clock

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  Q      :  std_logic_vector((2 * numbits - 1) downto 0); -- product
    signal  DONE   :  std_logic;

    --Signal used to stop clock signal generators
    signal  END_SIM     :  BOOLEAN := FALSE;


begin

    -- Unit Under Test port map
    UUT : BitSerialMultiplier
        port map(
            A      => A,
            B      => B,
            START  => START,
            CLK    => CLK,
            Q      => Q,
            DONE   => DONE
        );


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i  :  integer;        -- general loop index

        -- inputs for A (numBits bits each)
        signal TestVectorA : std_logic_vector(numTests*numBits - 1 downto 0)
            :=  "00000000" &
                "00000000" &
                "10101010" &
                "11111111" &
                "00001111";
        -- inputs for B (numBits bits each)
        signal TestVectorB : std_logic_vector(numTests*numBits - 1 downto 0)
            :=  "00000000" &
                "10101010" &
                "00000000" &
                "11111111" &
                "00001111";
        -- outputs for each Q = A * B (2*numBits bits each)
        signal TestVectorQ : std_logic_vector(numTests*2*numBits - 1 downto 0)
            :=  "0000000000000000" &
                "0000000000000000" &
                "0000000000000000" &
                "1111111000000001" &
                "0000000011100001";

    begin  -- of stimulus process

        -- initially input is X and mutliplier shouldn't start
        START  <= '0';
        A      <= 'X';
        B      <= 'X';

        -- run for a few clocks
        wait for 100 ns;

        for  i  in  0  to  (numTests-1)  loop
            -- Set A and B inputs (multiplicand and multiplier)
            A <= TestVectorA((numTests-i)*numBits-1 downto (numTests-i-1)*numBits);
            B <= TestVectorB((numTests-i)*numBits-1 downto (numTests-i-1)*numBits);

            -- run for a few clocks before starting
            wait for 100 ns;
            START <= '1';

            -- After a few clocks, clear START
            wait for 100 ns;
            START <= '0';

            -- let the multiplication occur (occurs in ~2n^2.  Give twice that many clocks)
            wait for 4*numBits*numBits*20 ns;

            -- check the output (from old input value)
            assert (std_match(DONE, '1');
                    report  "DONE Output Test Failure"
                    severity  ERROR;
            assert (std_match(Q,
                TestVectorQ((numTests-i)*2*numBits-1 downto (numTests-i-1)*2*numBits)));
                    report  "Product Q Output Test Failure"
                    severity  ERROR;

        end loop;

        END_SIM <= TRUE;        -- end of stimulus events
        wait;                   -- wait for simulation to end

    end process; -- end of stimulus process


    CLOCK_CLK : process

    begin

        -- this process generates a 20 ns period, 50% duty cycle clock

        -- only generate clock if still simulating

        if END_SIM = FALSE then
            CLK <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            CLK <= '1';
            wait for 10 ns;
        else
            wait;
        end if;

    end process;


end TB_ARCHITECTURE;
