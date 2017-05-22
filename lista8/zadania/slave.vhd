library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;

-----------------------------------------------------------------------
-- a (working) skeleton template for slave device on 8-bit bus
--    capable of executing commands sent on the bus in the sequence:
--    1) device_address (8 bits)
--		2) cmd_opcode (4 bits) & reserved (4 bits)
--		3) (optional) cmd_args (8 bits)
--
-- currently supported commands:
-- 	* ID 			[0010] - get device address
-- 	* DATA_REQ 	[1111] - send current result in the next clockpulse
-- 	* NOP 		[0000] - don't do anything
-----------------------------------------------------------------------
-- debugging information on current state of statemachine and command
-- executed and input buffer register is given in outputs, vstate,
-- vcurrent_cmd and vq, respectively
-----------------------------------------------------------------------

entity slave is
    generic ( identifier : std_logic_vector (7 downto 0) := "10101010" );
    Port ( conn_bus : inout  STD_LOGIC_VECTOR (7 downto 0);
           clk : in  STD_LOGIC;
			  state : out STD_LOGIC_VECTOR (5 downto 0);
			  vq : out std_logic_vector (7 downto 0);
			  vcurrent_cmd : out std_logic_vector(3 downto 0)
			  );
end slave;

architecture Behavioral of slave is

-- statemachine definitions
type state_type is (IDLE, CMD, RUN);
signal current_s : state_type := IDLE;
signal next_s : state_type := IDLE;
-- for debugging entity's state
signal vstate : std_logic_vector(5 downto 0) := (others => '0');

-- command definitions
type cmd_type is (NOP, ADD, ID, CRC, RST, HENC, HDEC, DATA_REQ);
attribute enum_encoding: string;
attribute enum_encoding of cmd_type: type is
				"0000 0001 0010 0011 0100 0101 0110 1111";
signal current_cmd : cmd_type := NOP;

-- input buffer
signal q : std_logic_vector (7 downto 0) := (others => '0');

-- for storing results and indicating it is to be sent to bus
signal result_reg : std_logic_vector (7 downto 0) := (others => '0');
signal sending : std_logic := '0';

function nextCRC (
    data_in		: std_logic_vector(7 downto 0);
    prevCRC 	: std_logic_vector(7 downto 0)
) return std_logic_vector is
    variable D	      : std_logic_vector(7 downto 0);
    variable C	      : std_logic_vector(7 downto 0);
    variable newCRC  : std_logic_vector(7 downto 0);
begin
    D := data_in;
    C := prevCRC;

    newCRC(0) := D(7) xor D(6) xor D(0) xor C(0) xor C(6) xor C(7);
    newCRC(1) := D(6) xor D(1) xor D(0) xor C(0) xor C(1) xor C(6);
    newCRC(2) := D(6) xor D(2) xor D(1) xor D(0) xor C(0) xor C(1)
                            xor C(2) xor C(6);
    newCRC(3) := D(7) xor D(3) xor D(2) xor D(1) xor C(1) xor C(2)
                            xor C(3) xor C(7);
    newCRC(4) := D(4) xor D(3) xor D(2) xor C(2) xor C(3) xor C(4);
    newCRC(5) := D(5) xor D(4) xor D(3) xor C(3) xor C(4) xor C(5);
    newCRC(6) := D(6) xor D(5) xor D(4) xor C(4) xor C(5) xor C(6);
    newCRC(7) := D(7) xor D(6) xor D(5) xor C(5) xor C(6) xor C(7);

    return newCRC;
end nextCRC;

function hamming_encoder (
    data_in : std_logic_vector(3 downto 0)
) return std_logic_vector is
    variable data_out : std_logic_vector(7 downto 0);
begin
    data_out(0) := data_in(0) xor data_in(1) xor data_in(3);
    data_out(1) := data_in(0) xor data_in(2) xor data_in(3);
    data_out(2) := data_in(0);
    data_out(3) := data_in(1) xor data_in(2) xor data_in(3);
    data_out(4) := data_in(1);
    data_out(5) := data_in(2);
    data_out(6) := data_in(3);

    data_out(7) := '0';

    return data_out;
end hamming_encoder;

function hamming_decoder (
    data_in	: std_logic_vector(6 downto 0)
) return std_logic_vector is
    variable data_out : std_logic_vector(7 downto 0);
    variable checker : std_logic_vector(2 downto 0);
begin
    checker(0) := data_in(6) xor data_in(4) xor data_in(2) xor data_in(0);
    checker(1) := data_in(6) xor data_in(5) xor data_in(2) xor data_in(1);
    checker(2) := data_in(6) xor data_in(5) xor data_in(4) xor data_in(3);

    if checker = "011" then
        data_out(0) := not data_in(2);
    else
        data_out(0) := data_in(2);
    end if;

    if checker = "101" then
        data_out(1) := not data_in(4);
    else
        data_out(1) := data_in(4);
    end if;

    if checker = "110" then
        data_out(2) := not data_in(5);
    else
        data_out(2) := data_in(5);
    end if;

    if checker = "111" then
        data_out(3) := not data_in(6);
    else
        data_out(3) := data_in(6);
    end if;

    data_out(7 downto 4) := "0000";

    return data_out;
end hamming_decoder;

begin

stateadvance: process(clk)
begin
  if rising_edge(clk)
  then
    q  <= conn_bus;
    current_s <= next_s;
  end if;
end process;


nextstate: process(current_s,q)
  variable fourbit : std_logic_vector(3 downto 0) := "0000";
begin

 case current_s is
   when IDLE =>
		vstate <= "000001";		-- set for debugging
		if q = identifier and sending /= '1'
		then
	      next_s <= CMD;
		else
			next_s <= IDLE;
		end if;
		sending <= '0';
	when CMD =>
		vstate <= "000010";
		-- command decode
		fourbit := q(7 downto 4);
		case fourbit is
			when "0000" => current_cmd <= NOP;
			when "0001" => current_cmd <= ADD;
			when "0010" => current_cmd <= ID;
			when "0011" => current_cmd <= CRC;
			when "0100" => current_cmd <= RST;
			when "0101" => current_cmd <= HENC;
			when "0110" => current_cmd <= HDEC;
			when "1111" => current_cmd <= DATA_REQ;
			when others => current_cmd <= NOP;
		end case;
		next_s <= RUN;
	when RUN =>
		vstate <= "000100";
		-- determine action based on currend_cmd state
		case current_cmd is
			when NOP
				=> result_reg <= result_reg;
			when ID
				=> result_reg <= identifier;
			when DATA_REQ
				=> sending <= '1';
            when ADD
                => result_reg <=std_logic_vector(unsigned(result_reg) + unsigned(q));
            when CRC
                => result_reg <= nextCRC(q, result_reg);
            when RST
                => result_reg <= "00000000";
            when HENC
                => result_reg <= "00000000";
                result_reg <= hamming_encoder(q(3 downto 0));
            when HDEC
                => result_reg <= "00000000";
                result_reg <= hamming_decoder(q(6 downto 0));
			--
			-- here other commands execution
			--
			when others
				=> result_reg <= result_reg;
		end case;
		next_s <= IDLE;
   when others =>
		vstate <= "111111";
		next_s <= IDLE;
   end case;
end process;


-- tri-state bus
conn_bus <= result_reg when sending = '1' else "ZZZZZZZZ";

-- output debugging signals
state <= vstate;
vq    <= q;
with current_cmd select
    vcurrent_cmd <= "0001" when ADD,
                    "0010" when ID,
                    "0011" when CRC,
                    "1111" when DATA_REQ,
                    "0000" when others;

end Behavioral;
