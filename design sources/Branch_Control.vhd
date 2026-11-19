library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Branch_Control: decides whether the PC is replaced by the branch/jump target.
-- The ALU performs rs1 - rs2 for the conditional branches. Its flags are used as follows:
--   BEQ : zero = '1'
--   BNE : zero = '0'
--   BLT : signed rs1 <  rs2  <=>  signo xor overflow = '1'
--   BGE : signed rs1 >= rs2  <=>  signo xor overflow = '0'
-- (The sign bit of the subtraction alone is NOT enough: it is wrong when the subtraction overflows,
--  e.g. 0x80000000 - 1 or 0x7FFFFFFF - (-1).)
entity Branch_Control is
    port (
        branch      : in std_logic_vector(2 downto 0);
        signo       : in std_logic;     --sign bit of the ALU result (rs1 - rs2)
        overflow    : in std_logic;     --signed overflow of rs1 - rs2 (ALU)
        zero        : in std_logic;
        PCSrc       : out std_logic
    );
end entity Branch_Control;

architecture arch_Branch_Control of Branch_Control is

    signal BEQ : std_logic;
    signal BNE : std_logic;
    signal BLT : std_logic;
    signal BGE : std_logic;
    signal temp: std_logic;

begin
    process( branch, signo, zero, BEQ, BNE, BLT, BGE )
    begin
        case branch is
            when "001" => temp <= BEQ;
            when "010" => temp <= BNE;
            when "011" => temp <= BLT;
            when "100" => temp <= BGE;
            when "101" => temp <= '1';  --JALR
            when "110" => temp <= '1';  --JAL
            when others => temp <= '0';
        end case;
    end process ;

    BEQ <= '1' when zero = '1' else '0';
    BNE <= '1' when zero = '0' else '0';
    BLT <= '1' when (signo xor overflow) = '1' else '0';    --signed less than
    BGE <= '1' when (signo xor overflow) = '0' else '0';    --signed greater than or equal

    PCSrc <= temp;

end architecture arch_Branch_Control;
