library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- alu is a component to execute simple operations: addition, subtraction and comparison.
-- values for this operations come from input signals of ac_reg and mbr_reg.
-- In IDLE it listens BUS for matching ID and mode selector.
-- When Id matches, alu will execute command on values in ac and mbr and send result to BUS on second cycle allowing for one more instruction on BUS to be executed before value is returned.
-- When activated in comparison mode, comparison_signal will be set to `1` when comparison on ac is true, `0` when not.

entity alu is
    generic(
        -- ID: allpws component activation
        ID : std_logic_vector (3 downto 0)
    );
    port(
        -- conn_bus: shared BUS
        conn_bus   : inout std_logic_vector(8 downto 0);
        -- memory buffer register input
        mbr_reg_in : in std_logic_vector(8 downto 0);
        -- accumulator register input
        ac_reg_in  : in std_logic_vector(8 downto 0);
        -- signal output to CU
        -- set to `1` requested comparison yielded true
        comparison_signal : out std_logic := '0';
        clk        : in std_logic
    );
end entity alu;

architecture behavior of alu is

    -- statemachine definitions
    type state_type is (IDLE, WRITE_BUS);
    signal current_s : state_type := IDLE;
    signal next_s    : state_type := IDLE;

    -- for debugging entity's state
    signal vstate    : std_logic_vector(1 downto 0) := (others => '0');

    -- input buffer
    signal q         : std_logic_vector (8 downto 0) := (others => 'Z');

    -- for storing results and indicating it is to be sent to bus
    signal result_reg : std_logic_vector (8 downto 0) := (others => '0');
    signal sending   : std_logic := '0';

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
        -- ac_reg value converted to number
        variable ac_int  : integer;
        -- mbr_reg value converted to number
        variable mbr_int : integer;
    begin
        case current_s is
            when IDLE =>
                vstate <= "00";
                -- reset signals
                sending <= '0';
                comparison_signal <= '0';

                -- bits 8 to 5 are ID,
                -- bits 4 to 2 are mode selector,
                -- other bits are not used
                if q(8 downto 5) = ID
                then
                    if q(4 downto 2) = "111" -- ADDITION
                    then
                        -- get abs value of registers
                        ac_int := to_integer(unsigned(ac_reg_in(6 downto 0)));
                        mbr_int := to_integer(unsigned(mbr_reg_in(6 downto 0)));

                        -- check sign and change if needed
                        if ac_reg_in(8 downto 7) = "01"
                        then
                            ac_int := -1 * ac_int;
                        end if;
                        if mbr_reg_in(8 downto 7) = "01"
                        then
                            mbr_int := -1 * mbr_int;
                        end if;

                        -- calculate result of addition
                        ac_int := ac_int + mbr_int;

                        next_s <= WRITE_BUS;

                    elsif q(4 downto 2) = "000" -- SUBTRACTION
                    then
                        -- get abs value of registers
                        ac_int := to_integer(unsigned(ac_reg_in(6 downto 0)));
                        mbr_int := to_integer(unsigned(mbr_reg_in(6 downto 0)));

                        -- check sign and change if needed
                        if ac_reg_in(8 downto 7) = "01"
                        then
                            ac_int := -1 * ac_int;
                        end if;
                        if mbr_reg_in(8 downto 7) = "01"
                        then
                            mbr_int := -1 * mbr_int;
                        end if;

                        -- calculate result of subtraction
                        ac_int := ac_int - mbr_int;

                        next_s <= WRITE_BUS;

                    elsif q(4 downto 2) = "001" -- COMPARE <
                    then
                        -- check if ac_reg is negative
                        if ac_reg_in(8 downto 7) = "01"
                        then -- AC < 0
                            comparison_signal <= '1';
                        end if;
                        next_s <= IDLE;

                    elsif q(4 downto 2) = "010" -- COMPARE =
                    then
                        -- chec if ac_reg is zero
                        if ac_reg_in(6 downto 0) = "0000000"
                        then -- AC == 0
                            comparison_signal <= '1';
                        end if;
                        next_s <= IDLE;

                    elsif q(4 downto 2) = "100" -- COMPARE >
                    then
                        -- check if ac_reg is positive but not 0
                        if ac_reg_in(8 downto 7) = "00" and ac_reg_in(6 downto 0) /= "0000000"
                        then -- AC > 0
                            comparison_signal <= '1';
                        end if;
                        next_s <= IDLE;
                    end if;
                else
                    next_s <= IDLE;
                end if;

            when WRITE_BUS =>
                -- check for overflow
                if ac_int > 127
                then
                    ac_int := 127;
                    report "overflow, reduced to 127" severity warning;
                end if;
                if ac_int < -127
                then
                    ac_int := -127;
                    report "overflow, reduced to -127" severity warning;
                end if;

                -- set sign
                -- convert result number to signal
                if ac_int < 0
                then
                    result_reg <= "01" & std_logic_vector(to_unsigned(-1 * ac_int, 7));
                else
                    result_reg <= "00" & std_logic_vector(to_unsigned(ac_int, 7));
                end if;

                sending <= '1';
                next_s <= IDLE;

            when others =>
                next_s <= IDLE;
        end case;
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
