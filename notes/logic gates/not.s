; NOT gate. Output is the opposite of the input.
; Can easily be modified to take any register as an input

Base NOT:
	; d = a ? false : true
	;
	; 8 words, 12 cycles
	; 2 delay slots
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw common_ret
	dw true
	dw common_ret

Inline NOT:
	; d = a ? false : true
	;
	; 8 words, 12 cycles
	; 2 delay slots
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4

Harnessed NOT:
	;Inputs:
	; d = ptr to a
	; f = ptr to out
	;Outputs:
	; a = trashed
	; c = trashed
	; d is decremented
	; f is decremented
	; result written to *f
	;
	; 10 words, 17 cycles
	; 8-bits would be 320 bytes, 152 cycles
3	ldmda d!, {a}
2	stmib r15, {a}
2	stmia a, {a}
2	stmia a, {a}
6	nopl ; Replaced
	dw false
	dw $ + 12
	dw true
	dw $ + 4
2	stmda f!, {c}
