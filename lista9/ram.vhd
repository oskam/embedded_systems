library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- ram is component to store program. It allows reading file from text file on creation
-- In IDLE it listens BUS for matching ID, bit 4 codes which mode to activate: `1` for READ_BUS (to jump in program), `0` for WRITE_BUS.
-- If Id matches, ram will change state on next clock cycle, then go back to IDLE.
-- BUS is read on first cycle after activation, when it is written on second cycle allowing for one more instruction on BUS to be executed before ram value is returned.
-- address to load and store values is indicated by input signal mar_reg_in

entity ram is
    generic(
        -- ID: allpws component activation
        ID    : std_logic_vector (3 downto 0) := "1010";
        filename : string
    );
    port(
        -- conn_bus: shared BUS
        conn_bus   : inout std_logic_vector(8 downto 0);
        -- adress register input
        mar_reg_in : in std_logic_vector(4 downto 0);
        -- clk: system clock for synchronization
        clk        : in std_logic
    );
end entity ram;

architecture behavior of ram is

    -- statemachine definitions
    type state_type  is (IDLE, READ_BUS, WRITE_BUS);
    signal current_s : state_type := IDLE;
    signal next_s    : state_type := IDLE;

    -- for debugging entity's state
    signal vstate : std_logic_vector(1 downto 0) := (others => '0');

    -- input buffer
    signal q : std_logic_vector (8 downto 0) := (others => 'Z');

    -- for storing results and indicating it is to be sent to bus
    signal result_reg : std_logic_vector (8 downto 0) := (others => '0');
    signal sending    : std_logic := '0';

    -- memory cells
    constant RAM_SIZE : integer := 2 ** 5;
    -- new type for memory, ROM_SIZE of 9 bit cells
    type ram_type     is array (0 to RAM_SIZE-1) of std_logic_vector(8 downto 0);

    -- function to load file to memory on system start
    impure function read_file(filename : in string) return ram_type is
        -- opened_file: file given by filename in read mode
        file opened_file  : TEXT open READ_MODE is filename;
        -- line_var: variable to store line type object
        variable line_var : LINE;
        -- word: 9 bit word
        variable word     : STD_LOGIC_VECTOR(8 downto 0);
        -- memory: file is loaded to it
        variable memory   : ram_type;
    begin
        -- for every aviable memory cell
        for i in 0 to RAM_SIZE-1 loop
            -- exit earlier when end of file is reached
            exit when endfile(opened_file);

            -- read line from file to line_var
            readline(opened_file, line_var);

            -- for every index in line_var (1 to 9)
            -- word is indexed 8 downto 0
            for k in 1 to 9 loop
                case line_var(k) is
                    -- copy line to std_logic_vector word
                    when '0' => word(9-k) := '0';
                    when others => word(9-k) := '1';
                end case;
            end loop;

            -- set memory cell to decoded word
            memory(i) := word;
        end loop;

        -- return written memory
        return memory;
    end read_file;

    -- memory: ram_type storing data
    signal memory : ram_type := read_file(filename);

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
                memory(to_integer(unsigned(mar_reg_in))) <= q;
                next_s <= IDLE;
            when WRITE_BUS =>
                vstate <= "10";
                -- convert mar_reg_in value to integer index of memory
                -- and set value under that index to output
                result_reg <= memory(to_integer(unsigned(mar_reg_in)));
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
