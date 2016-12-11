-- bring in the necessary packages
library  ieee;
use  ieee.std_logic_1164.all;
use  ieee.numeric_std.all;
use  ieee.std_logic_unsigned.all;

entity SerialDivider16 is
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
        HexDigits    : buffer std_logic_vector(3 downto 0);

        -- 7-segment segment outputs (all active low, segment a highest bit)
        Segments     : buffer std_logic_vector(6 downto 0);

        -- 4:12 decoder outputs (to 29M16 digit decoder)
        DecoderEn    : buffer std_logic; -- enable for the decoder
        DecoderCntr  : out    std_logic_vector(3 downto 0);

        -- 7-segment digit outputs
        Digits       : out    std_logic_vector(11 downto 0)
    );
end SerialDivider16;

architecture DataFlow of SerialDivider16 is

    type state is (
        init,
        display,
        rotate,
        subtract,
        waitForSub,
        add,
        remainder,
        quotient
    );

    signal Divider      : state;

    signal DigitClkEn   : std_logic;
    signal SubberEn     : std_logic;
    signal AdderEn      : std_logic;
    signal CalculateEn  : std_logic;

    signal MuxCntr      : integer range 0 to (2**10 - 1);

    signal KeypadRDYS   : std_logic_vector(2 downto 0);
    signal HaveKey      : std_logic;

    signal Carry        : std_logic;

    signal Dividend     : std_logic_vector(15 downto 0);
    signal Divisor      : std_logic_vector(15 downto 0);
    signal Quotient     : std_logic_vector(15 downto 0);
    signal Remainder    : std_logic_vector(15 downto 0);

    divide: process (CLK, Reset, Calculate, InDivisor, KeypadRDY, Keypad) is
    begin
        -- Always enable decoder
        DecoderEn <= "1";
        -- On reset, go to a start state
        if (Reset = "0") then
            Digits <= "00000000000";
            MuxCntr <= 0;
            DecoderCntr <= 3;
            Divider <= display;
            Carry <= "0";
        elsif (rising_edge(CLK)) then
            ---------------------------------------------------------------------------------
            -- Enable signals and general flags
            ---------------------------------------------------------------------------------
            DigitClkEn <= (MuxCntr = 2**10 - 1);
            -- Store calculate enable from end of calculate active cycle until first clock
            -- of next mux cycle
            CalculateEn <= Calculate or
                           (CalculateEn and not (DecoderCntr = 3 and MuxCntr = 0));
            -- When adding 16 bits, we need 16 clocks.  We need to add 16 total times, so
            -- we choose a MuxCntr value that occurs 16 times, and is valid for 16
            -- consecutive clocks.  We don't choose "00" here because there are other states
            -- that run during "00".
            SubberEn <= (std_logic_vector(to_unsigned(MuxCntr, 16))(5 downto 4) = "01");
            AdderEn <= (std_logic_vector(to_unsigned(MuxCntr, 16))(5 downto 4) = "11");

            ---------------------------------------------------------------------------------
            -- The digit currently being output
            ---------------------------------------------------------------------------------
            -- Always using low nibble of Dividend to display.  The bits will be
            -- rotated properly elsewhere
            HexDigits <= Dividend(3 downto 0);

            ---------------------------------------------------------------------------------
            -- edge (and key) detection on KeypadRDY
            ---------------------------------------------------------------------------------
            KeypadRDYS(2 downto 1) <= KeypadRDYS(1 downto 0);
            KeypadRDYS(0) <= KeypadRDY;

            -- have a key if have one already that hasn't been processed or a new one
            -- is coming in (rising edge of KeypadRDY), reset if on the last clock of
            -- Digit 3 or Digit 7 (depending on position of InDivisor switch)
            HaveKey <= (KeypadRDYS(2 downto 1) = "01") or
                       (HaveKey and DecoderCntr != 3);

            ---------------------------------------------------------------------------------
            -- Advance mux counter each clock
            -- Advance decoder at 1 kHz, in order 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8
            ---------------------------------------------------------------------------------
            if (DigitClkEn) then
                MuxCntr <= 0;
                -- Advance decoder only once every MuxCntr cycle
                if (DecoderCntr = 0) then
                    DecoderCntr = 7;
                elsif (DecoderCntr = 4) then
                    DecoderCntr = 11;
                elsif (DecoderCntr = 8) then
                    DecoderCntr = 8;
                else
                    DecoderCntr = DecoderCntr - 1;
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

                    if (MuxCntr = 0 and DecoderCntr = 3 and CalculateEn) then
                        -- Start calculation
                        Divider <= init;
                    elsif (DigitClkEn = "1") then
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
                    Remainder <= (others => "0");
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Clear borrow flag in preparation
                    Carry <= "0";

                    -- After initializing, we idly wait until subtract cycle
                    Divider <= remainder;
                ---------------------------------------
                -- Remainder state
                ---------------------------------------
                when remainder =>
                    -- Rotate the remainder for the next round of adding
                    Remainder(15 downto 1) <= Remainder(14 downto 0);
                    Remainder(0) <= Quotient(15);
                    Quotient(15 downto 1) <= Quotient(14 downto 0);
                    Quotient(0) <= "0";
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Clear borrow flag in preparation for subtraction
                    Carry <= "0";

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

                    -- Clear borrow flag in preparation for subtraction
                    Carry <= Carry and not SubberEn;

                    -- We add 16 times, and each requires 16 clocks.  Since we already have
                    -- states that have "00" in (5 downto 4), we arbitrarily choose "01"
                    -- to be when we start adding
                    if (MuxCntr = 0 and DecoderCntr = 3) then
                        Divider <= display;
                    elsif (SubberEn = "1") then
                        Divider <= subtract;
                    elsif (AdderEn = "1" and Carry = "1") then
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
                    Carry <= (    Carry and (Remainder(0) != "1" or  Divisor(0) != "0") or
                             (not Carry and  Remainder(0)  = "1" and Divisor(0)  = "0");

                    -- Rotate remainder and dividend to perform on next bit.
                    Quotient <= Quotient;
                    Remainder(15) <= Carry xor Remainder(0) xor Divisor(0);
                    Remainder(14 downto 0) <= Remainder(15 downto 1);
                    Dividend <= Dividend;
                    Divisor(15) <= Divisor(0);
                    Divisor(14 downto 0) <= Divisor(15 downto 1);

                    -- Keep adding until no longer in subtract state
                    if (SubberEn = "1") then
                        Divider <= subtract;
                    else
                        Divider <= quotient;
                    end if;
                ---------------------------------------
                -- Quotient state
                ---------------------------------------
                when quotient =>
                    -- We put a 1 in the quotient if difference is positive, 0 otherwise.
                    -- This is the inverse of the borrow flag.
                    Quotient(15 downto 1) <= Quotient(15 downto 1);
                    Quotient(0) <= not Carry;
                    Remainder <= Remainder;
                    Dividend <= Dividend;
                    Divisor <= Divisor;

                    -- Reset borrow
                    Carry <= Carry;

                    -- After shifting quotient, we idly wait until add or subtract cycle
                    Divider <= waitForSub;
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

                    -- Set carry flag for next iteration
                    Carry <= (Remainder(0) and Divisor(0)) or
                             (Carry xor Divisor(0)) or
                             (Carry xor Remainder(0));

                    -- Stay here until enable signal goes away
                    if (AdderEn = "1") then
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
                    Dividend(15 downto 12) <= Quotient( 3 downto 0);
                    Dividend(11 downto  4) <= Dividend(15 downto 8);
                    if (HaveKey = "1" and ((DecoderCntr = 3 and not InDivisor)  or
                                           (DecoderCntr = 7 and     InDivisor)) then
                        Dividend(3 downto 0) <= Keypad;
                    else
                        Dividend(3 downto 0) <= Dividend(7 downto 4);
                    end if;
                    Divisor(15 downto 12)  <= Dividend( 3 downto 0);
                    Divisor(11 downto  0)  <= Divisor(15 downto 4);
                    Quotient(15 downto 12) <= Divisor( 3 downto 0);
                    Quotient(11 downto  0) <= Quotient(15 downto 4);

                    -- Carry doesn't matter
                    Carry <= "0";

                    -- Continue displaying normally
                    if (CalculateEn = "1" and MuxCntr = 0 and DecoderCntr = 3) then
                        -- Only start division when we are at beginning of a 1kHz cycle and have
                        -- gotten a calculate signal
                        Divider <= init;
                    else
                        Divider <= display;
                    end if;
            end case;
        end if;
    end process divide;
end DataFlow;
