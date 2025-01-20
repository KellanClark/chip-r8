; XOR gate. Output is true if inputs aren't equal

Base XOR:
	; d = b ? !a : a
	;
	; 10/18 words, 21-33 cycles
	; 0 delay slots
2	push {r15}
3	pop {tmp}
2	stmib r15, {b}
6	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {a}
6	nopl ; Replaced
	dw 0
12	dw bit_not_a
	dw 0
	dw common_ret

Inline XOR:
	; d = b ? !a : a
	;
	; 18 words, 21-33 cycles
	; 0 delay slots
2	push {r15}
3	pop {tmp}
2	stmib r15, {b}
7	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {a}
6	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 36
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4

Harnessed XOR:
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
	; 21 words, 29-41 cycles
	; 8-bits would be 672 bytes, 232-328 cycles

3	ldmda d!, {a}
3	ldmda e!, {b}
2	push {r15}
3	pop {tmp}
2	stmib r15, {b}
7	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {a}
6	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 36
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4
2	stmda f!, {c}
