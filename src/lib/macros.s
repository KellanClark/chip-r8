; Register Aliases
tmp equ r0
tmp! equ r0!
tmp0 equ r0
tmp0! equ r0!
tmp1 equ r1
tmp1! equ r1!
tmp2 equ r2
tmp2! equ r2!
tmp3 equ r3
tmp3! equ r3!
tmp4 equ r4
tmp4! equ r4!
tmp5 equ r5
tmp5! equ r5!
tmp6 equ r6
tmp6! equ r6!
tmp7 equ r7
tmp7! equ r7!
a equ r8
a! equ r8!
b equ r9
b! equ r9!
c equ r10
c! equ r10!
d equ r11
d! equ r11!
ptr1 equ r11
ptr1! equ r11!
e equ r12
e! equ r12!
ptr2 equ r12
ptr2! equ r12!
f equ r14
f! equ r14!
ptr3 equ r14
ptr3! equ r14!

true equ 0xE81F8400 ; ldmda r15, {c, r15}
false equ 0xE99F8400 ; ldmib r15, {c, r15}

; nop using ldm
macro nopl {
	dw 0x08900001  ; ldmeqia tmp, {tmp}
}

; Copies a value from one register to another
macro move dest, src {
	push {src\}
	pop {dest\}
}

macro jump address {
	ldmdb r15, {r15\}
	dw address
}

; Infinite loop
macro halt {
	ldmdb r15, {r15\}
	dw $ - 4
}

; Calls a subroutine
macro call address {
	stmdb sp!, {r15\}
	ldmdb r15, {r15\}
	dw address
}

macro callr reg {
	stmdb sp!, {r15\} ; Push return address onto the stack
	ldmia reg, {r15\} ; Jump to the handler
	nopl ; Unused because stm stores PC+12
}

; Returns from a subroutine
macro ret {
	ldmia sp!, {r15\}
}

; Sets b to any value. Meant to be used with bin_to_ofs functions. Can't be generalized for other registers without wasting a word
macro load_base value {
	dw 0xE81F8200 ; ldmda r15, {b, r15}
	dw value
	dw $ + 4
}

; Hex number printing code from fasm manual
macro display_hex value, bits {
	repeat bits/4
		digit = '0' + value shr (bits-%*4) and 0Fh
		if digit > '9'
			digit = digit + 'A'-'9'-1
		end if
		display digit
	end repeat
}

macro display_newline {
	display $d, $a
}
