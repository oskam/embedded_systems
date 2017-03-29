LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- include also the local library for 'str' call
USE work.txt_util.ALL;


ENTITY statemachine_tb IS
END statemachine_tb;

ARCHITECTURE behavior OF statemachine_tb IS
    COMPONENT statemachine
    PORT(
        clk    : IN  std_logic;
        pusher : IN  std_logic;
        rst    : IN  std_logic;
        driver : OUT  std_logic_vector(1 downto 0)
        );
    END COMPONENT;


    --Inputs
    signal clk    : std_logic := '0';
    signal pusher : std_logic := '0';
    signal rst    : std_logic := '0';

    --Outputs
    signal driver : std_logic_vector(1 downto 0);

    -- Clock period definitions
    constant clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: statemachine PORT MAP (
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

        wait for clk_period*10;
		pusher <= '1';				   -- allow state transitions now
		wait for clk_period * 2;	-- let some states transit to some other...

		assert driver = "10"			-- test what we've got
            report "expected state '10' on driver not achieved -- got '" & str(driver) & "'";

		wait for clk_period;
		pusher <= '0';					-- disable state transitions
		wait for clk_period * 2;


		assert driver = "11"
			report "expected state '11' on driver not achieved -- got '" & str(driver) & "'";

        rst <= '1';                     -- reset statemachine to S0
        wait for 1 ns;                  -- let signal change

        assert driver = "00"            -- test if it's reset
			report "expected state '00' on driver not achieved -- got '" & str(driver) & "'";

        wait for 100 ns;

        assert driver = "00"            -- test if it's reset again
			report "expected state '00' on driver not achieved -- got '" & str(driver) & "'";

        wait;
    end process;

END;
