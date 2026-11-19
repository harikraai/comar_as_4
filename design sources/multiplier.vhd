-- multiplier: given parallel (array) multiplier, built from FullAdder cells with generate statements.
-- It multiplies two UNSIGNED operands: product(2*size-1 downto 0) = operator1 * operator2 (unsigned).
--
-- NOTE FOR THE MULH INSTRUCTION (student work, intentionally NOT implemented here):
--   MUL   = product(31 downto 0)   is identical for signed and unsigned operands.
--   MULH  = HIGH 32 bits of the SIGNED x SIGNED product (RISC-V: MULH is signed*signed).
--         product(63 downto 32) of this unsigned multiplier is MULHU, which differs from MULH
--         whenever an operand is negative. Converting the unsigned array multiplier (or its upper half)
--         into a correct signed MULH is part of the assignment (sub-lab 2) and is left to the students.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;  

entity multiplier is
    generic(size: INTEGER := 32);
    port (
        operator1   : in std_logic_vector(size-1 downto 0);
        operator2   : in std_logic_vector(size-1 downto 0);
        product     : out std_logic_vector(size-1 downto 0);
        MulOp : in STD_LOGIC
    );
end entity multiplier;	 

architecture arch_multiplier of multiplier is

    type Tr is array (size-1 downto 0) of std_logic_vector(size downto 0);
    signal PProduct, S, C : Tr;

    component FullAdder
        Port ( 
            X : in STD_LOGIC;
            Y : in STD_LOGIC;
            Ci : in STD_LOGIC;
            Sum : out STD_LOGIC;
            Co : out STD_LOGIC
        );
    end component;
    signal check : STD_LOGIC;
    signal operator1_s : std_logic_vector(size-1 downto 0);
    signal operator2_s : std_logic_vector(size-1 downto 0);
    signal product_s : std_logic_vector(2*size-1 downto 0);
    signal product_neg : std_logic_vector(2*size-1 downto 0);
begin

    check <= operator1(size-1) xor operator2(size-1);
    product_neg <= not product_s + 1;


    process(operator1, operator2, MulOp, product_s, check,product_neg)
    begin

        operator1_s <= operator1;
        operator2_s <= operator2;

        case(MulOp) is
            when '0' => product <= product_s(size-1 downto 0);
            when '1' =>     
                if operator1(size-1) = '1'then
                    operator1_s <= not operator1 + 1;
                end if;
                if operator2(size-1) = '1'then
                    operator2_s <= not operator2 + 1;
                end if;
                
                
                if check = '1' then 
                    product <= product_neg(2*size-1 downto size);
                else 
                    product <= product_s(2*size-1 downto size);
                end if;
            when others => product <= (others => 'X');
        end case ;       
    end process ;
    
    S(0)(size) <= '0';
    row_0: for i in size-1 downto 0 generate
        S(0)(i) <= operator1_s(i) and operator2_s(0);
    end generate row_0;

    row_j : for j in 1 to size-1 generate
        S(j)(size) <= C(j)(size);
        col_i : for i in size-1 downto 0 generate
            PProduct(j)(i) <= operator1_s(i) and operator2_s(j);
            FullAdd: FullAdder port map (X => S(j-1)(i+1), Y => PProduct(j)(i), Ci => C(j)(i), Sum => S(j)(i), Co => C(j)(i+1));
        end generate ; -- col_i
        C(j)(0) <= '0';
        product_s(j) <= S(j)(0);
    end generate ; -- row_j

    product_s(2*size-1 downto size) <= S(size -1)(size downto 1);
    product_s(0) <= S(0)(0);
    
end architecture arch_multiplier;