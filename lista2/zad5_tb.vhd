LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
 
ENTITY zad5_tb IS
END zad5_tb;

ARCHITECTURE behavior OF zad5_tb IS 

	COMPONENT zad5 IS
		generic (width: integer);
		port (s: in std_logic;
			  A,B: in std_logic_vector(width-1 downto 0);
			  	X: out std_logic_vector(width-1 downto 0) 
			  );
	END COMPONENT;

	constant w : integer := 3;

	signal s : std_logic := '0';
	signal A,B : std_logic_vector(w-1 downto 0) := (others => '0');

	signal X : std_logic_vector(w-1 downto 0);

	constant period : time := 10 ns;
	constant t : integer := 2 ** w;

BEGIN

	UUT: zad5 generic map (width => w)
				port map(
					s => s,
					A => A,
					B => B,
					X => X
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

		s <= '1';

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