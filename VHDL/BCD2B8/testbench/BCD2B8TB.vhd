----------------------------------------------------------------------------
--
--  Test Bench for BCD2Binary8
--
--  This is a test bench for the BCD2Binary8 entity.  The test bench
--  thoroughly tests the entity by exercising it and checking the outputs.
--  All possible valid 8-bit BCD values are generated and tested.  The test
--  bench entity is called bcd2binary8_tb and it is currently defined to test
--  the DataFlow architecture of the BCD2Binary8 entity.
--
--  Revision History:
--      4/4/00   Automated/Active-VHDL    Initial revision.
--      4/4/00   Glen George              Modified to add documentation and
--                                           more extensive testing.
--     11/21/05  Glen George              Updated comments and formatting.
--
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity bcd2binary8_tb is
end bcd2binary8_tb;

architecture TB_ARCHITECTURE of bcd2binary8_tb is

    -- Component declaration of the tested unit
    component BCD2Binary8
        port(
            BCD  :  in  std_logic_vector(7 downto 0);
            B    :  out std_logic_vector(7 downto 0)
        );
    end component;

    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  BCD  :  std_logic_vector(7 downto 0);

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  B    :  std_logic_vector(7 downto 0);

    -- test values
    signal  BCDin           :  unsigned(7 downto 0);
    signal  ExpectedBinary  :  unsigned(7 downto 0) := X"00";


begin

    -- Unit Under Test port map
    UUT : BCD2Binary8
        port map  (
            BCD => BCD,
            B => B
        );


    -- compute the BCD input from the expected binary
    BCDin <= (((ExpectedBinary / 10) sll 4) or (ExpectedBinary mod 10));
    -- need to map BCDin to a std_logic_vector
    BCD <= STD_LOGIC_VECTOR(BCDin);


    -- now generate the stimulus and test it
    process
    begin  -- of stimulus process

        -- wait a little for propagation delays
        wait for 10 ns;

        -- check if the expected binary output is right
        assert (std_match(B, STD_LOGIC_VECTOR(ExpectedBinary)))
            report  "Test Failure"
            severity  ERROR;

        -- now wait a bit
        wait for 10 ns;

        -- update the binary value
        if (ExpectedBinary = 99) then
            ExpectedBinary <= X"00";
        else
            ExpectedBinary <= ExpectedBinary + 1;
        end if;

        -- and just keep looping in the process
    end process; -- end of stimulus process

end TB_ARCHITECTURE;


configuration TESTBENCH_FOR_BCD2Binary8 of bcd2binary8_tb is
    for TB_ARCHITECTURE
        for UUT : BCD2Binary8
            use entity work.BCD2Binary8(DataFlow);
        end for;
    end for;
end TESTBENCH_FOR_BCD2Binary8;
