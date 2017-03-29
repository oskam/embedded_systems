
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity statemachine2 is
    port(
        clk    : in std_logic;
        pusher : in std_logic;
        rst    : in std_logic;
        driver : out std_logic
    );

end statemachine2;

architecture Flow of statemachine2 is
    type stan is (A, B, C, D);
    signal stan_teraz : stan := A;
    signal stan_potem : stan := A;
begin

state_advance: process(clk, rst)
begin
    if rst = '1' then
        stan_teraz <= A;
    elsif rising_edge(clk) then
        stan_teraz <= stan_potem;
    end if;
end process;

next_state: process(stan_teraz)
begin
    stan_potem <= stan_teraz;
    case stan_teraz is
        when A =>
            if pusher = '1'then
                stan_potem <= B;
            end if; 
        driver <= '0';
        when B =>
            if pusher = '1'then
                stan_potem <= C;
            end if; 
        driver <= '0';
        when C =>
            if pusher = '1'then
                stan_potem <= D;
            end if; 
        driver <= '0';
        when D =>
            if pusher = '1'then
                stan_potem <= B;
            else 
                stan_potem <= A;
            end if;            
        driver <= '1';
    end case;
end process;

end Flow;
