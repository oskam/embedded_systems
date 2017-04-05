library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
generic (
	Nbit : natural;
	Div_down : natural;
    Div_up : natural
	);

port (
	clk: in std_logic;
	clk_out: inout std_logic := '0'
	);
end divider;

architecture divider_arch of divider is

signal cnt: unsigned(NBit-1 downto 0) := (others=>'0');

begin

	process(clk)
	begin
		if (clk'event) then
            if clk_out = '1' then
			    if cnt < Div_up-1 then
				    cnt <= cnt + 1;
			    else
				    cnt <= (others=>'0');
				    clk_out <= not clk_out;
			    end if;
            elsif (clk_out='0') then
		        if cnt < Div_down-1 then
			        cnt <= cnt + 1;
		        else
			        cnt <= (others=>'0');
			        clk_out <= not clk_out;
		        end if;
            end if;          
		end if;
	end process;

end divider_arch;
