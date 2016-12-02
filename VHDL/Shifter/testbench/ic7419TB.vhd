----------------------------------------------------------------------------
--
--  Test Bench for ic74194
--
--  This is a test bench for the ic74194 entity.  The test bench thoroughly
--  tests the entity by exercising it and checking the outputs through the
--  use of an array of test values (TestVector).  The test bench entity is
--  called ic74194_tb and it is currently defined to test the DataFlow
--  architecture of the ic74914 entity.
--
--  Revision History:
--      4/4/00   Automated/Active-VHDL    Initial revision.
--      4/4/00   Glen George              Modified to add documentation and
--                                           more extensive testing.
--      4/9/02   Glen George              Fixed bit order problem on the
--                                           buses.
--      4/6/04   Glen George              Updated comments.
--     11/21/05  Glen George              Updated comments and formatting.
--
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ic74194_tb is
end ic74194_tb;

architecture TB_ARCHITECTURE of ic74194_tb is

    -- Component declaration of the tested unit
    component ic74194
        port(
            DI   :  in      std_logic_vector(0 to 3);
            LSI  :  in      std_logic;
            RSI  :  in      std_logic;
            S    :  in      std_logic_vector(1 downto 0);
            CLR  :  in      std_logic;
            CLK  :  in      std_logic;
            DO   :  buffer  std_logic_vector(0 to 3)
        );
    end component;


    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  DI   :  std_logic_vector(0 to 3);
    signal  LSI  :  std_logic;
    signal  RSI  :  std_logic;
    signal  S    :  std_logic_vector(1 downto 0);
    signal  CLR  :  std_logic;
    signal  CLK  :  std_logic;

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  DO   :  std_logic_vector(0 to 3);

    -- Signal used to stop clock signal generators
    signal  END_SIM  :  BOOLEAN := FALSE;

    -- Test Input/Output Vectors
    signal  TestVector  :  std_logic_vector(16 downto 0) := "00001011011101111";


begin

    -- Unit Under Test port map
    UUT : ic74194
        port map  (
            DI  => DI,
            LSI => LSI,
            RSI => RSI,
            S   => S,
            CLR => CLR,
            CLK => CLK,
            DO  => DO
        );


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i  :  integer;        -- general loop index

    begin  -- of stimulus process

        -- initially everything is X and there is a clear (active low)
        CLR <= '0';
        S   <= "XX";
        RSI <= 'X';
        LSI <= 'X';
        DI  <= "XXXX";

        -- run for a few clocks
        wait for 100 ns;

        -- check that we are clear
        assert (std_match(DO, "0000"))
            report  "Clear Test Failure"
            severity  ERROR;


        -- remove clear and do a shift left using the test vector
        CLR <= '1';         -- clear off

        for i in (TestVector'high - 4) downto 0 loop

            -- setup the input vector
            LSI <= TestVector(i);
            S   <= "10";        -- left shift

            -- make sure nothing has shifted yet (after signals propagate)
            wait for 5 ns;
            assert (std_match(DO, TestVector((i + 4) downto (i + 1))))
                report  "Shift Left Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the shift worked
            assert (std_match(DO, TestVector((i + 3) downto i)))
                report  "Shift Left Test Failure"
                severity  ERROR;

            -- also make sure hold works
            S   <= "00";        -- hold
            -- now wait for a clock
            wait for 20 ns;
            -- and make sure the old value is still there
            assert (std_match(DO, TestVector((i + 3) downto i)))
                report  "Hold Test Failure"
                severity  ERROR;

        end loop;


        -- now hold for a few clocks
        S   <= "00";        -- hold
        RSI <= 'X';         -- shift inputs are unused
        LSI <= 'X';

        -- give it a few clocks
        wait for 100 ns;

        -- and check to be sure held the value
        assert (std_match(DO, TestVector(3 downto 0)))
            report  "Hold Test Failure"
            severity  ERROR;


        -- now do a right shift test using the same test vector backwards
        S   <= "01";        -- right shift
        LSI <= 'X';         -- left shift input is unused

        for i in 4 to TestVector'high loop

            -- setup the input vector
            RSI <= TestVector(i);

            -- make sure nothing has shifted yet (give time for propagation)
            wait for 5 ns;
            assert (std_match(DO, TestVector((i - 1) downto (i - 4))))
                report  "Shift Right Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the shift worked
            assert (std_match(DO, TestVector(i downto (i - 3))))
                report  "Shift Right Test Failure"
                severity  ERROR;

        end loop;


        -- test for asynchronous clear

        -- shift in a 1
        RSI <= '1';
        -- wait for the clock
        wait for 20 ns;

        -- check that we actually shifted
        assert (std_match(DO, "1000"))
            report  "Clear Test Failure"
            severity  ERROR;

        -- now do an asynchronous clear (active low)
        CLR <= '0';
        wait for 5 ns;          -- let it propagate
        -- check that we are clear
        assert (std_match(DO, "0000"))
            report  "Clear Test Failure"
            severity  ERROR;

        -- finally wait for a clock to set clear back
        wait for 15 ns;
        CLR <= '1';


        -- last test to do is the parallel load test (not shifting)
        LSI <= 'X';
        RSI <= 'X';
        S   <= "11";

        for i in 15 downto 0 loop

            -- load the chip with the loop value
            DI  <= STD_LOGIC_VECTOR(to_unsigned(i, 4));

            -- make sure nothing has loaded yet (after propagating signals)
            wait for 5 ns;
            assert (std_match(DO, STD_LOGIC_VECTOR(to_unsigned(((i + 1) mod 16), 4))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the parallel load worked
            assert (std_match(DO, STD_LOGIC_VECTOR(to_unsigned(i, 4))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

            -- now wait for a clock to be sure load doesn't shift
            wait for 20 ns;
            -- verify still the same value
            assert (std_match(DO, STD_LOGIC_VECTOR(to_unsigned(i, 4))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

        end loop;


        END_SIM <= TRUE;        -- end of stimulus events
        wait;                   -- wait for simulation to end

    end process; -- end of stimulus process


    CLOCK_CLK : process
    begin

        -- this process generates a clock with a 20 ns period and 50% duty cycle
        -- stop the clock when end of simulation is reached
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



configuration TESTBENCH_FOR_ic74194 of ic74194_tb is
    for TB_ARCHITECTURE
        for UUT : ic74194
            use entity work.ic74194(DataFlow);
        end for;
    end for;
end TESTBENCH_FOR_ic74194;
