-- bring in the necessary packages
library  ieee;
use  ieee.std_logic_1164.all;
use  ieee.numeric_std.all;
use  ieee.std_logic_unsigned.all;

---------------------------------------------------------------------------------------------
--
-- SerialDivider
--
-- This performs a 16-bit serial division.  The algorithm used works as such:
--     (1) Load the dividend into the quotient registers and zero the remainder.
--     (2) Shift the remainder and quotient left one each, putting the high bit of the
--         quotient into the low bit of the remainder.
--     (3) Subtract the divisor from the remainder.  If the difference is positive, put a 1
--         in the low bit of quotient.  Otherwise, put a 0 and add the divisor back to the
--         remainder.
--     (4) Repeat from step 2 for all 16 bits.
-- The quotient is displayed on the third (bottom) row of the board.  Unused outputs are
-- tri-stated.
--
-- Inputs:
--    CLK - 1 MHz clock
--    Reset - Active low reset
--    Calculate - Active low signal to dictate start of division
--    InDivisor - High when inputs are divisor, low when inputs are dividend
--    KeypadRDY - Active high, goes active when a key is available
--    Keypad - The 4-bit value of the key pressed
--    KeypadRows - The raw keypad row inputs (UNUSED)
--
-- Outputs:
--    KeypadCols - The raw keypad column outputs if scanning done (UNUSED)
--    HexDigits - The hex value of the digit to display on current digit in mux
--    Segments - Active low outputs to 7-segment display (UNUSED)
--    DecoderEn - Active high enable signal to decoder
--    DecoderCntr - LED digit number
--    Digits - The 7-segment digit outputs (UNUSED)
--
-- Revisions:
--    12/11/16 - Tim Menninger: Created
--
entity SerialDivider is
    port (
        -- Clock input 1 MHz
        CLK          : in     std_logic;

        -- reset input
        Reset        : in     std_logic; -- active low reset signal (for
                                         --   testing) tied high in hardware
        -- switch inputs
        Calculate    : in     std_logic; -- calculate the quotient
        InDivisor    : in     std_logic; -- input the divisor (not the dividend)

        -- keypad inputs (RDY --> key available)
        KeypadRDY    : in     std_logic;
        Keypad       : in     std_logic_vector(3 downto 0);

        -- keypad scanning inputs
        KeypadRows   : in     std_logic_vector(3 downto 0);

        -- keypad scanning outputs
        KeypadCols   : out    std_logic_vector(3 downto 0);

        -- Hex digit outputs (to 16L8 seven segment decoder)
        HexDigits    : out    std_logic_vector(3 downto 0);

        -- 7-segment segment outputs (all active low, segment a highest bit)
        Segments     : out    std_logic_vector(6 downto 0);

        -- 4:12 decoder outputs (to 29M16 digit decoder)
        DecoderEn    : out    std_logic; -- enable for the decoder
        DecoderCntr  : buffer std_logic_vector(3 downto 0);

        -- 7-segment digit outputs
        Digits       : out    std_logic_vector(11 downto 0)
    );
end SerialDivider;

architecture DataFlow of SerialDivider is

    --
    -- type state
	--
	-- State machine governing the serial division
	--     init: This sets up the variables in preparation for performing division
	--     display: This just does nothing but hold the previous values
	--     rotate: This rotates the values so the mux can work
	--     subtract: This subtracts divisor from remainder so we know whether to
	--         load a 1 or 0 into the quotient.
	--     waitForSub: Wait states while nothing should be happening
	--     add: This adds the divisor back to the remainder if the remainder was
	--         negative.
	--     shiftRemainder: Shifts the remainder to consider the next quotient bit
	--
    type state is (
        init,
        display,
        rotate,
        subtract,
        waitForSub,
        add,
        shiftRemainder
    );

    --
	-- signals
	--
	--     Divider: State machine for serial division.
	--     highBit: Maintains the high bit, which we compare to know whether the mux has
	--         cycled back to the beginning.
	--     enableAS: Used to determine when we should start adding or subtracting
	--     KeypadRDYS: Signal used to catch edge of keypress
	--     Carry: Carry flag for add and subtract operations
	--     Dividend: The dividend of the operation
	--     Divisor: The divisor in the division
	--     Quotient: The output quotient
	--     Remainder: The remainder from division
	--
    signal Divider      : state;

    signal highBit      : std_logic;
    signal enableAS     : std_logic;

    signal MuxCntr      : unsigned(9 downto 0);

    signal KeypadRDYS   : std_logic;

    signal Carry        : std_logic;

    signal Dividend     : std_logic_vector(15 downto 0);
    signal Divisor      : std_logic_vector(15 downto 0);
    signal Quotient     : std_logic_vector(15 downto 0);
    signal Remainder    : std_logic_vector(15 downto 0);

begin

    divide: process (CLK, Reset, Calculate, InDivisor, KeypadRDY, Keypad) is
    begin
        -- Always enable decoder
        DecoderEn <= '1';
        -- Always disable unused outputs
        KeypadCols <= "ZZZZ";
        Segments <= "ZZZZZZZ";
        Digits <= "ZZZZZZZZZZZZ";

        ---------------------------------------------------------------------------------
        -- The digit currently being output
        ---------------------------------------------------------------------------------
        -- Always using low nibble of Dividend to display.  The bits will be
        -- rotated properly elsewhere
        HexDigits <= Dividend(3 downto 0);

        -- On reset, go to a start state
        if (Reset = '0') then
            MuxCntr <= to_unsigned(0, 10);
            DecoderCntr <= "0011";
            Divider <= display;
            Carry <= '0';
                KeypadRDYS <= '0';
                enableAS <= '0';
                highBit <= '0';
        elsif (rising_edge(CLK)) then
            ---------------------------------------------------------------------------------
            -- Enable signals and general flags
            ---------------------------------------------------------------------------------
            -- Enable signal for adding/subtracting on edges of MuxCntr bit 5
            enableAS <= MuxCntr(5);
            -- Digit Clock enable signal once per cycle, which will be when high bit goes
            -- from high to low (could have also been low to high)
            highBit <= MuxCntr(9);

            ---------------------------------------------------------------------------------
            -- edge (and key) detection on KeypadRDY
            ---------------------------------------------------------------------------------
            -- have a key if have one already that hasn't been processed or a new one
            -- is coming in (rising edge of KeypadRDY), reset if on the last clock of
            -- Digit 3 or Digit 7 (depending on position of InDivisor switch)
            if ((DecoderCntr = "0011" and MuxCntr = 1 and InDivisor = '0') or
                (DecoderCntr = "0111" and MuxCntr = 1 and InDivisor = '1')) then
            KeypadRDYS <= KeypadRDY;
            else
                KeypadRDYS <= KeypadRDYS;
            end if;

            ---------------------------------------------------------------------------------
            -- Advance mux counter each clock
            -- Advance decoder at 1 kHz, in order 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8
            ---------------------------------------------------------------------------------
            if (MuxCntr = (2**10 - 1)) then
                MuxCntr <= to_unsigned(0, 10);
                -- Advance decoder only once every MuxCntr cycle
                if (DecoderCntr(1 downto 0) = "00") then
                    DecoderCntr(3) <= DecoderCntr(2);
                    DecoderCntr(2) <= DecoderCntr(3) nand DecoderCntr(2);
                    DecoderCntr(1 downto 0) <= "11";
                else
                    DecoderCntr(3 downto 2) <= DecoderCntr(3 downto 2);
                    DecoderCntr(1) <= DecoderCntr(0) and DecoderCntr(1);
                    DecoderCntr(0) <= not DecoderCntr(0);
                end if;
            else
                MuxCntr <= MuxCntr + 1;
                DecoderCntr <= DecoderCntr;
            end if;

            ---------------------------------------------------------------------------------
            -- Advance state machine and do division
            ---------------------------------------------------------------------------------
            case Divider is
                ---------------------------------------
                -- Display state
                ---------------------------------------
                when display =>
                    -- Keep everything the same
                    Quotient <= Quotient;
                    Remainder <= Remainder;
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    if (highBit = '1' and MuxCntr(9) = '0') then
                        -- rotate display, bringing in new key if necessary
                        Divider <= rotate;
                    else
                        -- Not starting division, stay here
                        Divider <= display;
                    end if;
                ---------------------------------------
                -- Init state
                ---------------------------------------
                when init =>
                    -- Zero the outputs and maintian inputs
                    Quotient <= Dividend;
                    Remainder <= (others => '0');
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Don't need an enable signal
                    enableAS <= MuxCntr(5);

                    -- Clear borrow flag in preparation
                    Carry <= '0';

                    -- After initializing, we idly wait until subtract cycle
                    Divider <= shiftRemainder;
                ---------------------------------------
                -- Remainder state
                ---------------------------------------
                when shiftRemainder =>
                    -- Rotate the remainder for the next round of adding
                    Remainder(15 downto 1) <= Remainder(14 downto 0);
                    Remainder(0) <= Quotient(15);
                    Quotient(15 downto 1) <= Quotient(14 downto 0);
                    Quotient(1) <= '0';
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Don't need an enable signal
                    enableAS <= MuxCntr(5);

                    -- Clear borrow flag in preparation for subtraction
                    Carry <= '0';

                    -- After shifting remainder, we idly wait until subtract cycle
                    Divider <= waitForSub;
                ---------------------------------------
                -- WaitForSub state
                ---------------------------------------
                when waitForSub =>
                    -- Idle in this state, change nothing
                    Quotient <= Quotient;
                    Remainder <= Remainder;
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Enable signal goes on bit 5 of mux counter
                    enableAS <= MuxCntr(5);

                    -- Maintain carry flag
                    Carry <= Carry;

                    -- We add 16 times, and each requires 16 clocks.  Since we already have
                    -- states that have "00" in (5 downto 4), we arbitrarily choose "01"
                    -- to be when we start adding
                    if (highBit = '1' and MuxCntr(9) = '0') then
                        -- Done with division, rotate for mux before going back to display.
                        -- This will reinitiate the division if Calculate is still active
                        Divider <= rotate;
                    elsif (MuxCntr(5) = '0') then
                        Divider <= subtract;
                    elsif (MuxCntr(5) = '1' and Carry = '1') then
                        Divider <= add;
                    else
                        Divider <= waitForSub;
                    end if;
                ---------------------------------------
                -- Subtract state
                ---------------------------------------
                when subtract =>
                    -- Want sign of subtracting divisor from accumulated remainder.  We
                    -- do this by simulating the "borrow" flag.  If we must borrow from
                    -- the next bit that we don't have, the difference is negative.
                    -- Here, Quotient(0) holds not Carry.
                    if (Quotient(0) = '0' and (Remainder(0) /= '1' or  Divisor(0) /= '0')) or
                       (Quotient(0) = '1' and  Remainder(0)  = '1' and Divisor(0)  = '0') then
                        Quotient(0) <= '0';
                    else
                        Quotient(0) <= '1';
                    end if;

                    Carry <= Carry;

                    -- Rotate remainder and dividend to perform on next bit.
                    Quotient(15 downto 1) <= Quotient(15 downto 1);
                    Remainder(15) <= (not Quotient(0)) xor Remainder(0) xor Divisor(0);
                    Remainder(14 downto 0) <= Remainder(15 downto 1);
                    Dividend <= Dividend;
                    Divisor(15) <= Divisor(0);
                    Divisor(14 downto 0) <= Divisor(15 downto 1);

                    -- Enable signal goes on bit 4 of mux counter
                    enableAS <= MuxCntr(5);

                    -- Keep adding until no longer in subtract state
                    if (MuxCntr(4) = '0') then
                        Divider <= subtract;
                    else
                        Divider <= waitForSub;
                    end if;
                ---------------------------------------
                -- Add state
                ---------------------------------------
                when add =>
                    -- Have to add divisor back in so we can maintain remainder
                    Quotient <= Quotient;
                    Dividend <= Dividend;
                    Divisor <= Divisor;
                    Remainder(14 downto 0) <= Remainder(15 downto 1);
                    Remainder(15) <= Carry xor Remainder(0) xor Divisor(0);

                    -- Enable signal goes on bit 4 of mux counter
                    enableAS <= MuxCntr(5);

                    -- Set carry flag for next iteration
                    Carry <= (Remainder(0) and Divisor(0)) or
                             (Carry and Divisor(0)) or
                             (Carry and Remainder(0));

                    -- Stay here until enable signal goes away
                    if (MuxCntr(4) = '0') then
                        Divider <= add;
                    else
                        Divider <= waitForSub;
                    end if;
                ---------------------------------------
                -- Rotate state
                ---------------------------------------
                when rotate =>
                    -- We aren't computing new values for division, but at 1kHz, we are
                    -- muxing to next digit, which we do by rotating everything 4 bits.
                    -- Similarly, if there is a new key to be read from input, rotate values
                    -- and input it to low nibble of appropriate vector
                    if (KeypadRDYS = '0' and KeypadRDY = '1' and
                                          ((DecoderCntr = 3 and InDivisor = '1')  or
                                           (DecoderCntr = 7 and InDivisor = '0'))) then
                        -- If we are shifting in a new number, we do an extra shift so that
                        -- it appears as if we are putting in the ones digit
                        Dividend(15 downto 12) <= Dividend(15 downto 12);
                        Dividend(11 downto 8) <= Dividend(11 downto 8);
                        Dividend(7 downto 4) <= Dividend(7 downto 4);
                        Dividend(3 downto 0) <= Keypad;
                    else
                       -- Otherwise, do a normal rotate to continue the mux
                        Dividend(15 downto 12) <= Quotient( 3 downto 0);
                        Dividend(11 downto  4) <= Dividend(15 downto 8);
                        Dividend(3 downto 0) <= Dividend(7 downto 4);
                    end if;
                    Divisor(15 downto 12)  <= Dividend( 3 downto 0);
                    Divisor(11 downto  0)  <= Divisor(15 downto 4);
                    Quotient(15 downto 12) <= Divisor( 3 downto 0);
                    Quotient(11 downto  0) <= Quotient(15 downto 4);
                    Remainder(15 downto 12) <= Remainder( 3 downto 0);
                    Remainder(11 downto  0) <= Remainder(15 downto 4);

                    -- Enable signal goes on bit 4 of mux counter
                    enableAS <= MuxCntr(5);

                    -- Carry doesn't matter
                    Carry <= Carry;

                    -- Continue displaying normally
                    if (Calculate = '0' and ((DecoderCntr = "0011" and InDivisor = '0') or
                                             (DecoderCntr = "0111" and InDivisor = '1'))) then
                        -- Only start division when we are at beginning of a 1kHz cycle and
                        -- have gotten a calculate signal.  Also note that the only
                        -- transitions into this state are on minimum MuxCntr, which means
                        -- that MuxCntr is necessarily 1
                        Divider <= init;
                    else
                        Divider <= display;
                    end if;
            end case;
        end if;
    end process divide;
end DataFlow;
