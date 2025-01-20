; OR gate. Output is true if either input is true

Base OR:
	; d = a ? 1 : b
	;
	; 10 words, 22 cycles
	; 0 delay slots
2	push {r15}
3	pop {tmp}
2	stmib r15, {a}
7	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {b}
6	nopl ; Replaced
	dw true
	dw common_ret
	dw 0 ; Replaced with b
	dw common_ret

Inline OR:
2	push {r15}
3	pop {tmp}
2	stmib r15, {a}
7	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {b}
6	nopl ; Replaced
	dw true
	dw $ + 12
	dw 0 ; Replaced with b
	dw $ + 4

Harnessed OR:
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
	; 13 words, 30 cycles
	; 8-bits would be 416 bytes, 240 cycles
3	ldmda d!, {a}
3	ldmda e!, {b}
2	push {r15}
3	pop {tmp}
2	stmib r15, {a}
7	ldmia tmp!, {tmp1-tmp4}
2	stmib tmp, {b}
6	nopl ; Replaced
	dw true
	dw $ + 12
	dw 0 ; Replaced with b
	dw $ + 4
2	stmda f!, {c}
