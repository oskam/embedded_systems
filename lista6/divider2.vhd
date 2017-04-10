library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider2 is
generic (
	N : natural
	);

port (
	clk: in std_logic;
	clk_out: out unsigned(N downto 0) := (others => '0')
	);
end divider2;

architecture divider2_arch of divider2 is
	signal cnt: unsigned(N downto 0) := (others => '0');

begin

	process(clk)
	begin
		if rising_edge(clk) then
			cnt <= cnt + 1;       
		end if;
	end process;
	clk_out <= cnt;

end divider2_arch;
