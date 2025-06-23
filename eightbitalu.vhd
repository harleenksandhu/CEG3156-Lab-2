library ieee;
use ieee.std_logic_1164.all;

entity eightbitalu is	
	port(x : in STD_LOGIC_VECTOR(7 downto 0); -- First operand
        y : in STD_LOGIC_VECTOR(7 downto 0); -- Second operand
        opcode : in STD_LOGIC_VECTOR(1 downto 0);  -- 00=ADD, 01=SUB, 10=AND, 11=OR
        ALUResult : out STD_LOGIC_VECTOR(7 downto 0);  -- Result
        cout : out STD_LOGIC;		-- Carry out
		zero : out STD_LOGIC   	-- Zero flag
    );
	
end eightbitalu;


architecture struc of eightbitalu is
SIGNAL carry, cins, yxor, sum, or_out, and_out, ALUResult_int: STD_LOGIC_VECTOR(7 downto 0);

COMPONENT fulladder IS
	PORT(x : in STD_LOGIC;
        y : in STD_LOGIC;
        cin : in STD_LOGIC;
        sum : out STD_LOGIC;
        cout : out STD_LOGIC);
END COMPONENT;

COMPONENT nbit4to1mux IS
	GENERIC(n: integer:=8);
	PORT ( i_0, i_1, i_2, i_3: IN std_logic;
			 sel1, sel2 : IN std_logic;
			 o : OUT std_logic);
END COMPONENT;

BEGIN 
	cins <= (others => opcode(0)); -- SUB if opcode = "01", else ADD
	yxor <= y XOR cins; -- Invert each bit of y if operation is subtraction
	
	--Logic OR and AND operations
	logic_gen: for i in 0 to 7 generate
        and_out(i) <= x(i) and y(i);
        or_out(i)  <= x(i) or y(i);
	end generate;

	-- ADD and SUB operations
	FA0: fulladder PORT MAP(x => x(0), y => yxor(0), cin => cins(0), sum => sum(0), cout => carry(0)); 
	addersubtractor: for i in 1 to 7 generate
	FAi: fulladder PORT MAP(x => x(i), y => yxor(i), cin => carry(i-1), sum => sum(i), cout => carry(i));
	end generate;

	-- Mux to select output based on opcode
	result_mux: for i in 0 to 7 generate
		ALUResult_int(i) <= sum(i) when opcode = "00" else  -- ADD
						sum(i) when opcode = "01" else  -- SUB
						and_out(i) when opcode = "10" else  -- AND
						or_out(i);                         -- OR
	
	end generate;
	
    -- Carry out only for ADD/SUB
    cout <= carry(7) when opcode = "00" or opcode = "01" else '0';

    -- Zero flag
    zero <= '1' when ALUResult_int = "00000000" else '0';

	ALUResult <= ALUResult_int;

end struc;