; XNOR gate. Output is true if inputs are equal

Base XNOR:
	; d = b ? a : !a
	;
	; 8/16 words, 12-24 cycles
	; 1 delay slot
2	stmib r15, {b}
2	stmia a, {a}
2	stmia r15, {a}
6	nopl ; Replaced
	dw 0 ; Replaced with a
	dw common_ret
	dw 0
12	dw bit_not_a

Inline XNOR:
	; d = b ? a : !a
	;
	; 16 words, 12-24 cycles
	; 1 delay slot
2	stmib r15, {b}
2	stmia a, {a}
2	stmia r15, {a}
6	nopl ; Replaced
	dw 0 ; Replaced with a
	dw $ + 44
	dw 0
	dw $ + 4
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4

Harnessed XNOR:
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
	; 8-bits would be 576 bytes, 144-240 cycles

3	ldmda e!, {b}
2	stmib r15, {b}
3	ldmda d!, {a}
2	stmia r15, {a}
6	nopl ; Replaced
	dw 0 ; Replaced with a
	dw $ + 44
	dw 0
	dw $ + 4
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4
2	stmda f!, {c}
