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
type cmd_type is (NOP, ADD, ID, CRC, DATA_REQ);
attribute enum_encoding: string;
attribute enum_encoding of cmd_type: type is
				"0000 0001 0010 0011 1111";
signal current_cmd : cmd_type := NOP;

-- input buffer
signal q : std_logic_vector (7 downto 0) := (others => '0');

-- for storing results and indicating it is to be sent to bus
signal result_reg : std_logic_vector (7 downto 0) := (others => '0');
signal sending : std_logic := '0';



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
			when "0100" => current_cmd <= DATA_REQ;
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
					  "0100" when DATA_REQ,
					  "0000" when others;


end Behavioral;

