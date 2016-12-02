---------------------------------------------------------------------------------------------------
--
--  BCD2Binary8
--
--  Converts a 2-digit input BCD signal to an 8-bit binary output.  This uses exclusively
--  combinational logic.  The equations for B0 through B3 were obtained through inspection.  For
--  B0, it is simply passing through BCD0.  Only two BCD values have B1 set, so if either of
--  those values are present, then B1 is set.  B2 and B3 are set only if they have the XOR of the
--  corresponding BCD values and carry is true.
--
--  B4 through B7 were computed using 7-bit Karnaugh maps (because BCD0 has no impact on B7 through
--  B1, as there is no potential for carry from the B0 bit).  Note that B7 is always 0--there is
--  no set of inputs that cause a carry to spill to bit 7.
--
--  Entities: BCD2binary8 - Converts 2-digit BCD to 8-bit binary
--
--  Inputs: BCD[7..0] - A two-digit BCD value, where each nibble represents one decimal value,
--              the high bit being the high bit of the tens digit (which is the high nibble)
--
--  Outputs: B[7..0] - The binary representation of the input BCD value.
--
--  Revision History:
--      12/01/16  Tim Menninger   Created
--
---------------------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

---------------------------------------------------------------------------------------------------
--
--  BCD2binary8 entity declaration
--

entity BCD2binary8 is
    port (
        BCD         : in  std_logic_vector(7 downto 0);  -- BCD value
        B           : out std_logic_vector(7 downto 0)   -- value in binary
    );
end BCD2binary8;

---------------------------------------------------------------------------------------------------
--
-- BCD2binary conversion architecture
--

architecture converter of BCD2binary8 is
-- Process will convert the BCD to a binary value
-- Each digit in the BCD (lhs) corresponds to B (rhs), so we just add the corresponding
-- bit values for each BCD into B:
--          BCD bit =>    B
--             0    => 00000001
--             1    => 00000010
--             2    => 00000100
--             3    => 00001000
--             4    => 00001010
--             5    => 00010100
--             6    => 00101000
--             7    => 01010000
begin
    -- Set each bit as sum of bits and carries from rightmore bits.  The sum of any one bit
    -- is the XOR of {the bit immediately to its right, and any set bits in the binary
    -- representation shown above the process}.  In these, the "factors" referred to in
    -- comments are terms XOR'd together.

    -- Bits 0..3 were defined by looking for patterns.  Refer to file header for methodology
    -- in finding the patterns.  They correspond to the ones digit of BCD
    B(0) <= BCD(0);
    B(1) <= BCD(1) xor BCD(4);
    B(2) <= (BCD(1) and BCD(4)) xor BCD(2) xor BCD(5);  -- Both B(1) factors causes carry
    B(3) <= (BCD(2) and BCD(5) or                       -- Two+ B(2) factors causes carry
            ((BCD(1) and BCD(4)) and BCD(2)) or
            ((BCD(1) and BCD(4)) and BCD(5)))
        xor BCD(3) xor BCD(4) xor BCD(6);

    -- BIts 4..7 were defined with the help of Karnaugh maps, and correspond to the tens BCD digit
    B(4) <= (BCD(7) and not BCD(4)) or
            (not BCD(6) and BCD(5) and not BCD(4)) or
            (BCD(5) and not BCD(4) and not BCD(3) and not BCD(2)) or
            (BCD(6) and not BCD(5) and BCD(3)) or
            (BCD(7) and BCD(2) and not BCD(1)) or
            (not BCD(7) and not BCD(6) and not BCD(5) and BCD(4) and BCD(3)) or
            (not BCD(7) and not BCD(6) and not BCD(5) and BCD(4) and BCD(2) and BCD(1)) or
            (BCD(6) and not BCD(5) and BCD(4)) or
            (BCD(7) and BCD(4) and not BCD(3) and not BCD(2)) or
            (not BCD(6) and BCD(5) and BCD(4) and not BCD(3) and not BCD(2) and not BCD(1));
    B(5) <= (BCD(6) and not BCD(5)) or
            (BCD(7) and BCD(4) and BCD(3)) or
            (BCD(7) and BCD(4) and BCD(2) and BCD(1)) or
            (not BCD(6) and BCD(5) and BCD(4) and BCD(2)) or
            (not BCD(6) and BCD(5) and BCD(4) and BCD(1)) or
            (BCD(6) and not BCD(4) and not BCD(3) and not BCD(2));
    B(6) <= (BCD(7)) or
            (BCD(6) and BCD(5) and BCD(4)) or
            (BCD(6) and BCD(5) and BCD(3)) or
            (BCD(6) and BCD(5) and BCD(2));
    B(7) <= '0';
end converter;

---------------------------------------------------------------------------------------------------
