library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- pc is a counter component that stores line number to be read from memory next.
-- it has input signal that will increase counter every time it goes from Lo to Hi.
-- In IDLE it listens BUS for matching ID, bit 4 codes which mode to activate: `1` for READ_BUS (to jump in program), `0` for WRITE_BUS.
-- If Id matches, pc will change state on next clock cycle, then go back to IDLE.
-- BUS is read on first cycle after activation, when it is written on second cycle allowing for one more instruction on BUS to be executed before pc value is returned.

entity pc is
    generic(
        -- ID: allpws component activation
        ID    : std_logic_vector (3 downto 0) := "1011"
    );
    port(
        -- conn_bus: shared BUS
        conn_bus : inout std_logic_vector(8 downto 0);
        -- increment signal input to increase counter
        inc_s    : in std_logic;
        -- clk: system clock for synchronization
        clk      : in std_logic
    );
end entity pc;

architecture behavior of pc is
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

    -- counter register
    shared variable counter_reg : std_logic_vector(4 downto 0) := (others => '0');

begin
    clock: process(clk)
    begin
      	if rising_edge(clk)
        then
            q  <= conn_bus;
            current_s <= next_s;
  		end if;
    end process;

    increment: process(inc_s)
    begin
        -- when inc_s goes Hi increase counter by 1
        if rising_edge(inc_s)
        then
            counter_reg := std_logic_vector(unsigned(counter_reg) + 1);
        end if;
    end process;

    nextstate: process(current_s, q)
    begin
        case current_s is
            when IDLE =>
                vstate <= "00";
                -- bits 8 to 5 are ID,
                -- other bits are not used
                if q(8 downto 5) = ID
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
                -- use only lower 5 bits (address is 5 bit only)
                counter_reg := q(4 downto 0);
                next_s <= IDLE;
            when WRITE_BUS =>
                -- add left padding to get 9 bits
                result_reg <= "0000" & counter_reg;
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
