; NAND gate. Opposite of AND gate
; This only has an advantage over AND+NOT with certain input combinations

Base NAND:
	; d = a ? !b : 1
	;
	; 8 words, 12-24 cycles
	; 1 delay slot
2	stmib r15, {a}
2	stmib r15, {b}
2	stmia r15, {b} ; Redundant. Saves a cycle
6	nopl ; Replaced
	dw 0 ; Replaced with b
12	dw bit_not_c
	dw true
	dw common_ret

Inline NAND:
	; d = a ? !b : 1
	;
	; 16 words, 12-24 cycles
	; 1 delay slot
2	stmib r15, {a}
2	stmib r15, {b}
2	stmia r15, {b} ; Redundant. Saves a cycle
6	nopl ; Replaced
	dw 0 ; Replaced with b
	dw $ + 12
	dw true
	dw $ + 36
	; NOT c
2		stmib r15, {c}
2		stmia c, {c}
2		stmia c, {c}
6		nopl ; Replaced
		dw false
		dw $ + 12
		dw true
		dw $ + 4

Harnessed NAND:
	;Inputs:
	; d = ptr to a
	; e = ptr to b
	; f = ptr to out
	;Outputs:
	; a = trashed
	; b = trashed
	; c = trashed
	; d is decremented
	; e is decremented
	; f is decremented
	; result written to *f
	;
	; 18 words, 18-30 cycles
	; 8-bits would be 144 bytes, 144-240 cycles
3	ldmda d!, {a}
2	stmib r15, {a}
3	ldmda e!, {b}
2	stmia r15, {b} ; Redundant. Saves a cycle
6	nopl ; Replaced
	dw 0 ; Replaced with b
	dw $ + 12
	dw true
	dw $ + 36
	; NOT c
2		stmib r15, {c}
2		stmia c, {c}
2		stmia c, {c}
6		nopl ; Replaced
		dw false
		dw $ + 12
		dw true
		dw $ + 4
2	stmda f!, {c}
