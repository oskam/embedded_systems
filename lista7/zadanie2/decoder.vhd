
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY decoder IS
	PORT(
	    data_out: out std_logic_vector(3 downto 0) := (others => '0');
	    data_in: in std_logic_vector(6 downto 0) := (others => '0');
	    error_out: out std_logic_vector(2 downto 0) := (others => '0')
  	);
END decoder;

ARCHITECTURE Behavioral OF decoder IS
	signal checker : std_logic_vector(2 downto 0);
BEGIN
	PROCESS(data_in)
	BEGIN
		checker(0) <= data_in(6) xor data_in(4) xor data_in(2) xor data_in(0);
		checker(1) <= data_in(6) xor data_in(5) xor data_in(2) xor data_in(1);
		checker(2) <= data_in(6) xor data_in(5) xor data_in(4) xor data_in(3);

		error_out <= "000";

		if checker = "011" then 
		data_out(0) <= not data_in(2);
		error_out <= checker;
		else data_out(0) <= data_in(2);
		end if;

		if checker = "101" then 
		data_out(1) <= not data_in(4);
		error_out <= checker;
		else data_out(1) <= data_in(4);
		end if;

		if checker = "110" then 
		data_out(2) <= not data_in(5);
		error_out <= checker;
		else data_out(2) <= data_in(5);
		end if;

		if checker = "111" then 
		data_out(3) <= not data_in(6);
		error_out <= checker;
		else data_out(3) <= data_in(6);
		end if;
	END PROCESS;
END;