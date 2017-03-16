library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_unsigned.all; 
use ieee.numeric_std;


entity zad5 is
	generic(width	: integer:=8);
	port(	s		: in std_logic;
			A,B		: in std_logic_vector(width-1 downto 0);
			X			: out std_logic_vector(width-1 downto 0)
			);
end zad5;

architecture Behavioral of zad5 is
begin
	X <= B when (s='1') else A;
end Behavioral;