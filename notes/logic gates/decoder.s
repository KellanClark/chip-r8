;Inputs:
; e = pointer to binary number
; f = base address
;Outputs:
; c = trashed
; e = incremented n words
; f = base with offset added
;
; Each bit takes 9 words and 15 cycles not counting the increment(s) at the end
bin_to_ofs_12_rev:
	; +2048
3	ldmia e!, {tmp}
2	stmib r15, {tmp}
2	stmia tmp, {tmp}
2	stmia tmp, {tmp}
6	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 256
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +1024
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 128
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +512
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 64
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +256
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 32
		ldmia f!, {tmp0-tmp7}
	end repeat

bin_to_ofs_8_rev:
	; +128
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 16
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +64
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 8
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +32
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 4
		ldmia f!, {tmp0-tmp7}
	end repeat

	; +16
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	repeat 2
		ldmia f!, {tmp0-tmp7}
	end repeat

bin_to_ofs_4_rev:
	; +8
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia f!, {tmp0-tmp7}

	; +4
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia f!, {tmp0-tmp3}

	; +2
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia f!, {tmp0,tmp1}

	; +1
	ldmia e!, {tmp}
	stmib r15, {tmp}
	stmia tmp, {tmp}
	stmia tmp, {tmp}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 8
	ldmia f!, {tmp0}
