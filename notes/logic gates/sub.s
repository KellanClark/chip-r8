; Binary subtraction. Can be scaled to any number of bits
; First bit can be half subtract to save cycles and space

;Inputs:
; c = carry in
; d = ptr to a
; e = ptr to b
; f = ptr to out
;Outputs:
; a = trashed
; b = trashed
; c = carry out
; d is decremented
; e is decremented
; f is decremented
; sum written to *f

Half Subtract Pseudocode:
	ldmda d!, {a}
	ldmda e!, {b}
	XOR
	stmda f!, {c}
	c = b ? a : 1

Half Subtract:
	ldmda d!, {a}
	ldmda e!, {b}
	; XOR
		push {r15}
		pop {tmp}
		stmib r15, {b}
		ldmia tmp!, {tmp1-tmp4}
		stmib tmp, {a}
		nopl ; Replaced
		dw 0
		dw $ + 12
		dw 0
		dw $ + 36
		; NOT a
			stmib r15, {a}
			stmia a, {a}
			stmia a, {a}
			nopl ; Replaced
			dw false
			dw $ + 12
			dw true
			dw $ + 4
	; c = b ? a : 1
		stmib r15, {b}
	stmda f!, {c}
		stmia r15, {a}
		nopl ; Replaced with b
		dw 0 ; Replaced with a
		dw $ + 12
		dw true
		dw $ + 4

Full Subtract Pseudocode:
	ldmda e!, {b}
	push {c}
	NOT b
	push {c}
	pop {b}
	ldmda d!, {a}
	XOR
	push {c}
	AND
	pop {a, b}
	push {c}
	XOR
	stmda f!, {c}
	AND
	push {c}
	pop {a, b}
	OR

Full Subtract:
	ldmda e!, {b}
	; NOT b
		stmib r15, {b}
	push {c}
	ldmda d!, {a}
		nopl ; Replaced
		dw false
		dw $ + 12
		dw true
		dw $ + 4
	push {c}
	pop {b}
	; XOR
		push {r15}
		pop {tmp}
		stmib r15, {b}
		ldmia tmp!, {tmp1-tmp4}
		stmib tmp, {a}
		nopl ; Replaced
		dw 0
		dw $ + 12
		dw 0
		dw $ + 36
		; NOT a
			stmib r15, {a}
			stmia a, {a}
			stmia a, {a}
			nopl ; Replaced
			dw false
			dw $ + 12
			dw true
			dw $ + 4
	; AND
		stmib r15, {a}
	push {c}
		stmia r15, {b}
		nopl ; Replaced
		dw 0 ; Replaced with b
		dw $ + 12
		dw false
		dw $ + 4
	pop {a, b}
	push {c}
	; XOR
		push {r15}
		pop {tmp}
		stmib r15, {b}
		ldmia tmp!, {tmp1-tmp4}
		stmib tmp, {a}
		nopl ; Replaced
		dw 0
		dw $ + 12
		dw 0
		dw $ + 36
		; NOT a
			stmib r15, {a}
			stmia a, {a}
			stmia a, {a}
			nopl ; Replaced
			dw false
			dw $ + 12
			dw true
			dw $ + 4
	; AND
		stmib r15, {a}
	stmda f!, {c}
		stmia r15, {b}
		nopl ; Replaced
		dw 0 ; Replaced with b
		dw $ + 12
		dw false
		dw $ + 4
	push {c}
	pop {a, b}
	; OR
		push {r15}
		pop {tmp}
		stmib r15, {a}
		ldmia tmp!, {tmp1-tmp4}
		stmib tmp, {b}
		nopl ; Replaced with a
		dw true
		dw $ + 12
		dw 0 ; Replaced with b
		dw $ + 4
