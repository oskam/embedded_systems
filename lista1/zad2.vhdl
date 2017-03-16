--  Hello world program.
use std.textio.all; -- Imports the standard textio package.

--  Defines a design entity, without any ports.
entity zad2 is
end zad2;

architecture behaviour of zad2 is
begin
   process
      variable l : line;
   begin
      readline(input, l);
      writeline (output, l);
      wait;
   end process;
end behaviour;