; AND gate. Output is true if all inputs are true

Base AND:
	; c = a ? b : 0
	;
	; 8 words, 12 cycles
	; 1 delay slot
2	stmib r15, {a}
2	stmib r15, {b}
2	stmia r15, {b} ; Redundant. Saves a cycle
6	nopl ; Replaced
	dw 0 ; Replaced with b
	dw common_ret
	dw false
	dw common_ret

Inline AND:
2	stmib r15, {a}
2	stmib r15, {b}
2	stmia r15, {b} ; Redundant. Saves a cycle
6	nopl ; Replaced
	dw 0 ; Replaced with b
	dw $ + 12
	dw false
	dw $ + 4

Harnessed AND:
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
	; 10 words, 18 cycles
	; 8-bits would be 320 bytes, 144 cycles

3	ldmda d!, {a}
2	stmib r15, {a}
3	ldmda e!, {b}
2	stmia r15, {b}
6	nopl ; Replaced
	dw 0 ; Replaced with b
	dw $ + 12
	dw false
	dw $ + 4
2	stmda f!, {c}
