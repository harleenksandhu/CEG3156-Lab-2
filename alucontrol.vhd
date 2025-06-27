library ieee;
use ieee.std_logic_1164.all;


entity alucontrol is
    port(ALUOp: in std_logic_vector(1 downto 0); 
         Instruction: in std_logic_vector(31 downto 0); 
         ALUFunc: out std_logic_vector (1 downto 0));
end alucontrol;

architecture struc of alucontrol is
signal F0, F1, F2, F3: std_logic;

begin

F0 <= Instruction(0);
F1 <= Instruction(1);
F2 <= Instruction(2);
F3 <= Instruction(3);

ALUFunc(1) <= '0' when ALUOp = "00" else 
              '0' when ALUOp = "X1" else  
              (ALUOp(1) and (not F3) and F2 and (not F1)); 

ALUFunc(0) <= '0' when ALUOp = "00" else  
              '1' when ALUOp = "X1" else
              (ALUOp(1) and (not F3) and (not F2) and F1 and (not F0)) 
            or (ALUOp(1) and (not F3) and F2 and (not F1) and F0);

end struc;
