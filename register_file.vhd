library ieee;
use ieee.std_logic_1164.all;

entity register_file is
	port(clock, reset_b, regwrite: in std_logic; 
		  read_reg1, read_reg2, write_reg: in std_logic_vector(4 downto 0); 
		  write_data: in std_logic_vector(7 downto 0); 
		  read_data1, read_data2: out std_logic_vector(7 downto 0));
end register_file;


architecture rtl of register_file is

type reg_array is array (0 to 31) of std_logic_vector(7 downto 0); 
signal registers: reg_array; --array that will store output of each register in the reg file
signal int_load: std_logic_vector(31 downto 0);

component nbitreg
	generic( n: integer:= 4);
	port(reset_b: in std_logic;
		din : in std_logic_vector(n-1 downto 0);
		load, clk: in std_logic;
		dout, dout_b : out std_logic_vector(n-1 downto 0));
end component;

begin

int_load(to_integer(unsigned(write_reg))) <= regwrite; --load is changed only for the write_reg

reg_gen: for i in 0 to 32 generate
	reg_i: nbitreg
		generic map(n => 8)
		port map(reset_b => reset_b, din => write_data, load => int_load(i), 
		clk => clock, dout => registers(i), dout_b => open);
end generate;

read_data1 <= registers(to_integer(unsigned(read_reg1)));
read_data2 <= registers(to_integer(unsigned(read_reg2)));

end rtl;