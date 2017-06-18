LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE behavior OF alu_tb IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT alu is
        generic(
            ID : std_logic_vector (3 downto 0)
        );
        port(
            conn_bus          : inout std_logic_vector(8 downto 0);
            mbr_reg_in        : in std_logic_vector(8 downto 0);
            ac_reg_in         : in std_logic_vector(8 downto 0);
            comparison_signal : out std_logic;
            clk               : in std_logic
        );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';

    --Dummy MBR, AC
    signal mbr_reg : std_logic_vector(8 downto 0) := (others => '0');
    signal ac_reg  : std_logic_vector(8 downto 0) := (others => '0');

    signal cmp_signal : std_logic := '0';

    --BiDirs
    signal conn_bus : std_logic_vector(8 downto 0) := (others => 'Z');

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
    test_alu: alu
	GENERIC MAP (
        ID => "1101"
    )
	PORT MAP (
        conn_bus   => conn_bus,
        mbr_reg_in => mbr_reg,
        ac_reg_in  => ac_reg,
        comparison_signal => cmp_signal,
        clk        => clk
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
        wait for clk_period*2;

        -- set dummy AC and MAR values
        ac_reg <= "000011010"; -- 26
        mbr_reg <= "010001101"; -- -13

        -- Activate ALU in ADDITION mode
        conn_bus <= "110111100";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000001101" report "addition fail"; -- 26 + (-13) = 13

        -- Activate ALU in SUBTRACT mode
        conn_bus <= "110100000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        wait for clk_period*2;
        assert conn_bus = "000100111" report "subtraction fail"; -- 26 - (-13) = 39

        wait for clk_period;

        -- Activate ALU in COMPARISON > mode
        conn_bus <= "110110000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        assert cmp_signal = '1' report "comparison > fail"; -- 28 > 0

        -- Activate ALU in COMPARISON > mode
        conn_bus <= "110100100";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        assert cmp_signal = '0' report "comparison > fail"; -- 28 !< 0

        ac_reg <= "000000000"; -- 0
        -- Activate ALU in COMPARISON mode
        conn_bus <= "110101000";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        assert cmp_signal = '1' report "comparison = fail"; -- 0 = 0

        ac_reg <= "010001100"; -- -12
        -- Activate ALU in COMPARISON mode
        conn_bus <= "110100100";
        wait for clk_period;
        conn_bus <= (others => 'Z');
        assert cmp_signal = '1' report "comparison < fail"; -- -12 < 0

        wait;
    end process;
END;
