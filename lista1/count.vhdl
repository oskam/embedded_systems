entity count is
  port (i0, i1 : in bit; ci : in bit; s : out bit; co : out bit);
end count;

architecture rtl of count is
	signal x,y: bit;
begin
   x <= i0 and i1;
   y <= i1 or ci;
   s <= x nor y;
   co <= x xor y;
end rtl;