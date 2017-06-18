LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY reg_tb IS
END reg_tb;

ARCHITECTURE behavior OF reg_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT reg is
        generic(
            ID       : std_logic_vector(3 downto 0);
            REG_ID   : std_logic_vector(2 downto 0);
            REG_SIZE : integer
        );
        port(
            conn_bus : inout std_logic_vector(8 downto 0);
            out_reg  : out std_logic_vector(REG_SIZE-1 downto 0);
            clk      : in std_logic
        );
    END COMPONENT;

    constant REG_SIZE : integer := 3;

    --Inputs
    signal clk : std_logic := '0';

    --BiDirs
    signal conn_bus : std_logic_vector(8 downto 0) := (others => 'Z');

    signal register_out : std_logic_vector(REG_SIZE-1 downto 0);

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
    test_reg: reg
	GENERIC MAP (
        ID       => "1100",
        REG_ID   => "111",
        REG_SIZE => REG_SIZE
    )
	PORT MAP (
        conn_bus => conn_bus,
        out_reg => register_out,
        clk => clk
    );

    -- Clock process definitions
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        wait for clk_period;

        -- WRITE REG
        -- address
        -- use reg in READ_BUS
        conn_bus <= "110011110";
        wait for clk_period;
        -- data
        conn_bus <= "111111111";
        wait for clk_period*2;

        -- READ REG
        -- use reg in WRITE_BUS
        conn_bus <= "110001110";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000000111" report "reg != 7";

        -- WRITE REG2
        -- address
        -- use reg in READ_BUS
        conn_bus <= "110010000";
        wait for clk_period;
        -- data
        conn_bus <= "111111010";
        wait for clk_period*2;

        -- check REG
        wait for clk_period;
        assert register_out = "111" report "out_reg != 7";

        wait;
    end process;
END;
