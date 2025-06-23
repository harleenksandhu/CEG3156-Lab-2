LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nbit8to1mux IS 
	GENERIC(n: integer:=8);
	PORT ( i0, i1, i2, i3, i4, i5, i6, i7 : IN std_logic_vector( n-1 downto 0);
			 sel : IN std_logic_vector(2 downto 0);
			 o : OUT std_logic_vector( n-1 downto 0));
END nbit8to1mux;

ARCHITECTURE behav of nbit8to1mux IS
	BEGIN
	o <= i0 when sel = "000" else 
		  i1 when sel = "001" else
		  i2 when sel="010" else
		  i3 when sel = "011" else 
		  i4 when sel = "100" else 
		  i5 when sel = "101" else 
		  i6 when sel = "110" else 
		  i7;
		 
END behav;