LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ram_tb IS
END ram_tb;

ARCHITECTURE behavior OF ram_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT ram is
        generic(
            ID    : std_logic_vector (3 downto 0);
            filename : string
        );
        port(
            conn_bus : inout std_logic_vector(8 downto 0);
            mar_reg  : in std_logic_vector(4 downto 0);
            clk      : in std_logic
        );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';

    --Dummy MAR
    signal mar_reg : std_logic_vector(4 downto 0) := "00000";

    --BiDirs
    signal conn_bus : std_logic_vector(8 downto 0) := (others => 'Z');

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
    memory: ram
	GENERIC MAP (
        ID => "1010",
        filename => "test_file.marie"
    )
	PORT MAP (
        conn_bus => conn_bus,
        mar_reg => mar_reg,
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

        -- WRITE TO MEMORY ADDRESS 0
        -- address
        mar_reg <= "00000";
        -- use memory in READ_BUS
        conn_bus <= "101010000";
        wait for clk_period;
        -- data
        conn_bus <= "000010000";
        wait for clk_period*2;

        -- WRITE TO MEMORY ADDRESS 1
        -- address
        mar_reg <= "00001";
        -- use memory in READ_BUS
        conn_bus <= "101010000";
        wait for clk_period;
        -- data
        conn_bus <= "111111111";
        wait for clk_period*2;

        -- READ MEMORY ADDRESS 0
        -- address
        mar_reg <= "00000";
        -- use memory in WRITE_BUS
        conn_bus <= "101000000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000010000" report "memory[0] != 16";

        -- READ MEMORY ADDRESS 1
        -- address
        mar_reg <= "00001";
        -- use memory in WRITE_BUS
        conn_bus <= "101000000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "111111111" report "memory[0] != 511";

        -- WRITE TO MEMORY ADDRESS 1
        -- address
        mar_reg <= "00001";
        -- use memory in READ_BUS
        conn_bus <= "101010000";
        wait for clk_period;
        -- data
        conn_bus <= "000000000";
        wait for clk_period*2;

        -- READ MEMORY ADDRESS 1
        -- address
        mar_reg <= "00001";
        -- use memory in WRITE_BUS
        conn_bus <= "101000000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000000000" report "memory[0] != 0";

        wait;
    end process;
END;
