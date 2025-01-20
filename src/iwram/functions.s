; Shoving all the large functions in this file so I don't have to look at them

macro get_register_msb reg {
	load_base register_table_msb
	call bin_to_ofs_4
	ldmia b, {reg\}
}

register_table_msb:
	dw reg_V0
	dw reg_V1
	dw reg_V2
	dw reg_V3
	dw reg_V4
	dw reg_V5
	dw reg_V6
	dw reg_V7
	dw reg_V8
	dw reg_V9
	dw reg_VA
	dw reg_VB
	dw reg_VC
	dw reg_VD
	dw reg_VE
	dw reg_VF

macro get_register_lsb reg {
	load_base register_table_lsb
	call bin_to_ofs_4
	ldmia b, {reg\}
}

register_table_lsb:
	dw reg_V0 + 28
	dw reg_V1 + 28
	dw reg_V2 + 28
	dw reg_V3 + 28
	dw reg_V4 + 28
	dw reg_V5 + 28
	dw reg_V6 + 28
	dw reg_V7 + 28
	dw reg_V8 + 28
	dw reg_V9 + 28
	dw reg_VA + 28
	dw reg_VB + 28
	dw reg_VC + 28
	dw reg_VD + 28
	dw reg_VE + 28
	dw reg_VF + 28

;Inputs:
; a = pointer to binary number
; b = base address
;Outputs:
; c = trashed
; a = incremented n words
; b = base with offset added
;
; Each bit takes 9 words and 15 cycles not counting the increment(s) at the end
bin_to_ofs_12:
	; +2048
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_11
	repeat 256
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_11:
	; +1024
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_10
	repeat 128
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_10:
	; +512
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_9
	repeat 64
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_9:
	; +256
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_8
	repeat 32
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_8:
	; +128
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_7
	repeat 16
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_7:
	; +64
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_6
	repeat 8
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_6:
	; +32
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_5
	repeat 4
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_5:
	; +16
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw bin_to_ofs_4
	repeat 2
		ldmia b!, {tmp0-tmp7}
	end repeat

bin_to_ofs_4:
	; +8
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia b!, {tmp0-tmp7}

	; +4
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia b!, {tmp0-tmp3}

	; +2
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia b!, {tmp0,tmp1}

	; +1
	ldmia a!, {tmp}
	stmib r15, {tmp}
	nopl
	nopl
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia b!, {tmp0}

common_ret:
	ret

; Checks if 2 8-bit numbers are equal
;
;Inputs:
; ptr1 = ptr to a
; ptr2 = ptr to b
;Outputs:
; a = trashed
; b = trashed
; c = result
; ptr1 is incremented
; ptr2 is incremented
equal_8:
	repeat 8
		ldmia ptr2!, {b}
		; XNOR
			stmib r15, {b}
			ldmia ptr1!, {a}
			stmia r15, {a}
			nopl ; Replaced
			dw 0 ; Replaced with a
			dw $ + 44
			dw 0
			dw $ + 4
			stmib r15, {a}
			nopl
			nopl
			nopl ; Replaced with a
			dw false
			dw $ + 12
			dw true
			dw $ + 4
		push {c}
		if % > 1
			pop {a, b}
			; AND
				stmib r15, {a}
				stmib r15, {b}
				nopl
				nopl ; Replaced with a
				dw 0 ; Replaced with b
				if % = 8
					dw common_ret
				else
					dw $ + 12
				end if
				dw false
				if % = 8
					dw common_ret
				else
					dw $ + 4
				end if
			push {c}
		end if
	end repeat

; Writes the boolean value in reg to VF, clearing the top 7 bits of the register in the process
macro write_to_vf reg {
	; c = reg ? bin_constant_1 : bin_constant_0
	stmib r15, {reg\}
	nopl
	nopl
	nopl ; Replaced with reg
	dw bin_constants + 32
	dw $ + 12
	dw bin_constants
	dw $ + 4

	; VF = c
	ldmia c, {tmp0-tmp7\}
	stmdb ptr3, {tmp0-tmp7\}
}

; 8-bit addition
;
;Inputs:
; ptr1 = ptr to a/out
; ptr2 = ptr to b
;Outputs:
; a = trashed
; b = trashed
; c = carry out
; ptr1 is decremented
; ptr2 is decremented
; sum written to *ptr1
add_8:
	; Half Add
		ldmda ptr1, {a}
		ldmda ptr2!, {b}
		; XOR
			push {r15}
			pop {tmp}
			stmib r15, {b}
			ldmia tmp!, {tmp1-tmp4}
			stmib tmp, {a}
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 36
			; NOT a
				stmib r15, {a}
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; AND
			stmib r15, {a}
		stmda ptr1!, {c}
			stmia r15, {b}
			nopl ; Replaced with a
			dw 0 ; Replaced with b
			dw $ + 12
			dw false
			dw $ + 4
	; Full Add
	repeat 7
		ldmda ptr1, {a}
		ldmda ptr2!, {b}
		push {c}
		; XOR
			push {r15}
			pop {tmp}
			stmib r15, {b}
			ldmia tmp!, {tmp1-tmp4}
			stmib tmp, {a}
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 36
			; NOT a
				stmib r15, {a}
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; AND
			stmib r15, {a}
		push {c}
			stmia r15, {b}
			nopl ; Replaced with a
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
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 36
			; NOT c
				stmib r15, {a}
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; AND
			stmib r15, {a}
		stmda ptr1!, {c}
			stmia r15, {b}
			nopl ; Replaced with a
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
			nopl ; Replaced
			dw true
			if % = 7
				dw common_ret
				dw 0
				dw common_ret
			else
				dw $ + 12
				dw 0 ; Replaced with b
				dw $ + 4
			end if
	end repeat

; 8-bit subtraction
;
;Inputs:
; ptr1 = ptr to a
; ptr2 = ptr to b
; ptr3 = ptr to out
;Outputs:
; a = trashed
; b = trashed
; c = carry out
; ptr1 is decremented
; ptr2 is decremented
; ptr3 is decremented
; sum written to *ptr3
subtract_8:
	; Half Subtract
		ldmda ptr1!, {a}
		ldmda ptr2!, {b}
		; XOR
			push {r15}
			pop {tmp}
			stmib r15, {b}
			ldmia tmp!, {tmp1-tmp4}
			stmib tmp, {a}
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 36
			; NOT a
				stmib r15, {a}
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; c = b ? a : 1
			stmib r15, {b}
		stmda ptr3!, {c}
			stmia r15, {a}
			nopl ; Replaced with b
			dw 0 ; Replaced with a
			dw $ + 12
			dw true
			dw $ + 4
	; Full Subtract
	repeat 7
		ldmda ptr2!, {b}
		; NOT b
			stmib r15, {b}
		push {c}
		ldmda ptr1!, {a}
			nopl ; Replaced with b
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
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 36
			; NOT a
				stmib r15, {a}
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; AND
			stmib r15, {a}
		push {c}
			stmia r15, {b}
			nopl ; Replaced with a
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
				nopl
				nopl
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw true
				dw $ + 4
		; AND
			stmib r15, {a}
		stmda ptr3!, {c}
			stmia r15, {b}
			nopl ; Replaced with a
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
			if % = 7
				dw common_ret
				dw 0
				dw common_ret
			else
				dw $ + 12
				dw 0 ; Replaced with b
				dw $ + 4
			end if
	end repeat
