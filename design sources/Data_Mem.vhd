--the ram is simplified to some register, just like the ROM this is to make the design easier
--single port RAM of 16 local * 8 bits (16 registers of 8 bits)
--no chip select and no read enable cause the output goes to a mux, not a bus
--0H to 7H for output data (0H-3H and 4H-7H 32 bits register) 2reg 32 bits
--8H to FH for input operations (8H-BH and CH-FH for inputs) 2reg 32 bits
--
--Little endian: MEM(Address) holds dataIn(7 downto 0) ... MEM(Address+3) holds dataIn(31 downto 24).
--Stores:  storeByte = '1' (SB): only the addressed byte MEM(Address) is written with dataIn(7 downto 0),
--                               the neighbouring bytes keep their value.
--         storeByte = '0' (SW): the four bytes MEM(Address) ... MEM(Address+3) are written.
--Loads:   dataOut always shows the 4 bytes starting at Address. LW uses all of them, LB uses
--         dataOut(7 downto 0) (= MEM(Address)) which is sign extended in Mux_ToRegFile.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Data_Mem is
    port (
        clk     :in std_logic;
        writeEn :in std_logic;
        storeByte :in std_logic;                        --'1': SB (write 1 byte), '0': SW (write 4 bytes)
        Address :in std_logic_vector(3 downto 0);
        dataIn  :in std_logic_vector(31 downto 0);
        dataOut :out std_logic_vector(31 downto 0)
    );
end entity Data_Mem;

architecture arch_Data_Mem of Data_Mem is

    type RAM is array (15 downto 0) of std_logic_vector(7 downto 0);
    signal MEM : RAM := (others => (others => '0'));
begin
    process(clk)
    begin
    if rising_edge(clk) then
        if (writeEn = '1') then
            MEM(conv_integer(Address))   <= dataIn(7 downto 0);
            if (storeByte = '0') then                   --SW: also write the 3 other bytes
                MEM(conv_integer(Address+1)) <= dataIn(15 downto 8);
                MEM(conv_integer(Address+2)) <= dataIn(23 downto 16);
                MEM(conv_integer(Address+3)) <= dataIn(31 downto 24);
            end if;
        end if;
    end if;
    end process;

    dataOut <= MEM(conv_integer(Address+3)) & MEM(conv_integer(Address+2)) &
               MEM(conv_integer(Address+1)) & MEM(conv_integer(Address));

end arch_Data_Mem ; -- arch_Data_Mem
