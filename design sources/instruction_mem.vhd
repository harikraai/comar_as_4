library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Instruction_Mem is
    port (
        Address     : in  std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(31 downto 0)
    );
end entity Instruction_Mem;

architecture arch_Instruction_Mem of Instruction_Mem is
    type ROM_ARRAY is array (0 to 65535) of std_logic_vector(7 downto 0);
    constant ROM : ROM_ARRAY := (
        -- 0x00: addi x1, x0, -5
        "11111111","10110000","00000000","10010011",
        -- 0x04: addi x2, x0, 4
        "00000000","01000000","00000001","00010011",
        -- 0x08: mul x3, x1, x2   -> -20 (0xFFFFFFEC)
        "00000010","00100000","10000001","10110011",
        -- 0x0C: mulh x4, x1, x2  -> -1  (0xFFFFFFFF)
        "00000010","00100000","10010010","00110011",

        -- 0x10: addi x5, x0, -6
        "11111111","10100000","00000010","10010011",
        -- 0x14: mul x6, x1, x5   -> 30  (0x0000001E)
        "00000010","01010000","10000011","00110011",
        -- 0x18: mulh x7, x1, x5  -> 0   (0x00000000)
        "00000010","01010000","10010011","10110011",

        -- 0x1C: addi x8, x0, 1000
        "00111110","10000000","00000100","00010011",
        -- 0x20: addi x9, x0, 2000
        "01111101","00000000","00000100","10010011",
        -- 0x24: mul x10, x8, x9  -> 2000000 (0x001E8480)
        "00000010","10010100","00000101","00110011",
        -- 0x28: mulh x11, x8, x9 -> 0       (0x00000000)
        "00000010","10010100","00010101","10110011",

        -- 0x2C: jal x0, 0 (blijft hier hangen)
        "00000000","00000000","00000000","01101111",

        others => X"00"
    );
begin
    instruction <= ROM(conv_integer(Address))     & ROM(conv_integer(Address + 1)) &
                   ROM(conv_integer(Address + 2)) & ROM(conv_integer(Address + 3));
end architecture arch_Instruction_Mem;