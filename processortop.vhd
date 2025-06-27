library ieee;
use ieee.std_logic_1164.all;

entity processortop is
    port(ValueSelect: in std_logic_vector(2 downto 0);
        GClk, GReset: in std_logic;
        MuxOut: out in std_logic_vector(7 downto 0);
        BranchOut, MemWriteOut, RegWriteOut, ZeroOut: out std_logic);
end processortop;

architecture rtl of processortop is

component nbit8to1mux
    GENERIC(n: integer:=8);
	PORT ( i0, i1, i2, i3, i4, i5, i6, i7 : IN std_logic_vector( n-1 downto 0);
		   sel : IN std_logic_vector(2 downto 0);
		   o : OUT std_logic_vector( n-1 downto 0));
end component;

component sc_datapath
	port(GClk, GReset, MemWrite, RegDst, ALUSrc, Branch, Jump, MemtoReg, MemRead, RegWrite: in std_logic,  -- from overall control block
         ALUFunc: in std_logic_vector(2 downto 0),   -- from ALU control block
         PCOut, ALUResult, ReadData1, ReadData2, WriteDate: out std_logic_vector(7 downto 0),    -- for MuxOut get control signals from control path
         InstructionOut: out std_logic_vector(31 downto 0), 
         ZeroOut: out std_logic);  
end component;

component main_control
    port(Instruction: in std_logic_vector(31 downto 0); 
         MemWrite, RegDst, ALUSrc, Branch, Jump, MemtoReg, MemRead, RegWrite: out std_logic;
         ALUOp: out std_logic_vector(1 downto 0));
end component;

component alucontrol
    port(ALUOp: in std_logic_vector(1 downto 0); 
         Instruction: in std_logic_vector(31 downto 0); 
         ALUFunc: out std_logic_vector (1 downto 0));
end component;


begin
    signal int_pcout, int_aluresult, int_readdata1, int_readdata2, int_writedata : std_logic_vector(7 downto 0);
    signal int_instruction : std_logic_vector(31 downto 0);
    signal int_zero, int_memwrite, int_regdst, int_alusrc, int_branch, int_jump, int_memtoreg, int_memread, int_regwrite : std_logic;
    signal int_aluop, int_alufunc: std_logic_vector(1 downto 0);
    signal int_controlinfo : std_logic_vector(7 downto 0);

control: maincontrol
    port map(
        Instruction => int_instruction,
        MemWrite => int_memwrite,
        RegDst => int_regdst,
        ALUSrc => int_alusrc,
        Branch => int_branch,
        Jump => int_jump,
        MemtoReg => int_memtoreg,
        MemRead => int_memread,
        RegWrite => int_regwrite,
        ALUOp => int_aluop
    );

alucontrol: alucontrol
    port map(
        ALUOp => int_aluop,
        Instruction => int_instruction,
        ALUFunc => int_alufunc
    );


datapath: sc_datapath
    port map(
        GClk => GClk,  
        GReset => greset_b,  
        MemWrite => int_memwrite,
        RegDst => int_regdst,
        ALUSrc => int_alusrc,
        Branch => int_branch,
        Jump => int_jump,
        MemtoReg => int_memtoreg,
        MemRead => int_memread,
        RegWrite => int_regwrite,
        ALUFunc => int_alufunc,
        PCOut => int_pcout,
        ALUResult => int_aluresult,
        ReadData1 => int_readdata1,
        ReadData2 => int_readdata2,
        WriteDate => int_writedata,
        InstructionOut => int_instruction,
        ZeroOut => int_zero
    );

int_controlinfo <= '0' & int_regdst & int_jump & int_memread & int_memtoreg & int_aluop & int_alusrc;

ValueSelectMux: nbit8to1mux
    port map(
        i0 => int_pcout,
        i1 => int_aluresult,
        i2 => int_readdata1,
        i3 => int_readdata2,
        i4 => int_writedata,
        i5 => int_controlinfo,
        i6 => int_controlinfo,
        i7 => int_controlinfo,
        sel => ValueSelect,
        o => MuxOut
    );

greset_b <= NOT Greset;

InstructionOut <= int_instruction;
BranchOut <= int_branch;
ZeroOut <= int_zero;
MemWriteOut <= int_memwrite;
RegWriteOut <= int_regwrite;

end rtl; 