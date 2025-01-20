# Logic Gates

This is a collection of bitwise logic gates implemented with only the LDM and STM instructions. Because I'm not sure exactly how they'll be used, most gates have multiple variants. True/false and 1/0 are defined as the following
| Value   | Instruction           | Internal Value |
|---------|-----------------------|----------------|
| 1/true  | `ldmda r15, {c, r15}` | 0xE81F8400     |
| 0/false | `ldmib r15, {c, r15}` | 0xE99F8400     |
