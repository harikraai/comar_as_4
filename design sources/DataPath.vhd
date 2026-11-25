library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DataPath is
    port (
        clk         : in std_logic;
        rst         : in std_logic; --reset is button, must be debounced
        ALUMULTIPLIER_result  : out std_logic_vector(31 downto 0)
    );
end entity DataPath;

architecture arch_DataPath of DataPath is

    component PC
        port (
            PCIn    : in std_logic_vector(31 downto 0);
            clk     : in std_logic;
            rst     : in std_logic;                                                     
            PCOut   : out std_logic_vector(31 downto 0)
        );
    end component;

    component Instruction_Mem
        port (
            Address     :in std_logic_vector(15 downto 0);
            instruction :out std_logic_vector(31 downto 0)
        );
    end component;

    component Reg_File
        port (
            clk         :in std_logic;
            writeReg    :in std_logic;                          --signal for write in register
            sourceReg1  :in std_logic_vector(4 downto 0);       --address of rs1
            sourceReg2  :in std_logic_vector(4 downto 0);       --address of rs2
            destinyReg  :in std_logic_vector(4 downto 0);       --address of rd
            data        :in std_logic_vector(31 downto 0);      --Data to be written
            readData1   :out std_logic_vector(31 downto 0);     --data in rs1
            readData2   :out std_logic_vector(31 downto 0)      --data in rs2    
        );
    end component;

    component Mux
        port (
            muxIn0      :in std_logic_vector(31 downto 0);
            muxIn1      :in std_logic_vector(31 downto 0);
            selector    :in std_logic;
            muxOut      :out std_logic_vector(31 downto 0)    
    );
    end component;

    component ALU_RV32
        port (
            operator1   :in std_logic_vector(31 downto 0);
            operator2   :in std_logic_vector(31 downto 0);
            ALUOp       :in std_logic_vector(2 downto 0);
            result_ALU      :out std_logic_vector(31 downto 0);
            zero        :out std_logic;
            carryOut    :out std_logic;
            overflow    :out std_logic;
            signo  		:out std_logic
        );
    end component;

    component Data_Mem
        port (
            clk     :in std_logic;
            writeEn :in std_logic;
            storeByte :in std_logic;                        --'1': SB (only the addressed byte is written), '0': SW (4 bytes)
            Address :in std_logic_vector(3 downto 0);
            dataIn  :in std_logic_vector(31 downto 0);
            dataOut :out std_logic_vector(31 downto 0)
        );
    end component;

    component Immediate_Generator
        port (
            instruction     : in std_logic_vector(31 downto 0);
            immediate       : out std_logic_vector(31 downto 0)
        );
    end component;

    component Mux_Store
        port (
            muxIn0      :in std_logic_vector(31 downto 0);  --SB
            muxIn1      :in std_logic_vector(31 downto 0);  --SW
            selector    :in std_logic;
            muxOut      :out std_logic_vector(31 downto 0)
    );
    end component;

    component Branch_Control
        port (
            branch      : in std_logic_vector(2 downto 0);
            signo       : in std_logic;
            overflow    : in std_logic;
            zero        : in std_logic;
            PCSrc       : out std_logic
        );
    end component;

    component Mux_ToRegFile
        generic (
            busWidth    :integer := 32
            --selWidth    :integer := 3
        );
        port (
            muxIn0     :in std_logic_vector(busWidth-1 downto 0);       --register
            muxIn1     :in std_logic_vector(busWidth-1 downto 0);       --LB
            muxIn2     :in std_logic_vector(busWidth-1 downto 0);       --LW
            muxIn3     :in std_logic_vector(busWidth-1 downto 0);       --PC
            muxIn4     :in std_logic_vector(busWidth-1 downto 0);       --mult
            muxIn5     :in std_logic_vector(busWidth-1 downto 0);       --PC+4
            muxIn6     :in std_logic_vector(busWidth-1 downto 0);
            selector   :in std_logic_vector(2 downto 0);       --ToRegister
            muxOut     :out std_logic_vector(busWidth-1 downto 0)
        );
    end component;

    component Control
        port (
            opcode      : in std_logic_vector(6 downto 0);
            funct3      : in std_logic_vector(2 downto 0);
            funct7      : in std_logic_vector(6 downto 0);
            jump        : out std_logic;
            ToRegister  : out std_logic_vector(2 downto 0);
            MemWrite    : out std_logic;
            Branch      : out std_logic_vector(2 downto 0);
            ALUOp       : out std_logic_vector(2 downto 0);
            StoreSel    : out std_logic;
            ALUSrc      : out std_logic;
            WriteReg    : out std_logic;
            MulOp       : out std_logic
        );
    end component;

    component multiplier is
    generic(size: INTEGER := 32);
    port (
        operator1   : in std_logic_vector(size-1 downto 0);
        operator2   : in std_logic_vector(size-1 downto 0);
        product     : out std_logic_vector(size-1 downto 0);
        MulOp : in STD_LOGIC
    );
    end component multiplier;	


    signal PCOut, PCOutPlus    : std_logic_vector(31 downto 0);    --data out from PC register
    signal instruction          : std_logic_vector(31 downto 0);    --instruction from ROM mem
    signal PCIn                 : std_logic_vector(31 downto 0);    --PC updated
    signal regData1,regData2    : std_logic_vector(31 downto 0);    --data readed from register file
    signal signo, zero, carry   : std_logic;
    signal overflow             : std_logic;                        --signed overflow of the ALU subtraction (for BLT/BGE)
    signal result, dataIn       : std_logic_vector(31 downto 0);    --alu result and data in to memory
    signal product              : std_logic_vector(31 downto 0);    --product
    signal MulOp                : std_logic;                        --signal to select ALU or multiplier
    signal immediate            : std_logic_vector(31 downto 0);    --immediate generated
    signal dataOut              : std_logic_vector(31 downto 0);    --data from memory
    signal jump, memWrite       : std_logic;
    signal StoreSel, ALUSrc     : std_logic;
    signal writeReg, PCSrc      : std_logic;
    signal toRegister, Branch, ALUOp : std_logic_vector(2 downto 0);
    signal dataForReg           : std_logic_vector(31 downto 0);    --data to be written in register File
    signal op2                  : std_logic_vector(31 downto 0);    --operator for ALU(output from mux)
    signal branchTarget         : std_logic_vector(31 downto 0);    --PC + (immediate << 1): branches and JAL
    signal jalrTarget           : std_logic_vector(31 downto 0);    --(rs1 + immediate) and 0xFFFFFFFE: JALR
    signal newAddress           : std_logic_vector(31 downto 0);    --target of a taken branch/jump
    signal shifted              : std_logic_vector(31 downto 0);
begin
    
    PCount: PC port map (clk => clk, rst => rst, PCIn => PCIn, PCOut => PCOut);

    ROM: Instruction_Mem port map (Address => PCOut(15 downto 0), instruction => instruction);

    RFILE: Reg_File port map (clk => clk, writeReg => writeReg, sourceReg1 => instruction(19 downto 15),
    sourceReg2 => instruction(24 downto 20), destinyReg => instruction(11 downto 7), data => dataForReg,
    readData1 => regData1, readData2 => regData2);

    Mux0: Mux port map (muxIn0 => immediate, muxIn1 => regData2, selector => ALUSrc, muxOut => op2);
    
    ALU: ALU_RV32 port map (operator1 => regData1, operator2 => op2, ALUOp => ALUOp, 
    result_ALU => result, zero => zero, carryOut => carry, overflow => overflow, signo => signo);

    RAM: Data_Mem port map (clk => clk, writeEn => memWrite, storeByte => StoreSel, Address => result(3 downto 0), dataIn => regData2, dataOut => dataOut);

    BRControl: Branch_Control port map (branch => Branch, signo => signo, overflow => overflow, zero => zero,PCSrc => PCSrc);

    MuxReg: Mux_ToRegFile port map (muxIn0 => result, muxIn1 => dataOut, muxIn2 => dataOut, muxIn3 => PCOut,
    muxIn4 => (others => '0'), muxIn5 => PCOutPlus, muxIn6 => product, selector => toRegister, muxOut => dataForReg);

    Ctrl: Control port map (opcode => instruction(6 downto 0), funct3 => instruction(14 downto 12), funct7 => instruction(31 downto 25),
    jump => jump, MemWrite => memWrite, Branch => Branch, ALUOp => ALUOp, StoreSel => StoreSel, ALUSrc => ALUSrc, 
    WriteReg => WriteReg, ToRegister => toRegister, MulOp => MulOp);

    --jump = '1' only for JALR: target = (rs1 + imm) and 0xFFFFFFFE (not PC relative). Otherwise PC + (imm << 1).
    Mux2: Mux port map (muxIn0 => branchTarget, muxIn1 => jalrTarget, selector => jump, muxOut => newAddress);

    Mux3: Mux port map (muxIn0 => PCOutPlus, muxIn1 => newAddress, selector => PCSrc, muxOut => PCIn);
    
    Imm: Immediate_Generator port map (instruction => instruction, immediate => immediate);

    mul: multiplier port map (
        operator1 => regData1,
        operator2 => regData2,
        product => product,
        MulOp => MulOp
    );

    PCOutPlus <= PCOut + 4;
    shifted <= immediate(30 downto 0) & '0';
    branchTarget <= PCOut + shifted;
    jalrTarget <= result(31 downto 1) & '0';                        --clear bit 0 of rs1 + imm
    
    ALUMULTIPLIER_result <= result;

end architecture arch_DataPath;
