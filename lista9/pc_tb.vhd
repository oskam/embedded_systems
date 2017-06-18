LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pc_tb IS
END pc_tb;

ARCHITECTURE behavior OF pc_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT pc is
        generic(
            ID    : std_logic_vector (3 downto 0) := "1011"
        );
        port(
            conn_bus : inout std_logic_vector(8 downto 0);
            inc_s    : in std_logic;
            clk      : in std_logic
        );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';

    --Increment signal
    signal increment : std_logic := '0';
    --BiDirs
    signal conn_bus : std_logic_vector(8 downto 0) := (others => 'Z');

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
    pc_reg: pc
	GENERIC MAP (
        ID => "1011"
    )
	PORT MAP (
        conn_bus => conn_bus,
        inc_s => increment,
        clk => clk
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;


    -- Stimulus process
    stim_proc: process
    begin
        wait for clk_period*10;

        -- WRITE PC
        -- address
        -- use pc in READ_BUS
        conn_bus <= "101110000";
        wait for clk_period;
        -- data
        conn_bus <= "000000011";
        wait for clk_period*2;

        -- READ PC
        -- use pc in WRITE_BUS
        conn_bus <= "101100000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000000011" report "pc != 3";

        -- INCREASE PC by 1
        increment <= '1';
        wait for clk_period;
        increment <= '0';
        wait for clk_period;

        -- READ PC
        -- use pc in WRITE_BUS
        conn_bus <= "101100000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000000100" report "pc != 4";

        -- INCREASE PC by 1
        increment <= '1';
        wait for clk_period;
        increment <= '0';
        wait for clk_period;

        -- READ PC
        -- use pc in WRITE_BUS
        conn_bus <= "101100000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000000101" report "pc != 5";

        wait;
    end process;
END;
