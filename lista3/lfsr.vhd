library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity lfsr is
    Port ( clk : in STD_LOGIC;
    	   rst : in STD_LOGIC;
           q : inout  STD_LOGIC_VECTOR(15 downto 0) := "0000000000000001"
			);
end lfsr;

ARCHITECTURE Behavioral OF lfsr IS
BEGIN
  PROCESS(clk, rst)
  BEGIN
  	IF rst = '0' THEN
  		q <= "0000000000000000";
  	ELSIF (rising_edge(clk)) THEN
		q(15 downto 1) <= q(14 downto 0);  --rejestr przesuwny
		q(0) <= q(15) XOR q(14) XOR q(13) XOR q(4);  --sprzezenie
	END IF;
  END PROCESS;
END Behavioral;

