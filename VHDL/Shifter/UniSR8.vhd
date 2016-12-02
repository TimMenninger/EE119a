---------------------------------------------------------------------------------------------------
--
--  UniversalSR8
--
---------------------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

---------------------------------------------------------------------------------------------------
--
-- ic74194 entity declaration
--

entity ic74194 is
    --
    -- Ports:
    --      CLK: (INPUT)  std_logic
    --          Clock signal used to update outputs.  Outputs should only change on rising edge
    --          of this signal unless CLR is active.
    --      CLR: (INPUT)  std_logic, active LOW
    --          Clears outputs when active.  This acts independent of CLK edge.
    --      LSI: (INPUT) std_logic
    --          The bit value (0 or 1) that is shifted in when shifting left.  Must be valid on
    --          rising clock edge when S = "01".
    --      RSI: (INPUT) std_logic
    --          The bit value (0 or 1) tha tis shifted in when shifting right.  Must be valid on
    --          rising clock edge when S = "10".
    --      S[1..0]: (INPUT) std_logic_vector
    --          Dictates how shifting occurs.  When "00", there should be no shift regardless of
    --          clock and the output values are retained.  When "10", shift right, putting RSI
    --          in Q7.  When "01", shift left, putting LSI in Q0.  Finally, when "11", manually
    --          resetting, put DI[7..0] into DO[7..0].  Only updates on rising clock edge.
    --      DI[3..0]: (INPUT) std_logic_vector
    --          When manually resetting outputs, the DO[7..0] outputs will relay what is
    --          respectively on DI[7..0].  This must be valid on rising clock edge when S = "11".
    --      DO[3..0]: (REGISTERED OUTPUT) std_logic_vector
    --          Contains the current value on the shift register.  This should be cleared on CLR
    --          (any clock value) and reset according to above specifications on rising CLK clock
    --          edge.  If inputs not specified, this retains its value.
    --
    port (
        CLK : in     std_logic;                     -- Clock signal
        CLR : in     std_logic;                     -- Resets output on low
        RSI : in     std_logic;                     -- High bit output when shifting right
        LSI : in     std_logic;                     -- Low bit output when shifting left
        S   : in     std_logic_vector(1 downto 0);  -- Dictates how to shift
        DI  : in     std_logic_vector(3 downto 0);  -- Data relayed to output on S = "11"
        DO  : buffer std_logic_vector(3 downto 0)   -- Data outputs of shifter
    );
end ic74194;

---------------------------------------------------------------------------------------------------
--
--  ic74194 shifting architecture
--

architecture shifter4bit of ic74194 is
begin
    process(CLK, CLR, RSI, LSI, S, DI) is
    -- Process will emulate 74LS194.  General specification:
    -- When CLR is low, clear outputs
    -- Outputs only change on rising edge of CLK and change according to S:
    --      If S[1..0] = "11", the DO[3..0] outputs should match the DI[3..0] inputs
    --      If S[1..0] = "10", shift DO[3..0] outputs right one and match D3 to RSI
    --      If S[1..0] = "01", shift DO[3..0] outputs left one and match D0 to LSI
    -- Otherwise, maintain previous DO[3..0] outputs
    begin
        -- Define dataflow of ic74194 4bit shifter
        if (CLR = '0') then
            -- When we want to clear, nothing else matters; just clear the outputs
            D0 <= "0000";
        elsif (rising_edge(CLK)) then
            -- Only changing outputs on rising edge of clock.
            if (S = "11") then
                -- When both are high, we are relaying the inputs to the outputs
                D0 <= DI;
            elsif (S = "10") then
                -- When just S1 is high, we shift right, with the high bit taking RSI
                DO(2 downto 0) <= DO(3 downto 1);
                DO(3) <= RSI;
            elsif (S = "01") then
                -- When just S0 is high, we shift left, with the low bit taking LSI
                DO(3 downto 1) <= DO(2 downto 0);
                DO(0) <= LSI;
            end if;
        end if;
    end process;
end shifter4bit;

---------------------------------------------------------------------------------------------------
--
--  UniversalSR8 entity declaration
--

entity UniversalSR8 is
    --
    -- Ports:
    --      CLK: (INPUT)  std_logic
    --          Clock signal used to update outputs.  Outputs should only change on rising edge
    --          of this signal unless CLR is active.
    --      CLR: (INPUT)  std_logic, active LOW
    --          Clears outputs when active.  This acts independent of CLK edge.
    --      LSer: (INPUT) std_logic
    --          The bit value (0 or 1) that is shifted in when shifting left.  Must be valid on
    --          rising clock edge when S = "01".
    --      RSer: (INPUT) std_logic
    --          The bit value (0 or 1) tha tis shifted in when shifting right.  Must be valid on
    --          rising clock edge when S = "10".
    --      Mode[1..0]: (INPUT) std_logic_vector
    --          Dictates how shifting occurs.  When "00", there should be no shift regardless of
    --          clock and the output values are retained.  When "10", shift right, putting RSer
    --          in Q7.  When "01", shift left, putting LSer in Q0.  Finally, when "11", manually
    --          resetting, put D[7..0] into Q[7..0].  Only updates on rising clock edge.
    --      D[7..0]: (INPUT) std_logic_vector
    --          When manually resetting outputs, the Q[7..0] outputs will relay what is
    --          respectively on D[7..0].  This must be valid on rising clock edge when S = "11".
    --      Q[7..0]: (REGISTERED OUTPUT) std_logic_vector
    --          Contains the current value on the shift register.  This should be cleared on CLR
    --          (any clock value) and reset according to above specifications on rising CLK clock
    --          edge.  If inputs not specified, this retains its value.
    --
    port (
        CLK  : in      std_logic;                    -- Clock signal
        CLR  : in      std_logic;                    -- Clears outputs when low (Q <= "00000000")
        RSer : in      std_logic;                    -- Fills high bit when shifting right
        LSer : in      std_logic;                    -- Fills low bit when shifting left
        Mode : in      std_logic_vector(1 downto 0); -- Dictates how/if to shift on rising CLK
        D    : in      std_logic_vector(7 downto 0); -- Data output on manual preset
        Q    : buffer  std_logic_vector(7 downto 0)  -- Registered output of shifter
    );
end UniversalSR8;

---------------------------------------------------------------------------------------------------
--
--  UniversalSR8 shifting architecture
--

architecture shifter8bit of UniversalSR8 is
    --
    -- Components
    --      ic74194:
    --          We are using two 4-bit shifters to create one nifty, shifty 8-bit shifter
    --
    component ic74194                                   -- 4-bit shifter, emulates 74LS194
        port (
            CLK : in     std_logic;                     -- Clock signal
            CLR : in     std_logic;                     -- Resets output on low
            RSI : in     std_logic;                     -- High bit output when shifting right
            LSI : in     std_logic;                     -- Low bit output when shifting left
            S   : in     std_logic_vector(1 downto 0);  -- Dictates how to shift
            DI  : in     std_logic_vector(3 downto 0);  -- Data relayed to output on S = "11"
            DO  : buffer std_logic_vector(3 downto 0)   -- Data outputs of shifter
        );
    end component;

    --
    -- Signals
    --      shiftIn: std_logic
    --          This will hold the bit that is shifted between the high and low nibbles of the two
    --          4bit shift registers.  This updates regardless of clock edge so we can simply relay
    --          the clock value onto the two 4bit shifters.
    --
    signal shiftIn : std_logic;
begin
    -- Using two ic74194's to form one 8bit shifter.  We will use one for the low nibble
    -- and one for the high nibble, and connect them all to our inputs with the exception of
    -- the left shift in on the high nibble (which comes from the low nibble) and the right
    -- shift in on the low nibble (which comes from the high nibble).  Because right shift and
    -- left shift are mutually exclusive, we can use the same signal for both.
    process(CLK, CLR, RSer, LSer, Mode, D) is
    begin
        -- Use the mode to define the value of the bit that will be shifted into one of the
        -- 4bit shifters.  When Mode = "11" or Mode = "10", this acts as if we are shifting right.
        -- In the former case, it will be ignored and in the latter, it is correct.  When
        -- Mode = "00" or Mode = "01", it acts as if shifting left.  Again, in the former case,
        -- this is ignored and in the latter, it is correct.
        if (Mode(1) = "1") then
            -- If shifting right, we will enter here and want to transfer low bit of high nibble
            -- to high bit of low nibble.
            shiftIn <= Q(4);
        else
            -- If shifting left, we will enter here and want to transfer high bit of low nibble to
            -- low bit of high nibble.  We will also enter here if we are manually resetting or
            -- doing nothing, in which case shiftIn doesn't matter, so no harm done
            shiftIn <= Q(3);
        end if;

        -- Define the components we are using
        --      highNibble: 4bit shift register containing high nibble of our 8 bits
        --      lowNibble:  4bit shift register containing low nibble of our 8 bits
        highNibble: ic74194
            port map (
                CLK           => CLK, -- ic74194 CLK mirrors UniversalSR8 CLK
                CLR           => CLR, -- ic74194 CLR mirrors UniversalSR8 CLR
                RSer          => RSI, -- ic74194 RSer mirrors UniversalSR8 RSI
                shiftIn       => LSI, -- ic74194 LSer set according to UniversalSR8 Mode
                Mode          => S,   -- ic74194 S mirrors UniversalSR8 Mode
                D(7 downto 4) => DI,  -- ic74194 DI from high nibble of UniversalSR8 D
                Q(7 downto 4) => DO   -- high nibble of UniversalSR8 Q from ic74194 DO
            );
        lowNibble: ic74194
            port map (
                CLK           => CLK, -- ic74194 CLK mirrors UniversalSR8 CLK
                CLR           => CLR, -- ic74194 CLR mirrors UniversalSR8 CLR
                shiftIn       => RSI, -- ic74194 RSer set according to UniversalSR8 Mode
                LSer          => LSI, -- ic74194 LSer mirrors UniversalSR8 LSI
                Mode          => S,   -- ic74194 S mirrors UniversalSR8 Mode
                D(3 downto 0) => DI,  -- ic74194 DI from low nibble of UniversalSR8 D
                Q(3 downto 0) => DO   -- low nibble of UniversalSR8 Q from ic74194 DO
            );
    end process;
end shifter8bit;
