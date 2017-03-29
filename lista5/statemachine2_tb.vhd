LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- include also the local library for 'str' call
USE work.txt_util.ALL;


ENTITY statemachine2_tb IS
END statemachine2_tb;

ARCHITECTURE behavior OF statemachine2_tb IS
    COMPONENT statemachine2
    PORT(
        clk    : IN  std_logic;
        pusher : IN  std_logic;
        rst    : IN  std_logic;
        driver : OUT  std_logic
        );
    END COMPONENT;


    --Inputs
    signal clk    : std_logic := '0';
    signal pusher : std_logic := '0';
    signal rst    : std_logic := '0';

    --Outputs
    signal driver : std_logic;

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: statemachine2 PORT MAP (
            clk    => clk,
            pusher => pusher,
            rst    => rst,
            driver => driver
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

        assert driver = '0' --A
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

		pusher <= '0';				   -- allow state transitions now
		wait for clk_period * 2;	-- let some states transit to some other...

        assert driver = '0' --A
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

		pusher <= '1';					-- disable state transitions
		wait for clk_period * 5;
        
        assert driver = '0' --C
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

        pusher <= '0';
        wait for clk_period * 5;

        assert driver = '0' --C
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

        pusher <= '1';
        wait for clk_period * 2;

        assert driver = '0' --B
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

        rst <= '1';                     
        wait for clk_period * 2;                  

        assert driver = '0' --A
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

        rst <= '0';                     
        wait for clk_period * 5; 

        assert driver = '0' --C
		report "expected state '0' on driver not achieved -- got '" & str(driver) & "'";

        pusher <= '0';

        wait;
    end process;

END;
