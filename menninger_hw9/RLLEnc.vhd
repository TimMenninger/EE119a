-- bring in the necessary packages
library  ieee;
use  ieee.std_logic_1164.all;

---------------------------------------------------------------------------------------------
--
--  RLLEncoder
--
--  This is an implementation of an RLL(2, 7) encoder.  It takes a constant input stream of
--  bits and outputs a constant stream of bits at twice the frequence of the RLL encoding
--  of the input.  Because the RLL output requires a two-bit lookahead, but we can't see
--  into the future (as of December 2017), the output lags the input by two bits.  The output
--  encoding follows this structure:
--              Input Stream            Output Stream
--                    10                      0100
--                    11                      1000
--                   000                    000100
--                   010                    100100
--                   011                    001000
--                  0010                  00100100
--                  0011                  00001000
--
--  Inputs:
--      DataIn  - Input stream of bits.  These change on CLK and are valid for two CLKs
--      Reset   - Active low reset
--      CLK     - Global clock
--
--  Outputs:
--      RLLOut  - Output stream of RLL encoded DataIn, lagging by two bits.  This is output
--                at twice the frequency of DataIn (frequency of CLK)
--
--  Revision History:
--      7 Dec 16  Tim Menninger     Initial revision
--
---------------------------------------------------------------------------------------------

--
-- entity RLLEncoder
--
-- Defines the inputs and outputs for the RLL bit stream encoder
--
entity RLLEncoder is
    port (
        DataIn  :  in  std_logic;   -- Input stream of data
        Reset   :  in  std_logic;   -- Active low reset
        CLK     :  in  std_logic;   -- Global CLK
        RLLOut  :  out std_logic    -- Output stream of RLL encoded input
    );
end RLLEncoder;

--
-- encoder architecture
--
-- Defines the dataflow of the RLL encoding of the data input.  To achieve this, it uses a
-- state machine that transitions on certain input bit sequences, and outputs based on its
-- known relevant history.
--
--  Inputs:
--      DataIn  - Input stream of bits.  These change on CLK and are valid for two CLKs
--      Reset   - Active low reset
--      CLK     - Global clock
--
--  Outputs:
--      RLLOut  - Output stream of RLL encoded DataIn, lagging by two bits.  This is output
--                at twice the frequency of DataIn (frequency of CLk)
--
architecture encoder of RLLEncoder is

    --
    -- Types:
    --
    -- RLLState: State machien for RLL encoding of input data bit stream
    --      states:
    --          RLL* - Each state represents a particular known history of inputs, where
    --                 the star here would be replaced by the relevant recent history.  In
    --                 the case of RLL, we know nothing.  This should only be the active
    --                 state for one clock immediately after reset.
    --
    type RLLState is (
        RLL,
        RLL0,
        RLL1,
        RLL00,
        RLL01,
        RLL10,
        RLL11,
        RLL000,
        RLL001,
        RLL010,
        RLL011,
        RLL0010,
        RLL0011
    );

    --
    -- Signals:
    --
    -- RLLMachine (RLLState) - Keeps track of the current state in the state machine.
    -- secondClk (std_logic) - Each input bit corresponds to two output bits.  This flag
    --      alternates every clock, keeping us in each state for two clocks.  States only
    --      change on the second clock, at which point this would be high.
    --
    signal RLLMachine : RLLState;
    signal secondClk  : std_logic;

begin
    --
    -- process
    --
    -- Handles the state machine and RLLOut encoded output.  The state machine only changes
    -- states every other input CLK, which it refers to secondClk to know about.  Each state
    -- is aware of as many previous bits as it needs to know in order to output the next
    -- two RLL-encoded bits.  Input and corresponding output sequences can be viewed in
    -- file header.
    --
    -- Inputs:  CLK - Global CLK governing RLLOut frequency
    --          Reset - Active low reset
    --          DataIn - Input data stream, which changes every other CLK
    --
    -- Outputs: RLLOut - Sets the RLLOut output based on state and input.
    --
    process (CLK, Reset, DataIn) is
    begin
        if (Reset = '0') then
            RLLMachine <= RLL;
            RLLOut <= '0';
            secondClk <= '0';
        elsif (rising_edge(CLK)) then
            secondClk <= not secondClk;
            -- State machine
            case RLLMachine is
                ---------------------------
                -- RLL state
                ---------------------------
                when RLL =>
                    -- Output here doesn't matter
                    RLLOut <= '0';
                    -- Idle state, should only be here when next bit is first in sequence
                    if (secondClk = '1') then
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL0 state
                ---------------------------
                when RLL0 =>
                    -- Last two bits of any encoding is always 00
                    RLLOut <= '0';
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL00;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL01;
                        end if;
                    end if;
                ---------------------------
                -- RLL1 state
                ---------------------------
                when RLL1 =>
                    -- Last two bits of any encoding is always 00
                    RLLOut <= '0';
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL10;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL11;
                        end if;
                    end if;
                ---------------------------
                -- RLL00 state
                ---------------------------
                when RLL00 =>
                    -- First and second bits of all 00* states is 00
                    RLLOut <= '0';
                    -- Change state on second clock
                    if (secondClk = '1') then
                        if (DataIn = '0') then
                            RLLMachine <= RLL000;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL001;
                        end if;
                    end if;

                ---------------------------
                -- RLL01 state
                ---------------------------
                when RLL01 =>
                    if (secondClk = '0') then
                        -- Output of first clock in 01* sequence always inverts input
                        RLLOut <= not DataIn;
                    else -- (secondClk = '1')
                        -- Second bit in 01* encoding is always a 0
                        RLLOut <= '0';
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL010;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL011;
                        end if;
                    end if;
                ---------------------------
                -- RLL10 state
                ---------------------------
                when RLL10 =>
                    -- First and second bits of 10 always 01
                    RLLOut <= secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL11 state
                ---------------------------
                when RLL11 =>
                    -- First and second bits of 11 always 10
                    RLLOut <= not secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL000 state
                ---------------------------
                when RLL000 =>
                    -- Third and fourth bits of 000 always 01
                    RLLOut <= secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL001 state
                ---------------------------
                when RLL001 =>
                    -- On first clock, output inverts input (third bit in encoding)
                    if (secondClk = '0') then
                        RLLOut <= not DataIn;
                    else -- (secondClk = '1')
                        -- Second clock of 001* is always 0 (fourth bit in encoding)
                        RLLOut <= '0';
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0010;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL0011;
                        end if;
                    end if;
                ---------------------------
                -- RLL010 state
                ---------------------------
                when RLL010 =>
                    -- Third and fourth bits of 010 is always 01
                    RLLOut <= secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL011 state
                ---------------------------
                when RLL011 =>
                    -- Third and fourth bits of 010 is always 10
                    RLLOut <= not secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL0010 state
                ---------------------------
                when RLL0010 =>
                    -- Fifth and sixth bits of 0010 always 01
                    RLLOut <= secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
                ---------------------------
                -- RLL0011 state
                ---------------------------
                when RLL0011 =>
                    -- Fifth and sixth bits of 0011 always 10
                    RLLOut <= not secondClk;
                    -- Move states on second clock
                    if (secondClk = '1') then
                        -- Move states
                        if (DataIn = '0') then
                            RLLMachine <= RLL0;
                        else -- (DataIn = '1')
                            RLLMachine <= RLL1;
                        end if;
                    end if;
            end case;
        end if;
    end process;

end encoder;
