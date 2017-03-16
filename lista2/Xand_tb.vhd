LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
 
ENTITY Xand_tb IS
END Xand_tb;

ARCHITECTURE behavior OF Xand_tb IS 

	COMPONENT Xand IS
		generic (width: integer);
		port (clk: in std_logic;
			  A,B: in std_logic_vector(width-1 downto 0);
			  	C: out std_logic_vector(width-1 downto 0) 
			  );
	END COMPONENT;

	constant w : integer := 3;

	signal clk : std_logic := '0';
	signal A,B : std_logic_vector(w-1 downto 0) := (others => '0');

	signal C : std_logic_vector(w-1 downto 0);

	constant period : time := 10 ns;
	constant t : integer := 2 ** w;

BEGIN

	UUT: Xand generic map (width => w)
				port map(
					clk => clk,
					A => A,
					B => B,
					C => C
				);

	stim_proc: process
	begin

      	for i in 1 to t loop
      		for j in 1 to t loop
      			wait for period;
      			B <= (std_logic_vector(unsigned(B) + 1));
      		end loop;
      		A <= (std_logic_vector(unsigned(A) + 1));
      	end loop;
      	wait for period;
		wait;
	end process;

END;