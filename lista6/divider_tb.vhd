library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_tb is
end divider_tb;

architecture divider_arch of divider_tb is
    component divider
    generic (
        Nbit : natural;
	    Div_down : natural;
        Div_up : natural
	    );
     port (
        clk: in std_logic;
	    clk_out: inout std_logic := '0'
	    );
     end component;

    signal clk : std_logic := '0';
    signal clk_period : time := 8 ns;

    -- 100Hz:
    -- 125Mhz/100Hz/2 = 625000
    constant Nbit_100Hz : natural := 21;
    constant Div_100Hz : natural := 625000*2;
    signal clk_100Hz : std_logic := '0';

    -- 1.1kHz:
    -- 125Mhz/1.1kHz/2 = 56818.181...
    constant Nbit_11kHz : natural := 17;
    constant Div_11kHz_up : natural := 56818*2;
    constant Div_11kHz_down : natural := 56818*2+1;
    signal clk_11kHz : std_logic := '0';

    -- 50Mhz:
    -- 125Mhz/50Mhz/2 = 1.25
    constant Nbit_50Mhz : natural := 2;
    constant Div_50Mhz_up: natural := 3;
    constant Div_50Mhz_down: natural := 2;
    signal clk_50Mhz : std_logic := '0';

begin
    divider_100Hz: divider
        generic map (
            Nbit => Nbit_100Hz,
            Div_up => Div_100Hz,
            Div_down => Div_100Hz
        )
        port map (
            clk  => clk,
            clk_out => clk_100Hz
        );

     divider_11kHz: divider
        generic map (
            Nbit => Nbit_11kHz,
            Div_up => Div_11kHz_up,
            Div_down => Div_11kHz_down
        )
        port map (
            clk  => clk,
            clk_out => clk_11kHz
        );

      divider_50Mhz: divider
        generic map (
            Nbit => Nbit_50Mhz,
            Div_up => Div_50Mhz_up,
            Div_down => Div_50Mhz_down
        )
        port map (
            clk  => clk,
            clk_out => clk_50Mhz
        );


    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
        
    -- Stimulus process
    stim_proc : process
    begin
        wait;
    end process;
end;
