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
    signal n_clk : std_logic := '1';

    --BiDirs
    signal conn_bus : std_logic_vector(7 downto 0) := (others => 'Z');


    -- outputs from UUT for debugging
    signal state : std_logic_vector(5 downto 0);
    signal vq : std_logic_vector (7 downto 0);
    signal current_cmd : std_logic_vector (3 downto 0);

    -- outputs from UUT for debugging
    signal state2 : std_logic_vector(5 downto 0);
    signal vq2 : std_logic_vector (7 downto 0);
    signal current_cmd2 : std_logic_vector (3 downto 0);

    -- outputs from UUT for debugging
    signal state3 : std_logic_vector(5 downto 0);
    signal vq3 : std_logic_vector (7 downto 0);
    signal current_cmd3 : std_logic_vector (3 downto 0);

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

    uut2: slave
	GENERIC MAP (identifier => "01010101")
	PORT MAP (
        conn_bus => conn_bus,
        clk => clk,
        state => state2,
        vq => vq2,
        vcurrent_cmd => current_cmd2
    );

    uut3: slave
	GENERIC MAP (identifier => "11001100")
	PORT MAP (
        conn_bus => conn_bus,
        clk => n_clk,
        state => state3,
        vq => vq3,
        vcurrent_cmd => current_cmd3
    );

    -- Clock process definitions
    clk_process :process
    begin
    	clk <= '0';
        n_clk <= '1';
    	wait for clk_period/2;
    	clk <= '1';
    	n_clk <= '0';
    	wait for clk_period/2;
    end process;


    -- Stimulus process
    stim_proc: process
    begin
        -- hold reset state for 100 ns.
        wait for 100 ns;

        -- ID AND DATA REQUEST

		-- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: id
		conn_bus <= "00100000";
		wait for clk_period*2;
		-- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = "10101010" report "bad ID1";
        wait for clk_period;

        -- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: id
		conn_bus <= "00100000";
		wait for clk_period*2;
		-- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = "01010101" report "bad ID2";
        wait for clk_period;

        -- address3
		conn_bus <= "11001100";
		wait for clk_period;
		-- CMD: id
		conn_bus <= "00100000";
		wait for clk_period*2;
		-- address3
		conn_bus <= "11001100";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = "11001100" report "bad ID3";
        wait for clk_period;

        -- ADD

		-- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: add
		conn_bus <= "00010000";
		wait for clk_period;
		-- add operands
		conn_bus <= "00000101"; -- 0xAA + 0x05 = 0xAF
		wait for 2*clk_period;
        -- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"AF" report "bad ADD";
        wait for clk_period;

        -- CRC

		-- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: reset
		conn_bus <= "01000000";
		wait for 2*clk_period;

        for I in 0 to 7 loop

            -- address2
    		conn_bus <= "01010101";
    		wait for clk_period;
    		-- CMD: crc
    		conn_bus <= "00110000";
    		wait for clk_period;
            -- operands
            conn_bus <= "01100110";
            -- calc CRC from 0x66
            -- X"35",
        	-- X"be",
        	-- X"06",
        	-- X"27",
        	-- X"c0",
        	-- X"7b",
        	-- X"53",
        	-- X"8b"
            wait for 2*clk_period;

        end loop;

        -- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"8b" report "bad CRC";
        wait for clk_period;

        -- HAMMING ENCODER

        -- address1
        conn_bus <= "10101010";
        wait for clk_period;
        -- CMD: hamming_encoder
        conn_bus <= "01010000";
        wait for clk_period;
        -- operands
        conn_bus <= "00000110"; -- hamming_encoder(0110) = 00110011 = 0x33
        wait for 2*clk_period;
        -- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"33" report "bad HENC";
        wait for clk_period;

        -- HAMMING DECODER

        -- address2
        conn_bus <= "01010101";
        wait for clk_period;
        -- CMD: hamming_decoder
        conn_bus <= "01100000"; -- 01100110 from above with one bit error
        wait for clk_period;
        -- operands
        conn_bus <= "01110011"; -- haming_decoder(1110011) = 0110 = 0x06
        wait for 2*clk_period;
        -- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"06" report "bad HDEC";
        wait for clk_period;

        -- RESET

        -- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: reset
		conn_bus <= "01000000";
		wait for 2*clk_period;
        -- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"00" report "1 not reset";
        wait for clk_period;

        -- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: reset
		conn_bus <= "01000000";
		wait for 2*clk_period;
        -- address2
		conn_bus <= "01010101";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"00" report "2 not reset";
        wait for clk_period;

        -- address3
		conn_bus <= "11001100";
		wait for clk_period;
		-- CMD: reset
		conn_bus <= "01000000";
		wait for 2*clk_period;
        -- address3
		conn_bus <= "11001100";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"00" report "3 not reset";
        wait for clk_period;

        -- HAMMING ENCODER/DECODER without master

        -- address3
        conn_bus <= "11001100";
        wait for clk_period;
        -- CMD: hamming_encoder
        conn_bus <= "01010000";
        wait for clk_period;
        -- operands
        conn_bus <= "00000110"; -- hamming_encoder(0110) = 00110011 = 0x33
        wait for clk_period;

        -- pause for clearance
        conn_bus <= "ZZZZZZZZ";
        wait for clk_period;

        -- address3
		conn_bus <= "11001100";
		wait for clk_period/2;
        -- address1
		conn_bus <= "10101010";
		wait for clk_period/2;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period/2;
        -- CMD: hamming_decoder
        conn_bus <= "01100000"; -- result from above
        wait for clk_period/2;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period*2;

        -- address1
		conn_bus <= "10101010";
		wait for clk_period;
		-- CMD: data_req
		conn_bus <= "11110000";
		wait for clk_period;
		-- this is needed to allow writing on bus by slave
		conn_bus <= "ZZZZZZZZ";
        wait for clk_period;
        assert conn_bus = x"06" report "bad HDEC";
        wait for clk_period;

      wait;
   end process;

END;
