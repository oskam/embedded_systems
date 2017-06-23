LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE IEEE.std_logic_unsigned.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY slave_tb IS
END slave_tb;
 
ARCHITECTURE behavior OF slave_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT slave
		generic ( identifier : std_logic_vector (7 downto 0) );
    PORT(
        conn_bus : INOUT  std_logic_vector(7 downto 0);
        clk : IN  std_logic;
		state : out STD_LOGIC_VECTOR (5 downto 0);
		vq : out std_logic_vector (7 downto 0);
		vcurrent_cmd : out std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';

	--BiDirs
   signal conn_bus : std_logic_vector(7 downto 0) := (others => 'Z');
	
	
	-- outputs from UUT for debugging
	signal state : std_logic_vector(5 downto 0);
	signal vq : std_logic_vector (7 downto 0);
	signal current_cmd : std_logic_vector (3 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: slave 
	GENERIC MAP (identifier => "10101010")
	PORT MAP (
          conn_bus => conn_bus,
          clk => clk,
			 state => state,
			 vq => vq,
			 vcurrent_cmd => current_cmd
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
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

		-- address
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: id
		conn_bus <= "00100000";
		wait for clk_period*2;
		-- address
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "01000000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";

		-- other possible execution
		wait for 3*clk_period;
		-- address
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: add
		conn_bus <= "00010000";
		wait for clk_period;
		-- add operands
		conn_bus <= "00001111";
		wait for 3*clk_period;
		
		
		
      wait;
   end process;

END;
