library ieee;
use ieee.std_logic_1164.all;


library lpm;
use lpm.lpm_components.all;


entity sc_datapath is
	port(GClk, GReset, MemWrite: in std_logic);

end sc_datapath;


architecture rtl of sc_datapath is
signal greset_b: std_logic;
signal int_read_reg1, int_read_reg2, int_write_reg: std_logic_vector(4 downto 0);
signal int_read_data, int_read_data2, int_write_data: std_logic_vector(7 downto 0);

component lpm_rom
    generic (
        LPM_WIDTH     : integer;
        LPM_WIDTHAD   : integer;
        LPM_FILE      : string;
        LPM_OUTTYPE   : string := "UNREGISTERED"  -- or "REGISTERED"
    );
    port (
        address : in std_logic_vector(LPM_WIDTHAD-1 downto 0);
        inclock : in std_logic := '0';  -- optional, depending on output type
        q       : out std_logic_vector(LPM_WIDTH-1 downto 0)
    );
end component;

component lpm_ram_dq


component lpm_ram_dq
    generic (
        LPM_WIDTH     : integer;        -- Data width
        LPM_WIDTHAD   : integer;        -- Address width
        LPM_NUMWORDS  : integer := 0;   -- Optional: defaults to 2^LPM_WIDTHAD
        LPM_INDATA    : string  := "REGISTERED";
        LPM_OUTDATA   : string  := "REGISTERED";
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
	port(clock, reset_b: in std_logic; 
		  read_reg1, read_reg2, write_reg: in std_logic_vector(4 downto 0); 
		  write_data: in std_logic_vector(7 downto 0); 
		  read_data1, read_data2: out std_logic_vector(7 downto 0));
end component;

begin 

instr_mem : lpm_rom
    generic map (
        LPM_WIDTH   => 32,
        LPM_WIDTHAD => 8,
        LPM_FILE    => "rom_init.mif",
        LPM_OUTTYPE => "REGISTERED"
    )
    port map (
        address => --need to assign,
        inclock => GClk,
        q       => --need to assign
    );


reg_file: register_file
	port(clock => GClk, reset_b => greset_b, 
		 read_reg1 => int_read_reg1, 
		 read_reg2 => int_read_reg2, 
		 write_reg => int_write_reg, 
		 write_data => int_write_data;
		 read_data1 => int_read_data1, 
		 read_data2 => int_read_data2);

data_mem : lpm_ram_dq
    generic map (
        LPM_WIDTH    => 32,
        LPM_WIDTHAD  => 3,
        LPM_FILE     => "ram_init.mif",
        LPM_OUTDATA  => "REGISTERED",
        LPM_INDATA   => "REGISTERED"
    )
    port map (
        data     => --need to assign,
        address  => --need to assign,
        inclock  => GClk,
        we       => MemWrite,
        q        => --need to assign
    );


greset_b <= NOT Greset;
end rtl;



