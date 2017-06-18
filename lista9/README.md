# MARIE vhdl simulation

## MARIE instruction set

> We mentioned previously that each instruction for MARIE consists of 16
bits. The most significant 4 bits, bits 12 through 15, make up the opcode that
specifies the instruction to be executed (which allows for a total of 16 instructions).
The least significant 12 bits, bits 0 through 11, form an address, which
allows for a maximum memory address of 2^(12)–1.

Implemented MARIE processor uses __9 bit words/instructions__. Most significant 4 bits, bits 8-5, make up the __opcode__, other 5 bits, bits 4-0, make up __address__, which allows memory with 32 __cells addressed from 0 to 31__.

### MARIE instructions

hex | bin    | instruction | meaning
--: | :--:   | :--:        | --
  1 | `0001` | Load X      | `ram[X]` → `AC`
  2 | `0010` | Store X     | `AC` → `ram[X]`
  3 | `0011` | Add X       | `ram[X] + AC` → `AC`
  4 | `0100` | Subt X      | `AC - ram[X]` → `AC`
  5 | `0101` | Input       | stdin → `AC`
  6 | `0110` | Output      | `AC` → stdout
  7 | `0111` | Halt        | terminate the program
  8 | `1000` | Skipcond    | `IF cond: PC+=1`
  9 | `1001` | Jump X      | `X → PC`

## Components' IDs

IDs of components are __opcodes__ activating component to do what __address__ codes them to do.

RAM, PC and registers operate in __READ_BUS__ (jump for PC) and __WRITE_BUS__ modes, activated by first bit of __address__:

- `0` for __WRITE_BUS__,
- `1` for __READ_BUS__.

### IDs of components

name | ID
:--: | :--
RAM  | `1010`
PC   | `1011`
REGISTERS | `1100`
ALU  | `1101`

> e.g. to activate RAM in READ_BUS mode bus should be set to `1010 1 ????`, where `?` are either `0` or `1`.

### Registers

When __opcode__ `1100` activates registers, and most significant bit of __address__ selects mode of register, there are 6 registers in MARIE, to choose which one should be used next 3 bits of __address__ are used.

register | activator
:--:     | :--
IR       | `000`
MAR      | `001`
MBR      | `010`
AC       | `011`
IN       | `100`
OUT      | `101`

> e.g. to activate MAR register in READ_BUS mode bus should be set to `1100 1 001 ?`, where `?` is either `0` or `1`.

### ALU modes

ALU is an unit responsible for addition (Add X), subtractions (Subt X) and comparison (Skipcond). AC and MBR register have to be set when ALU is activated.

3 bits of address (bit 4 to 2 of instruction) are used to choose mode, codes are:

- `111` for addition,
- `000` for subtraction,
- `100` for comparison `AC > 0`,
- `010` for comparison `AC = 0`,
- `001` for comparison `AC < 0`.

> e.g. to activate ALU in addition mode bus should be set to `1101 01 ???`, where `?` are either `0` or `1`.

When comparison yields _true_ ALU signal `comparison_signal` connected to CU is set to `1`.

Addition and Subtraction results are send to bus on second cycle after activation, giving time for CU to let know AC to store that value.

## Numbers

As __opcodes__ for MARIE instructions are only decoded in given (known) moments by Control Unit, bus has only to be guarded from writing Components IDs when one should not be activated.

All IDs begin with `1`, therefore positive and negative numbers are coded by first 2 bits, that leaves __7 bits__ for value.

1. Positive numbers start with `00`.
2. Negative numbers start with `01`.
3. 7 bits allow storing and using integer numbers in range __[-127, 127]__.
4. Addition giving result __greater__ than 127 is reduced to 127.
4. Subtraction giving result __lesser__ than -127 is reduced to -127.

> e.g.
- 26 = `00 0011010`,
- -13 = `01 0001101`
