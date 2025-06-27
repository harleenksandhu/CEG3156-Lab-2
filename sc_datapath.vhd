library ieee;
use ieee.std_logic_1164.all;


library altera_mf;
library lpm;
use lpm.lpm_components.all;


entity sc_datapath is
	port(GClk, GReset, MemWrite, RegDst, ALUSrc, Branch, Jump, MemtoReg, MemRead, RegWrite: in std_logic;  -- from overall control block
         ALUFunc: in std_logic_vector(1 downto 0);   -- from ALU control block
         PCOut, ALUResult, ReadData1, ReadData2, WriteData: out std_logic_vector(7 downto 0);    -- for MuxOut get control signals from control path
         InstructionOut: out std_logic_vector(31 downto 0); 
         ZeroOut: out std_logic);  

end sc_datapath;


architecture rtl of sc_datapath is
signal greset_b, int_alu_zero_out, int_alu_cout, int_selBranch: std_logic;
signal int_read_reg1, int_read_reg2, int_write_reg: std_logic_vector(4 downto 0);
signal int_read_data1, int_read_data2, int_write_data, int_instr_out_ext, int_adder_result, int_read_data_mem: std_logic_vector(7 downto 0);
signal int_selBranchMuxOut, int_instr_out_shft, int_PCIn, int_PCOut, int_incPC, int_memToReg_out, int_alu_result, int_aluOpB: std_logic_vector(7 downto 0);
signal int_instr_out: std_logic_vector(31 downto 0);


component lpm_rom
    generic (
        LPM_WIDTH     : integer;
        LPM_WIDTHAD   : integer;
        LPM_FILE      : string;
        LPM_OUTDATA   : string := "UNREGISTERED"  -- or "REGISTERED"
    );
    port (
        address : in std_logic_vector(LPM_WIDTHAD-1 downto 0);
        inclock : in std_logic := '0';  -- optional, depending on output type
        q       : out std_logic_vector(LPM_WIDTH-1 downto 0)
    );
end component;


component lpm_ram_dq
    generic (
        LPM_WIDTH     : integer;        -- Data width
        LPM_WIDTHAD   : integer;        -- Address width
        LPM_NUMWORDS  : integer := 0;   -- Optional: defaults to 2^LPM_WIDTHAD
        LPM_INDATA    : string  := "REGISTERED";
        LPM_OUTDATA   : string  := "UNREGISTERED";
        LPM_FILE      : string  := "UNUSED";  -- .mif file (optional)
        LPM_TYPE      : string  := "LPM_RAM_DQ";
        LPM_HINT      : string  := "USE_EAB=ON"
    );
    port (
        data     : in std_logic_vector(LPM_WIDTH-1 downto 0);
        address  : in std_logic_vector(LPM_WIDTHAD-1 downto 0);
        inclock  : in std_logic;
        we       : in std_logic;
        q        : out std_logic_vector(LPM_WIDTH-1 downto 0)
    );
end component;

component register_file
	port(clock, reset_b, regwrite: in std_logic; 
		  read_reg1, read_reg2, write_reg: in std_logic_vector(4 downto 0); 
		  write_data: in std_logic_vector(7 downto 0); 
		  read_data1, read_data2: out std_logic_vector(7 downto 0));
end component;

component nbit2to1mux
    GENERIC(n: integer:=8);
	PORT ( i_0, i_1 : IN std_logic_vector( n-1 downto 0);
			 sel1 : IN std_logic;
			 o : OUT std_logic_vector( n-1 downto 0));
end component;

component nbit8to1mux
	GENERIC(n: integer:=8);
	PORT ( i0, i1, i2, i3, i4, i5, i6, i7 : IN std_logic_vector( n-1 downto 0);
			 sel : IN std_logic_vector(2 downto 0);
			 o : OUT std_logic_vector( n-1 downto 0));
end component;

component nbitreg
    generic(n: integer:=4);
	port(reset_b: in std_logic;
		  din : in std_logic_vector(n-1 downto 0);
		  load, clk: in std_logic;
		  dout, dout_b : out std_logic_vector(n-1 downto 0));
end component;

component nbitaddersubtractor
	generic(n: integer:= 8);
	port(x : in STD_LOGIC_VECTOR(n-1 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(n-1 downto 0); -- Second operand
        cin : in STD_LOGIC;			-- Control signal for operation type
        sum : out STD_LOGIC_VECTOR(n-1 downto 0);  -- Result
        cout : out STD_LOGIC		-- Carry out
    );
end component;

component eightbitalu
	port(x : in STD_LOGIC_VECTOR(7 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(7 downto 0); -- Second operand
        opcode : in STD_LOGIC_VECTOR(1 downto 0);  -- 00=ADD, 01=SUB, 10=AND, 11=OR
        ALUResult : out STD_LOGIC_VECTOR(7 downto 0);  -- Result
        cout : out STD_LOGIC;		-- Carry out
		zero : out STD_LOGIC   	-- Zero flag
    );
end component;


begin 

PC_adder: nbitaddersubtractor
	generic map(n => 8)
	port map( x => int_PCOut, y => "00000100", cin => '0', 
              sum => int_incPC, cout => open);

PC: nbitreg
    generic map(n => 8)
    port map(reset_b => greset_b, din => int_PCIn, load => '1', 
             clk => GClk, dout => int_PCOut, dout_b => open);

instr_mem : lpm_rom
    generic map (
        LPM_WIDTH   => 32,
        LPM_WIDTHAD => 8,
        LPM_FILE    => "rom2_init.mif",
        LPM_OUTDATA => "UNREGISTERED"
    )
    port map (
        address => int_PCOut,
        inclock => GClk,
        q       => int_instr_out
    );

regDstMux: nbit2to1mux
    generic map(n => 5)
    port map (i_0 => int_instr_out(20 downto 16), i_1 => int_instr_out(15 downto 11), 
              sel1 => RegDst, o => int_write_reg);

reg_file: register_file
	port map(clock => GClk, reset_b => greset_b, 
         regwrite => RegWrite,
		 read_reg1 => int_read_reg1, 
		 read_reg2 => int_read_reg2, 
		 write_reg => int_write_reg, 
		 write_data => int_memToReg_out,
		 read_data1 => int_read_data1, 
		 read_data2 => int_read_data2);

aluSrcMux: nbit2to1mux
    generic map(n => 8)
    port map(i_0 => int_read_data2, i_1 => int_instr_out_ext, 
             sel1 => AluSrc, o => int_aluOpB);

alu: eightbitalu
    port map(x => int_read_data1,
            y => int_aluOpB, 
            opcode => ALUFunc,
            ALUResult => int_alu_result,
            cout => int_alu_cout,  -- used no where, for debugging
            zero => int_alu_zero_out);

adder: nbitaddersubtractor
	generic map(n => 8)
	port map( x => int_incPC, y => int_instr_out_shft, cin => '0', 
              sum => int_adder_result, cout => open);


selBranchMux: nbit2to1mux
    generic map(n => 8)
    port map(i_0 => int_incPC, i_1 => int_adder_result, 
             sel1 => int_selBranch, o => int_selBranchMuxOut);


jumpMux: nbit2to1mux
    generic map(n => 8)
    port map(i_0 => int_instr_out_shft, i_1 => int_selBranchMuxOut, 
             sel1 => Jump, o => int_PCIn);



data_mem : lpm_ram_dq
    generic map (
        LPM_WIDTH    => 8,
        LPM_WIDTHAD  => 8,
        LPM_FILE     => "ram_init.mif",
        LPM_OUTDATA  => "UNREGISTERED",
        LPM_INDATA   => "REGISTERED"
    )
    port map (
        data     => int_read_data2,
        address  => int_alu_result,
        inclock  => GClk,
        we       => MemWrite,
        q        => int_read_data_mem
    );

memtoRegMux: nbit2to1mux
    generic map(n => 8)
    port map(i_0 => int_read_data_mem, i_1 => int_alu_result, 
             sel1 => MemToReg, o => int_memToReg_out);

greset_b <= NOT Greset;
int_instr_out_ext <= int_instr_out(5) & int_instr_out(5) & int_instr_out(5 downto 0); --sign extend instructionOut
int_instr_out_shft <= int_instr_out(5 downto 0) & "00";
int_selBranch <= int_alu_zero_out AND Branch;


-- Outputs
ZeroOut <= int_alu_zero_out;
PCOut <= int_PCOut;
ALUResult <= int_alu_result;
ReadData1 <= int_read_data1;
ReadData2 <= int_read_data2;
WriteData <= int_write_data;
InstructionOut <= int_instr_out;

end rtl;



