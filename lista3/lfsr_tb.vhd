library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use std.textio.all; 

entity lfsr_tb is
end lfsr_tb;

architecture behavior of lfsr_tb is

component lfsr
port( clk : in std_logic;
			rst : in std_logic;
				q : inout std_logic_vector(15 downto 0)
		);
end component;

signal clk : std_logic := '0';
signal rst : std_logic := '1';

signal q : std_logic_vector(15 downto 0);

constant clk_period : time := 20 ns;

begin
	uut: lfsr port map(
		clk => clk,
		rst => rst,
		q => q
		);

	clk_process: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	stim_proc: process
		variable l : line;
		variable str : string(16 downto 1);
	begin
		for j in 0 to 50 loop
			--if (j mod 10) = 0 then
			--	rst <= '0';
			--	wait for clk_period;
			--	rst <= '1';
			--end if; 
			for i in str'high downto str'low loop
				wait for clk_period;
				str(i) := std_logic'image(q(15))(2);
			end loop;
			write(l, str);
			writeline(output, l);
		end loop;
		wait;
	end process;
end;