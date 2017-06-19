library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity cu_tb is
end cu_tb;

architecture behavior of cu_tb is

    COMPONENT ram is
        generic(
            ID    : std_logic_vector (3 downto 0);
            filename : string
        );
        port(
            conn_bus   : inout std_logic_vector(8 downto 0);
            mar_reg_in : in std_logic_vector(4 downto 0);
            clk        : in std_logic
        );
    END COMPONENT;

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

    COMPONENT cu IS
        port(
            conn_bus       : inout std_logic_vector (8 downto 0);
            alu_cmp_signal : in std_logic := '0';
            clk            : in std_logic
        );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';

    --BiDirs
    signal conn_bus : std_logic_vector(8 downto 0) := (others => 'Z');

    --ALU registers inputs
    signal cmp_signal : std_logic := '0';
    signal mbr_reg : std_logic_vector(8 downto 0);
    signal ac_reg : std_logic_vector(8 downto 0);

    --RAM registers inputs
    signal mar_reg : std_logic_vector(4 downto 0);

    --CU register output
    signal out_reg : std_logic_vector(8 downto 0);

    -- components IDs
    constant RAM_ID : std_logic_vector(3 downto 0) := "1010";
    constant REG_ID : std_logic_vector(3 downto 0) := "1100";
    constant ALU_ID : std_logic_vector(3 downto 0) := "1101";

    -- registers IDs
    constant IR_REG_ID  : std_logic_vector(2 downto 0) := "000";
    constant MAR_REG_ID : std_logic_vector(2 downto 0) := "001";
    constant MBR_REG_ID : std_logic_vector(2 downto 0) := "010";
    constant AC_REG_ID  : std_logic_vector(2 downto 0) := "011";
    constant IN_REG_ID  : std_logic_vector(2 downto 0) := "100";
    constant OUT_REG_ID : std_logic_vector(2 downto 0) := "101";

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    ram_unit: ram
	GENERIC MAP (
        ID => RAM_ID,
        filename => "test.marie"
    )
	PORT MAP (
        conn_bus   => conn_bus,
        mar_reg_in => mar_reg,
        clk        => clk
    );

    alu_unit: alu
    GENERIC MAP (
        ID => ALU_ID
    )
    PORT MAP (
        conn_bus   => conn_bus,
        mbr_reg_in => mbr_reg,
        ac_reg_in  => ac_reg,
        comparison_signal => cmp_signal,
        clk        => clk
    );

    mar_register: reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => MAR_REG_ID,
        REG_SIZE => 5
    )
	PORT MAP (
        conn_bus => conn_bus,
        out_reg => mar_reg,
        clk => clk
    );

    mbr_register: reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => MBR_REG_ID,
        REG_SIZE => 9
    )
	PORT MAP (
        conn_bus => conn_bus,
        out_reg => mbr_reg,
        clk => clk
    );

    ac_register: reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => AC_REG_ID,
        REG_SIZE => 9
    )
	PORT MAP (
        conn_bus => conn_bus,
        out_reg => ac_reg,
        clk => clk
    );

    in_register: reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => IN_REG_ID,
        REG_SIZE => 9
    )
	PORT MAP (
        conn_bus => conn_bus,
        clk => clk
    );

    out_register: reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => OUT_REG_ID,
        REG_SIZE => 9
    )
	PORT MAP (
        conn_bus => conn_bus,
        out_reg => out_reg,
        clk => clk
    );

    control_unit: cu
    PORT MAP (
        conn_bus       => conn_bus,
        alu_cmp_signal => cmp_signal,
        clk            => clk
    );

    -- Clock process definitions
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- process printing out_reg when it changes and is set
    out_reg_print : process(out_reg)
        variable number : integer;
        variable line_var : line;
    begin
        -- if out_reg is set to value
        if out_reg(0) /= 'Z'
        then
            -- save abs value of out_reg as integer
            number := to_integer(unsigned(out_reg(6 downto 0)));

            -- check sign
            if out_reg(8 downto 7) = "01"
            then
                number := -1 * number;
            end if;

            -- write number to stdout
            write(line_var, integer'image(number));
            writeline(output, line_var);
        end if;
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        wait;
    end process;
end architecture;
