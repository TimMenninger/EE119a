----------------------------------------------------------------------------
--
--  Test Bench for UniversalSR8
--
--  This is a test bench for the UniversalSR8 entity.  The test bench
--  thoroughly tests the entity by exercising it and checking the outputs
--  through the use of an array of test values (TestVector).  The test bench
--  entity is called universalsr8_tb and it is currently defined to test the
--  Structural architecture of the UniversalSR8 entity.
--
--  Revision History:
--      4/4/00   Automated/Active-VHDL    Initial revision.
--      4/4/00   Glen George              Modified to add documentation and
--                                           more extensive testing.
--      4/6/04   Glen George              Updated comments.
--     11/21/05  Glen George              Updated comments and formatting.
--
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity universalsr8_tb is
end universalsr8_tb;

architecture TB_ARCHITECTURE of universalsr8_tb is

    -- Component declaration of the tested unit
    component UniversalSR8
        port(
            D    : in      std_logic_vector(7 downto 0);
            LSer : in      std_logic;
            RSer : in      std_logic;
            Mode : in      std_logic_vector(1 downto 0);
            CLR  : in      std_logic;
            CLK  : in      std_logic;
            Q    : buffer  std_logic_vector(7 downto 0)
        );
    end component;


    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  D     :  std_logic_vector(7 downto 0);
    signal  LSer  :  std_logic;
    signal  RSer  :  std_logic;
    signal  Mode  :  std_logic_vector(1 downto 0);
    signal  CLR   :  std_logic;
    signal  CLK   :  std_logic;

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  Q     :  std_logic_vector(7 downto 0);

    -- Signal used to stop clock signal generators
    signal  END_SIM  :  BOOLEAN := FALSE;

    -- Test Input/Output Vectors
    signal  TestVector  :  std_logic_vector(58 downto 0)
                           := "00000000101010101011011101111011111011111101111111011111111";


begin

    -- Unit Under Test port map
    UUT : UniversalSR8
        port map  (
            D    => D,
            LSer => LSer,
            RSer => RSer,
            Mode => Mode,
            CLR  => CLR,
            CLK  => CLK,
            Q    => Q
        );


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i  :  integer;        -- general loop index

    begin  -- of stimulus process

        -- initially everything is X and there is a clear (active low)
        CLR  <= '0';
        Mode <= "XX";
        RSer <= 'X';
        LSer <= 'X';
        D    <= "XXXXXXXX";

        -- run for a few clocks
        wait for 100 ns;

        -- check that we are clear
        assert (std_match(Q, "00000000"))
            report  "Clear Test Failure"
            severity  ERROR;


        -- remove clear and do a shift left using the test vector
        CLR  <= '1';        -- clear off

        for i in (TestVector'high - 8) downto 0 loop

            -- setup the input vector
            LSer <= TestVector(i);
            Mode <= "10";       -- left shift

            -- make sure nothing has shifted yet (after giving time to propagate)
            wait for 5 ns;
            assert (std_match(Q, TestVector((i + 8) downto (i + 1))))
                report  "Shift Left Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the shift worked
            assert (std_match(Q, TestVector((i + 7) downto i)))
                report  "Shift Left Test Failure"
                severity  ERROR;

            -- make sure hold works
            Mode <= "00";       -- hold
            -- now wait for a clock
            wait for 20 ns;
            -- make sure held the value and didn't shift
            assert (std_match(Q, TestVector((i + 7) downto i)))
                report  "Hold Test Failure"
                severity  ERROR;

        end loop;


        -- now hold for a few clocks
        Mode <= "00";        -- hold
        RSer <= 'X';         -- shift inputs are unused
        LSer <= 'X';

        -- give it a few clocks
        wait for 100 ns;

        -- and check to be sure held the value
        assert (std_match(Q, TestVector(7 downto 0)))
            report  "Hold Test Failure"
            severity  ERROR;


        -- now do a right shift test using the same test vector backwards
        Mode <= "01";       -- right shift
        LSer <= 'X';        -- left shift input is unused

        for i in 8 to TestVector'high loop

            -- setup the input vector
            RSer <= TestVector(i);

            -- make sure nothing has shifted yet
            -- give some time for signals to propagate
            wait for 5 ns;
            assert (std_match(Q, TestVector((i - 1) downto (i - 8))))
                report  "Shift Right Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the shift worked
            assert (std_match(Q, TestVector(i downto (i - 7))))
                report  "Shift Right Test Failure"
                severity  ERROR;

        end loop;


        -- test for asynchronous clear

        -- shift in a 1
        RSer <= '1';
        -- wait for the clock
        wait for 20 ns;

        -- check that we actually shifted
        assert (std_match(Q, "10000000"))
            report  "Clear Test Failure"
            severity  ERROR;

        -- now do an asynchronous clear (active low)
        CLR <= '0';
        wait for 5 ns;      -- let it propagate
        -- check that we are clear
        assert (std_match(Q, "00000000"))
            report  "Clear Test Failure"
            severity  ERROR;

        -- finally wait for a clock to set clear back
        wait for 15 ns;
        CLR <= '1';


        -- last test to do is the parallel load test (not shifting)
        LSer <= 'X';
        RSer <= 'X';
        Mode <= "11";

        for i in 255 downto 0 loop

            -- load the chip with the loop value
            D  <= STD_LOGIC_VECTOR(to_unsigned(i, 8));

            -- make sure nothing has loaded yet (after a little propagation time)
            wait for 5 ns;
            assert (std_match(Q, STD_LOGIC_VECTOR(to_unsigned(((i + 1) mod 256), 8))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

            -- now wait for a clock
            wait for 15 ns;

            -- make sure the parallel load worked
            assert (std_match(Q, STD_LOGIC_VECTOR(to_unsigned(i, 8))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

            -- give it another clock to be sure we don't shift
            wait for 20 ns;

            -- make sure the load didn't do a shift
            assert (std_match(Q, STD_LOGIC_VECTOR(to_unsigned(i, 8))))
                report  "Parallel Load Test Failure"
                severity  ERROR;

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


configuration TESTBENCH_FOR_UniversalSR8 of universalsr8_tb is
    for TB_ARCHITECTURE
        for UUT : UniversalSR8
            use entity work.UniversalSR8(Structural);
        end for;
    end for;
end TESTBENCH_FOR_UniversalSR8;
