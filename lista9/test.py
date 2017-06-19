# print powers of 2 lower than x

x = input()
z = 0
y = 1

if x > 0:
	print(z)
else:
	exit()

while y < x:	# AC = z - x; AC < 0
	print(y)
	y += y

exit()

#1 input
#2 store (ostatni indeks)
#3 skipcond 00
#4 jump if
#5 jump else
#6 if: load adr 0
#7 output
#8 jump next
#9 else: halt
#10 next:
# 0
# 1