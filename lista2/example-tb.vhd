LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
 
 
ENTITY example_tb IS
END example_tb;
 
ARCHITECTURE behavior OF example_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT example
    PORT(
         a : IN  std_logic;
         b : IN  std_logic;
         c : IN  std_logic;
         x : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic := '0';
   signal b : std_logic := '0';
   signal c : std_logic := '0';
	
	signal abc : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal x : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   -- for display clarity only
   constant period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: example PORT MAP (
          a => a,
          b => b,
          c => c,
          x => x
        );

   -- Clock process definitions
	-- don't need that
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for period*10;

		-- silly way to test all states... 
      a <= '0';
		b <= '0';
		c <= '1';
		wait for period;
		
      a <= '0';
		b <= '1';
		c <= '0';
		wait for period;

      a <= '0';
		b <= '1';
		c <= '1';
		wait for period;

      a <= '1';
		b <= '0';
		c <= '0';
		wait for period;

      a <= '1';
		b <= '0';
		c <= '1';
		wait for period;

      a <= '1';
		b <= '1';
		c <= '0';
		wait for period;

      a <= '1';
		b <= '1';
		c <= '1';

		wait for 10*period;
		
		-- another way to do this... 
		for i in 0 to 6 loop
		  abc <= std_logic_vector( unsigned(abc) + 1);
		  a <= abc(2);
		  b <= abc(1);
		  c <= abc(0);
		  wait for period;
		end loop;



      wait;
   end process;

END;
