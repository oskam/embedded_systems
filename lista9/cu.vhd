library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use std.textio.all;

entity cu is
    port(
        -- conn_bus: shared BUS
        conn_bus       : inout std_logic_vector (8 downto 0);
        -- alu_cmp_signal: input signal from alu for comparison result
        alu_cmp_signal : in std_logic := '0';
        -- clk: system clock for synchronization
        clk            : in std_logic
    );
end cu;

architecture behavior of cu is

    component pc is
        generic(
            ID    : std_logic_vector (3 downto 0)
        );
        port(
            conn_bus : inout std_logic_vector(8 downto 0);
            inc_s    : in std_logic;
            clk      : in std_logic
        );
    end component;

    component reg is
        generic(
            ID       : std_logic_vector (3 downto 0);
            REG_ID   : std_logic_vector (2 downto 0);
            REG_SIZE : integer
        );
        port(
            conn_bus : inout std_logic_vector(8 downto 0);
            out_reg  : out std_logic_vector(REG_SIZE-1 downto 0);
            clk      : in std_logic
        );
    end component reg;

    -- program counter increment signal
    signal inc_pc_signal : std_logic := '0';

    -- statemachine definitions
    type state_type is (
        IDLE,                   -- do nothing

        FETCH_GET_PC,           -- activate PC in WRITE_BUS_MODE
        FETCH_SET_MAR,          -- activate MAR in READ_BUS_MODE
        FETCH_LINE_ADDRESS,     -- PC -> MAR
        FETCH_GET_RAM,          -- activate RAM in WRITE_BUS_MODE
        FETCH_SET_IR,           -- activate IR in READ_BUS_MODE
        FETCH_LOAD_INSTRUCTION, -- RAM[MAR] -> IR

        DECODE_GET_IR,          -- activate IR in WRITE_BUS_MODE
        DECODE_SET_MAR,         -- activate MAR in READ_BUS_MODE
        DECODE_SAVE_ADDRESS,    -- IR(4 downto 0) -> MAR
        DECODE_INSTRUCTION,     -- decode opcode and address from IR, prepare instruction execution
        -- LOAD:                activate RAM in WRITE_BUS_MODE
        -- STORE:               activate AC in WRITE_BUS_MODE
        -- ADD:                 activate RAM in WRITE_BUS_MODE
        -- SUBT:                activate RAM in WRITE_BUS_MODE
        -- INPUT:               wait for input, save it in variable and activate IN in READ_BUS_MODE
        -- OUTPUT:              activate AC in WRITE_BUS_MODE
        -- SKIPCOND:            decode condition and activate ALU in proper comparison mode
        -- JUMP:                activate MAR in WRITE_BUS_MODE
        -- HALt:                stop execution

        EXECUTE_LOAD_1,         -- activate MBR in READ_BUS_MODE
        EXECUTE_LOAD_2,         -- RAM[MAR] -> MBR
        EXECUTE_LOAD_3,         -- activate MBR in WRITE_BUS_MODE
        EXECUTE_LOAD_4,         -- activate AC in READ_BUS_MODE
                                -- in IDLE: MBR -> AC
        EXECUTE_STORE_1,        -- activate MBR in READ_BUS_MODE
        EXECUTE_STORE_2,        -- AC -> MBR
        EXECUTE_STORE_3,        -- activate MBR in WRITE_BUS_MODE
        EXECUTE_STORE_4,        -- activate RAM in READ_BUS_MODE
                                -- in IDLE: MBR -> RAM[MAR]
        EXECUTE_ADD_1,          -- activate MBR in READ_BUS_MODE
        EXECUTE_ADD_2,          -- RAM[MAR] -> MBR
        EXECUTE_ADD_3,          -- activate ALU inv ALU_ADD_MODE
        EXECUTE_ADD_4,          -- activate AC in READ_BUS_MODE
                                -- in IDLE: AC + MBR -> AC
        EXECUTE_SUBT_1,         -- activate MBR in READ_BUS_MODE
        EXECUTE_SUBT_2,         -- RAM[MAR] -> MBR
        EXECUTE_SUBT_3,         -- activate ALU inv ALU_SUBT_MODE
        EXECUTE_SUBT_4,         -- activate AC in READ_BUS_MODE
                                -- in IDLE: AC - MBR -> AC
        EXECUTE_INPUT_1,        -- write input number to BUS, number -> IN
        EXECUTE_INPUT_2,        -- activate IN in WRITE_BUS_MODE
        EXECUTE_INPUT_3,        -- activate AC in READ_BUS_MODE
                                -- in IDLE: IN -> AC
        EXECUTE_OUTPUT,         -- activate OUT in READ_BUS_MODE
                                -- in IDLE: AC -> OUT
        EXECUTE_SKIP_LT_1,      -- wait for ALU to compare AC < 0
        EXECUTE_SKIP_GT_1,      -- wait for ALU to compare AC > 0
        EXECUTE_SKIP_EQ_1,      -- wait for ALU to compare AC = 0
        EXECUTE_SKIP_LT_2,      -- increase PC if ALU yielded true
        EXECUTE_SKIP_GT_2,      -- increase PC if ALU yielded true
        EXECUTE_SKIP_EQ_2,      -- increase PC if ALU yielded true
        EXECUTE_JUMP            -- activate PC in READ_BUS_MODE
                                -- in IDLE: MAR -> PC
    );
    signal current_s : state_type := IDLE;
    signal next_s    : state_type := IDLE;

    -- input buffer
    signal q         : std_logic_vector (8 downto 0) := (others => 'Z');

    -- for storing results and indicating it is to be sent to bus
    signal result_reg : std_logic_vector (8 downto 0) := (others => '0');
    signal sending   : std_logic := '0';

    -- instructions
    constant LOAD_OPCODE     : std_logic_vector(3 downto 0) := "0001";
    constant STORE_OPCODE    : std_logic_vector(3 downto 0) := "0010";
    constant ADD_OPCODE      : std_logic_vector(3 downto 0) := "0011";
    constant SUBT_OPCODE     : std_logic_vector(3 downto 0) := "0100";
    constant INPUT_OPCODE    : std_logic_vector(3 downto 0) := "0101";
    constant OUTPUT_OPCODE   : std_logic_vector(3 downto 0) := "0110";
    constant HALT_OPCODE     : std_logic_vector(3 downto 0) := "0111";
    constant SKIPCOND_OPCODE : std_logic_vector(3 downto 0) := "1000";
    constant JUMP_OPCODE     : std_logic_vector(3 downto 0) := "1001";

    -- components IDs
    constant RAM_ID : std_logic_vector(3 downto 0) := "1010";
    constant PC_ID  : std_logic_vector(3 downto 0) := "1011";
    constant REG_ID : std_logic_vector(3 downto 0) := "1100";
    constant ALU_ID : std_logic_vector(3 downto 0) := "1101";

    -- modes
    constant READ_BUS_MODE  : std_logic := '1';
    constant WRITE_BUS_MODE : std_logic := '0';

    -- registers IDs
    constant IR_REG_ID  : std_logic_vector(2 downto 0) := "000";
    constant MAR_REG_ID : std_logic_vector(2 downto 0) := "001";
    constant MBR_REG_ID : std_logic_vector(2 downto 0) := "010";
    constant AC_REG_ID  : std_logic_vector(2 downto 0) := "011";
    constant IN_REG_ID  : std_logic_vector(2 downto 0) := "100";
    constant OUT_REG_ID : std_logic_vector(2 downto 0) := "101";

    -- ALU modes
    constant ALU_ADD_MODE      : std_logic_vector(2 downto 0) := "111";
    constant ALU_SUBT_MODE     : std_logic_vector(2 downto 0) := "000";
    constant ALU_COMP_LT_MODE  : std_logic_vector(2 downto 0) := "001";
    constant ALU_COMP_EQ_MODE  : std_logic_vector(2 downto 0) := "010";
    constant ALU_COMP_GT_MODE  : std_logic_vector(2 downto 0) := "100";

    -- numbers
    constant POSITIVE_NUM : std_logic_vector(1 downto 0) := "00";
    constant NEGATIVE_NUM : std_logic_vector(1 downto 0) := "01";

    -- local
    shared variable opcode : std_logic_vector(3 downto 0) := (others => 'Z');
    shared variable address : std_logic_vector(4 downto 0) := (others => 'Z');

begin

    -- cu have two registers internally:

    -- program_counter stores line number to read from memory in FETCH phase
    program_counter : pc
	GENERIC MAP (
        ID    => PC_ID
    )
	PORT MAP (
        conn_bus => conn_bus,
        inc_s    => inc_pc_signal,
        clk      => clk
    );

    -- instruction_register stores instruction read from memory
    instruction_register : reg
	GENERIC MAP (
        ID       => REG_ID,
        REG_ID   => IR_REG_ID,
        REG_SIZE => 9
    )
	PORT MAP (
        conn_bus => conn_bus,
        clk      => clk
    );

    clock: process(clk)
    begin
        if rising_edge(clk)
        then
            q  <= conn_bus;
            current_s <= next_s;
        end if;
    end process;

    next_state: process(current_s, q)
        variable line_var   : line;
        variable string_var : string(1 to 9);
        variable number     : integer;
    begin
        sending <= '1'; -- default mode is send
        inc_pc_signal <= '0';
        case current_s is
            when IDLE =>
                sending <= '0';
                next_s <= FETCH_GET_PC;

            when FETCH_GET_PC =>
                result_reg <= PC_ID & WRITE_BUS_MODE & "0000";
                next_s <= FETCH_SET_MAR;

            when FETCH_SET_MAR =>
                result_reg <= REG_ID & READ_BUS_MODE & MAR_REG_ID & '0';
                next_s <= FETCH_LINE_ADDRESS;

            when FETCH_LINE_ADDRESS =>
                sending <= '0';
                next_s <= FETCH_GET_RAM;

            when FETCH_GET_RAM =>
                result_reg <= RAM_ID & WRITE_BUS_MODE & "0000";
                next_s <= FETCH_SET_IR;

            when FETCH_SET_IR =>
                result_reg <= REG_ID & READ_BUS_MODE & IR_REG_ID & '0';
                inc_pc_signal <= '1';
                next_s <= FETCH_LOAD_INSTRUCTION;

            when FETCH_LOAD_INSTRUCTION =>
                sending <= '0';
                next_s <= DECODE_GET_IR;

            when DECODE_GET_IR =>
                result_reg <= REG_ID & WRITE_BUS_MODE & IR_REG_ID & '0';
                next_s <= DECODE_SET_MAR;

            when DECODE_SET_MAR =>
                result_reg <= REG_ID & READ_BUS_MODE & MAR_REG_ID & '0';
                next_s <= DECODE_SAVE_ADDRESS;

            when DECODE_SAVE_ADDRESS =>
                sending <= '0';
                next_s <= DECODE_INSTRUCTION;

            when DECODE_INSTRUCTION =>
                opcode := q(8 downto 5);
                address := q(4 downto 0);

                case opcode is
                    when LOAD_OPCODE =>
                        result_reg <= RAM_ID & WRITE_BUS_MODE & "0000";
                        next_s <= EXECUTE_LOAD_1;

                    when STORE_OPCODE =>
                        result_reg <= REG_ID & WRITE_BUS_MODE & AC_REG_ID & '0';
                        next_s <= EXECUTE_STORE_1;

                    when ADD_OPCODE =>
                        result_reg <= RAM_ID & WRITE_BUS_MODE & "0000";
                        next_s <= EXECUTE_ADD_1;

                    when SUBT_OPCODE =>
                        result_reg <= RAM_ID & WRITE_BUS_MODE & "0000";
                        next_s <= EXECUTE_SUBT_1;

                    when INPUT_OPCODE =>
                        write (line_var, string'("input number in [-127, 127]:"));
                        writeline (output, line_var);
                        readline (input, line_var);
                        read (line_var, number);

                        assert number >= -127
                        report "number reduced to -127"
                        severity warning;
                        if number < -127
                        then
                            number := -127;
                        end if;

                        assert number <= 127
                        report "number reduced to 127"
                        severity warning;
                        if number > 127
                        then
                            number := 127;
                        end if;

                        result_reg <= REG_ID & READ_BUS_MODE & IN_REG_ID & '0';
                        next_s <= EXECUTE_INPUT_1;

                    when OUTPUT_OPCODE =>
                        result_reg <= REG_ID & WRITE_BUS_MODE & AC_REG_ID & '0';
                        next_s <= EXECUTE_OUTPUT;

                    when SKIPCOND_OPCODE =>
                        case q(4 downto 3) is
                            when "00" => -- AC < 0
                                result_reg <= ALU_ID & ALU_COMP_LT_MODE & "00";
                                next_s <= EXECUTE_SKIP_LT_1;
                            when "01" => -- AC = 0
                                result_reg <= ALU_ID & ALU_COMP_EQ_MODE & "00";
                                next_s <= EXECUTE_SKIP_EQ_1;
                            when "10" => -- AC > 0
                                result_reg <= ALU_ID & ALU_COMP_GT_MODE & "00";
                                next_s <= EXECUTE_SKIP_GT_1;
                            when others =>
                                report "unrecognized skipcond"
                                severity failure;
                        end case;

                    when JUMP_OPCODE =>
                        result_reg <= REG_ID & WRITE_BUS_MODE & MAR_REG_ID & '0';
                        next_s <= EXECUTE_JUMP;

                    when HALT_OPCODE =>
                        report "halt instruction, exiting"
                        severity failure;

                    when others =>
                		report "unrecognized opcode"
                		severity failure;
                end case;

            when EXECUTE_LOAD_1 =>
                result_reg <= REG_ID & READ_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_LOAD_2;

            when EXECUTE_LOAD_2 =>
                sending <= '0';
                next_s <= EXECUTE_LOAD_3;

            when EXECUTE_LOAD_3 =>
                result_reg <= REG_ID & WRITE_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_LOAD_4;

            when EXECUTE_LOAD_4 =>
                result_reg <= REG_ID & READ_BUS_MODE & AC_REG_ID & '0';
                next_s <= IDLE;

            when EXECUTE_STORE_1 =>
                result_reg <= REG_ID & READ_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_STORE_2;

            when EXECUTE_STORE_2 =>
                sending <= '0';
                next_s <= EXECUTE_STORE_3;

            when EXECUTE_STORE_3 =>
                result_reg <= REG_ID & WRITE_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_STORE_4;

            when EXECUTE_STORE_4 =>
                result_reg <= RAM_ID & READ_BUS_MODE & "0000";
                next_s <= IDLE;

            when EXECUTE_ADD_1 =>
                result_reg <= REG_ID & READ_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_ADD_2;

            when EXECUTE_ADD_2 =>
                sending <= '0';
                next_s <= EXECUTE_ADD_3;

            when EXECUTE_ADD_3 =>
                result_reg <= ALU_ID & ALU_ADD_MODE & "00";
                next_s <= EXECUTE_ADD_4;

            when EXECUTE_ADD_4 =>
                result_reg <= REG_ID & READ_BUS_MODE & AC_REG_ID & '0';
                next_s <= IDLE;

            when EXECUTE_SUBT_1 =>
                result_reg <= REG_ID & READ_BUS_MODE & MBR_REG_ID & '0';
                next_s <= EXECUTE_SUBT_2;

            when EXECUTE_SUBT_2 =>
                sending <= '0';
                next_s <= EXECUTE_SUBT_3;

            when EXECUTE_SUBT_3 =>
                result_reg <= ALU_ID & ALU_SUBT_MODE & "00";
                next_s <= EXECUTE_SUBT_4;

            when EXECUTE_SUBT_4 =>
                result_reg <= REG_ID & READ_BUS_MODE & AC_REG_ID & '0';
                next_s <= IDLE;

            when EXECUTE_INPUT_1 =>
                if number < 0
                then
                    number := -1 * number;
                    result_reg <= "01" & std_logic_vector(to_unsigned(number, 7));
                else
                    result_reg <= "00" & std_logic_vector(to_unsigned(number, 7));
                end if;
                next_s <= EXECUTE_INPUT_2;

            when EXECUTE_INPUT_2 =>
                result_reg <= REG_ID & WRITE_BUS_MODE & IN_REG_ID & '0';
                next_s <= EXECUTE_INPUT_3;

            when EXECUTE_INPUT_3 =>
                result_reg <= REG_ID & READ_BUS_MODE & AC_REG_ID & '0';
                next_s <= IDLE;

            when EXECUTE_OUTPUT =>
                result_reg <= REG_ID & READ_BUS_MODE & OUT_REG_ID & '0';
                next_s <= IDLE;

            when EXECUTE_SKIP_LT_1 =>
                sending <= '0';
                next_s <= EXECUTE_SKIP_LT_2;

            when EXECUTE_SKIP_GT_1 =>
                sending <= '0';
                next_s <= EXECUTE_SKIP_GT_2;

            when EXECUTE_SKIP_EQ_1 =>
                sending<= '0';
                next_s <= EXECUTE_SKIP_GT_2;

            when EXECUTE_SKIP_LT_2 =>
                if alu_cmp_signal = '1'
                then
                    inc_pc_signal <= '1';
                end if;
                sending <= '0';
                next_s <= IDLE;

            when EXECUTE_SKIP_GT_2 =>
                if alu_cmp_signal = '1'
                then
                    inc_pc_signal <= '1';
                end if;
                sending <= '0';
                next_s <= IDLE;

            when EXECUTE_SKIP_EQ_2 =>
                if alu_cmp_signal = '1'
                then
                    inc_pc_signal <= '1';
                end if;
                sending <= '0';
                next_s <= IDLE;

            when EXECUTE_JUMP =>
                result_reg <= PC_ID & READ_BUS_MODE & "0000";
                next_s <= IDLE;

            when others =>
                sending <= '0';
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
        wait until falling_edge(clk);
    end process;

end behavior;
