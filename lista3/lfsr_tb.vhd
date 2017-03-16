library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity lfsr_tb is
end lfsr_tb;

architecture behavior of lfsr_tb is
	
	component lfsr
	port( clk : in std_logic;
		  q : inout std_logic_vector(15 downto 0)
		);
	end component;

	signal clk : std_logic := '0';

	signal q : std_logic_vector(15 downto 0);

	constant clk_period : time := 20 ns;
 
begin
	uut: lfsr port map(
		clk => clk,
		q => q
		);
	
	clk_process: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

		
end;