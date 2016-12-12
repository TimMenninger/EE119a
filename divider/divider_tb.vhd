----------------------------------------------------------------------------
--
--  Test Bench for SerialDivider
--
--  This is a test bench for the SerialDivider entity.  It tests that the
--  counters work properly and that it gets the correct output when dividing.
--  It also checks for proper muxing.
--
--  Revision History:
--      4/4/00   Automated/Active-VHDL    Initial revision.
--      4/4/00   Glen George              Modified to add documentation and
--                                           more extensive testing.
--      4/6/04   Glen George              Updated comments.
--     11/21/05  Glen George              Updated comments and formatting.
--     12/11/16  Tim Menninger            Adapted for use with serial divider
--
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity serialdivider_tb is
end serialdivider_tb;

architecture TB_ARCHITECTURE of serialdivider_tb is

    -- Component declaration of the tested unit
    component SerialDivider
        port(
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
    end component;

    -- Stimulus signals
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

    -- Signal used to stop clock signal generators
    signal  END_SIM  :  BOOLEAN := FALSE;
    -- Test Input/Output Vectors
    signal  DecoderVector  :  std_logic_vector(0 to 47)
                           := "001100100001000001110110010101001011101010011000";
    -- Divide 1010101010101001 by 0010101010101010.  We should get 100 remainder 1.
    signal  Dividend  : std_logic_vector (0 to 15) := "1010" & "1010" & "1010" & "1001";
    signal  Divisor   : std_logic_vector (0 to 15) := "0010" & "1010" & "1010" & "1010";
    signal  Quotient  : std_logic_vector (0 to 15) := "0000" & "0000" & "0000" & "0100";
    signal  Remainder : std_logic_vector (0 to 15) := "0000" & "0000" & "0000" & "0001";


begin

    -- Unit Under Test port map
    UUT : SerialDivider
        port map  (
            CLK          => CLK;
            Reset        => Reset;
            Calculate    => Calculate;
            InDivisor    => InDivisor;
            KeypadRDY    => KeypadRDY;
            Keypad       => Keypad;
            KeypadRows   => KeypadRows;
            KeypadCols   => KeypadCols;
            HexDigits    => HexDigits;
            Segments     => Segments;
            DecoderEn    => DecoderEn;
            DecoderCntr  => DecoderCntr;
            Digits       => Digits
        );


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i, j, k  :  integer;        -- general loop index



    begin  -- of stimulus process

        -- initially everything is X and there is a clear (active low)
        Reset       <= '0';
        Calculate   <= 'X';
        InDivisor   <= 'X';
        KeypadRDY   <= 'X';
        Keypad      <= "XXXX";
        KeypadRows  <= "XXXX";

        -- run for a few clocks
        wait for 100 ns;

        ---------------------------------------------------------------------------------
        --
        -- Decoder tests
        --
        Reset <= '1';

        -- After 2^10 clocks, decoder should update.  The order is
        -- 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8
        for i in 0 to 11 loop
            -- Check that it updated, starting with initial value of 3
            std_match(DecoderCntr, DecoderVector(i*4 to (i+1)*4-1))
                report  "Reset Failure"
                severity  ERROR;
            -- Update counter
            for j in 0 to 2**10+1 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;

        ---------------------------------------------------------------------------------
        --
        -- Keypad tests
        --
        Reset <= '0';
        wait for 100 ns;

        -- Put value on the keypad.  We should see that it is part of the mux at LED
        -- position 3
        InDivisor <= '0';
        Keypad <= "0101";
        KeypadRDY <= '0';
        wait for 100 ns;
        Reset <= '1';
        KeypadRDY <= '1';

        -- Need to let the machine run 12 mux cycles
        for i in 0 to 11 loop
            -- Update counter
            for j in 0 to 2**10+10 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;
        -- Mux cycle should be on digit 3, which means we should be able to see what we put
        std_match(HexDigits, "0101")
            report  "Input Dividend Failure"
            severity  ERROR;

        -- Now testing that it works for the divisor
        -- Put two values on the keypad.  We should see that it is part of the mux at LED
        -- position 3 and 2
        InDivisor <= '1';
        Keypad <= "1010";
        KeypadRDY <= '0';
        wait for 100 ns;
        Reset <= '1';
        KeypadRDY <= '1';

        -- Need to let the machine run 12 mux cycles
        for i in 0 to 11 loop
            -- Update counter
            for j in 0 to 2**10+10 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;
        -- Should still have first digit
        std_match(HexDigits, "0101")
            report  "Input Divisor, Dividend Failure"
            severity  ERROR;
        -- Run mux cycle 4 more times so we are now looking at first digit in divisor
        for i in 0 to 3 loop
            -- Update counter
            for j in 0 to 2**10+10 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;
        -- Should still have first digit
        std_match(HexDigits, "1010")
            report  "Input Divisor Failure"
            severity  ERROR;

        ---------------------------------------------------------------------------------
        --
        -- Dividing tests
        --
        -- Load divisor and dividend
        Reset <= '0';
        for k in 0 to 3 loop
            InDivisor <= '0';
            Keypad <= Dividend(k*4 to (k+1)*4-1);
            wait for 100 ns;
            Reset <= '1';
            KeypadRDY <= '0';
            wait for 10 ns;
            KeypadRDY <= '1';

            -- Need to let the machine run 12 mux cycles
            for i in 0 to 11 loop
                -- Update counter
                for j in 0 to 2**10 loop
                    -- Cycle clock
                    wait for 20 ns;
                end loop;
            end loop;
        end loop;
        -- Load divisor
        for k in 0 to 3 loop
            InDivisor <= '1';
            Keypad <= Divisor(k*4 to (k+1)*4-1);
            KeypadRDY <= '0';
            wait for 100 ns;
            KeypadRDY <= '1';

            -- Need to let the machine run 12 mux cycles
            for i in 0 to 11 loop
                -- Update counter
                for j in 0 to 2**10 loop
                    -- Cycle clock
                    wait for 20 ns;
                end loop;
            end loop;
        end loop;
        -- Check quotient, which is 8th through 12th digit
        for i in 0 to 7 loop
            -- Update counter to get to right mux digit
            for j in 0 to 2**10 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;
        for i in 0 to 3 loop
            -- Should still have first digit
            std_match(HexDigits, Quotient(i*4 to (i+1)*4-1)))
                report  "Input Divisor Failure"
                severity  ERROR;
            -- Update counter to get to right mux digit
            for j in 0 to 2**10 loop
                -- Cycle clock
                wait for 20 ns;
            end loop;
        end loop;

        END_SIM <= TRUE;        -- end of stimulus events
        wait;                   -- wait for simulation to end

    end process; -- end of stimulus process


    CLOCK_CLK : process
    begin

        -- this process generates a 20 ns 50% duty cycle clock
        -- stop the clock when the end of the simulation is reached
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


configuration TESTBENCH_FOR_SerialDivider of serialdivider_tb is
    for TB_ARCHITECTURE
        for UUT : SerialDivider
            use entity work.SerialDivider(DataFlow);
        end for;
    end for;
end TESTBENCH_FOR_SerialDivider;
