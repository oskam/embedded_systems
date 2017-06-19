library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- reg is a component that stores single value for specific purpose
-- every register is instatinated from this component with it's unique REG_ID.
-- reg is statemachine with 3 states: IDLE, READ_BUS and WRITE_BUS.
-- In IDLE it listens BUS for matching ID and unique REG_ID, bit 4 codes which mode to activate: `1` for READ_BUS, `0` for WRITE_BUS.
-- If Ids match, reg will change state on next clock cycle, then go back to IDLE.
-- BUS is read on first cycle after activation, when it is written on second cycle allowing for one more instruction on BUS to be executed before reg value is returned.

entity reg is
    generic(
        -- ID: allpws component activation
        ID       : std_logic_vector (3 downto 0) := "1100";
        -- REG_ID: allows creating multiple regiters and activating only one
        REG_ID   : std_logic_vector (2 downto 0);
        -- REG_SIZE: bit size of register
        REG_SIZE : integer
    );
    port(
        -- conn_bus: shared BUS
        conn_bus : inout std_logic_vector(8 downto 0);
        -- signal to access register value outside, when other component have direct access to it
        out_reg  : out std_logic_vector(REG_SIZE-1 downto 0) := (others => 'Z');
        -- clk: system clock for synchronization
        clk      : in std_logic
    );
end entity reg;

architecture behavior of reg is
    -- statemachine definitions
    type state_type is (IDLE, READ_BUS, WRITE_BUS);
    signal current_s : state_type := IDLE;
    signal next_s    : state_type := IDLE;

    -- for debugging entity's state
    signal vstate    : std_logic_vector(1 downto 0) := (others => '0');

    -- input buffer
    signal q         : std_logic_vector (8 downto 0) := (others => 'Z');

    -- for storing results and indicating it is to be sent to bus
    signal result_reg : std_logic_vector (8 downto 0) := (others => '0');
    signal sending   : std_logic := '0';

    -- register
    signal var_reg : std_logic_vector(REG_SIZE-1 downto 0) := (others => 'Z');

begin
    clock: process(clk)
    begin
        if rising_edge(clk)
        then
            q  <= conn_bus;
            current_s <= next_s;
        end if;
    end process;

    nextstate: process(current_s, q)
    begin
        case current_s is
            when IDLE =>
                vstate <= "00";
                -- bits 8 to 5 are ID,
                -- bit 4 is mode selector,
                -- bits 3 to 1 are REG_ID,
                -- bit 0 is not used
                if q(8 downto 5) = ID and q(3 downto 1) = REG_ID
                then
                    if q(4) = '1'
                    then
                        next_s <= READ_BUS;
                    else
                        next_s <= WRITE_BUS;
                    end if;
                else
                    next_s <= IDLE;
                end if;
                sending <= '0';
            when READ_BUS =>
                vstate <= "01";
                var_reg <= q(REG_SIZE-1 downto 0);
                next_s <= IDLE;
            when WRITE_BUS =>
                -- if REG_SIZE is lower than bus size, result have to be left padded with 0s
                result_reg <= (8 downto REG_SIZE => '0') & var_reg;
                sending <= '1';
                next_s <= IDLE;
            when others =>
                next_s <= IDLE;
        end case;

        out_reg <= var_reg;
    end process;

    -- tri-state bus
    stim: process
    begin
        if sending = '1' then
            conn_bus <= result_reg;
        else
            conn_bus <= (others => 'Z');
        end if;
        -- synchronize with CU cycles to allow free cycle for other instruction
        wait until falling_edge(clk);
    end process;

end behavior;
