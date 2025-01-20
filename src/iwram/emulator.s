; Main code for the CHIP-8 emulator

; Quirks (see quirks.json in the database):
; - Shift quirk
;     Address: handler_8XY6 | handler_8XYE
;     True Value: ldmda ptr1, {tmp1-tmp7, a} | ldmda ptr1, {tmp0-tmp7}
;     False Value: ldmda ptr2, {tmp1-tmp7, a} | ldmda ptr2, {tmp0-tmp7}
; - Load/Store quirk: increment index register by X
;     Address: handler_FX55.break
;     True Value: ldmda ptr2!, {tmp}
;     False Value: nopl
; - Load/Store quirk: leave index register unchanged
;     Address: handler_FX55.break + 4
;     True Value: ret
;     False Value: stmib ptr3, {ptr2}
; - Wrap quirk
;     Address: N/A
;     True Value: Unsupported
;     False Value: Unsupported
; - Jump quirk
;     Address: handler_table + 44
;     True Value: handler_BXNN_quirky
;     False Value: handler_BNNN
; - vBlank quirk
;     Address: handler_DXYN.end
;     True Value: pop {b}
;     False Value: pop {b, r15}
; - vF reset quirk
;     Address: logical_end
;     True Value: ldmia r15, {tmp0-tmp3, r15}
;     False Value: ret


include 'variables.s'
include 'functions.s'

emulator_start:
	; a will hold value of PC
	; b will hold pointer to instruction handler
	; ptr2 will hold pointer to timers (IT/DT/ST)
	; ptr3 will hold pointer to VF/PC/I
	; It is the instruction's job to increment and store PC

	.loop:
		; Set up registers
		dw 0xE89FD200 ; ldmia r15, {b,ptr2,ptr3,r15}
		dw 0
		dw handler_table
		dw delay_timer
		dw reg_PC
		dw $ + 4
		ldmia ptr3, {a}

		; Save timer pointer
		push {ptr2}

		; Call the handler
		call bin_to_ofs_4
		callr b

		; Load timer pointer into ptr2
		dw 0xE81F9000 ; ldmda r15, {ptr2, r15}
		dw delay_timer
		dw $ + 4
		pop {ptr2}

		; Decrement instruction_timer
		ldmdb ptr2, {a}
		ldmdb a, {a}

		; if instruction_timer is 0, all instructions have been executed for the frame
		ldmia a, {c} ; c = instruction_timer->isZero
		stmib r15, {c}
		stmdb ptr2, {a} ; Write back instruction_timer
		stmdb c, {c}
		nopl ; Replaced with c
		dw_number INSTRUCTIONS_PER_FRAME
		dw $ + 12
		dw 0
		dw .loop

		; Reset instruction_timer
		stmdb ptr2, {c}

		; Wait until vblank
		.vblank_loop:
			dw 0xE89F8FFF ; ldmia r15, {tmp0-tmp7,a,b,c,d,r15}
			dw 0
			times 8 dw false
			dw REG_DISPSTAT
			dw REG_IE
			dw .vblank_loop
			dw $ + 48
			dw $ + 4
			push {tmp, c}

			; Transform DISPSTAT into a LDM instruction
			ldmia a, {c} ; c = DISPSTAT
			stmia b, {c} ; IE = c
			; VCOUNT was in the top half and could have cleared the L bit. Luckily timer 1 is constantly requesting interrupts so this shouldn't be a problem
			ldmia b, {c} ; c = IE/IF

			; c is a ldmneda r0, {DISPSTAT}
			; r0-r7 are all false values, meaning r0 points to open bus
			; If I make the open bus value true, it effectively translates the bottom 8 bits to one of our "binary" numbers

			; The following code doesn't work when DISPSTAT is 0 because of the empty rlist bug
			; How I get around that is left as an exercise to the reader
			;stmib r15, {c}
			;nopl
			;nopl
			;nopl ; Replaced
			;ldmib r15, {r15}
			;dw 0
			;dw true ; Open
			;dw $ + 4

			stmib r15, {c} ; Store trap
			stmia d, {c} ; Store real
			nopl
			nopl ; Replaced (trap)
			pop {tmp}
			stmeqia r2, {r2, r6, r10, r15} ; Open bus (trap) ; 0x08828444
			nopl ; Replaced (real)
			ldmia r15, {r15}
			dw true ; Open bus (real)
			dw $ + 4

			; At this point r0 should be holding the vblank flag
			stmib r15, {tmp2}
			nopl
			pop {tmp}
			nopl ; Replaced
			dw 0
			dw $ + 12
			dw 0
			dw .vblank_loop

		; Decrement delay_timer and sound_timer
		ldmia ptr2, {a, b}
		ldmdb a, {a}
		ldmdb b, {b}
		stmia ptr2, {a, b}

		; Check if we should be playing sound
		dw 0xE81F8100 ; ldmda r15, {a, r15}
		dw REG_SOUNDCNT_L
		dw $ + 4

		ldmib b, {b}
		stmib r15, {b}
		nopl
		nopl
		nopl ; Replaced
		dw 0x00022277 ; Channel 2 enabled
		dw $ + 12
		dw 0x00020077 ; Everything disabled
		dw $ + 4
		stmia a, {c} ; Write to SOUNDCNT_L

		; Make copy of old key values
		dw 0xE81F8400 ; ldmda r15, {c, r15}
		dw emu_pressed_keys - 4
		dw $ + 4
		ldmib c, {r0-r9}
		stmdb c, {r0-r9}

		; Get input
		.debug:
			dw 0xE89FDFFF ; ldmia r15, {tmp0-tmp7,a,b,c,d,e,f,r15}
			dw 0
			times 10 dw true ; tmp0-b
			dw REG_KEYINPUT ; c
			dw REG_IE ; d
			dw .no_keys ; e
			dw $ + 48 ; f
			dw $ + 4
			push {tmp, e}

			; Transform KEYINPUT into a LDM instruction
			ldmia c, {e} ; e = KEYINPUT
			stmia d, {e} ; IE = e
			ldmia d, {e} ; e = IE/IF

			; e is a ldmneda r0, {KEYINPUT}
			; r0-r9 are all true values, meaning r0 points to open bus
			; If I make the open bus value false, it effectively translates the bottom 10 bits to one of our "binary" numbers

			stmib r15, {e} ; Store trap
			stmia f, {e} ; Store real
			nopl
			nopl ; Replaced (trap)
			pop {tmp}
			stmeqia r2, {r2, r6, r10, r15} ; Open bus (trap) ; 0x08828444
			nopl ; Replaced (real)
			ldmia r15, {r15}
			dw false ; Open bus (real)
			dw $ + 4

			; Now r0-r9 contains all the key values and they can be stored in the array
			pop {c}
		.no_keys:
			dw 0xE89FD800 ; ldmia r15, {ptr1-ptr3, r15}
			dw 0
			dw emu_pressed_keys ; ptr1
			dw emu_old_pressed_keys ; ptr2
			dw emu_falling_edge_keys ; ptr3
			dw $ + 4
			stmia ptr1, {r0-r9}

		; Check for falling edge using modified OR gate
		; (NOT a) AND b
		; a ? false : b
		repeat 10
			ldmia ptr1!, {a}
			ldmia ptr2!, {b}
			; (NOT a) AND b
				push {r15}
				pop {tmp}
				stmib r15, {a}
				ldmia tmp!, {tmp1-tmp4}
				stmib tmp, {b}
				nopl ; Replaced with a
				dw false
				dw $ + 12
				dw 0 ; Replaced with b
				dw $ + 4
			stmia ptr3!, {c}
		end repeat

		; Loop infinitely
		jump .loop

handler_table:
	dw handler_00EN
	dw handler_1NNN
	dw handler_2NNN
	dw handler_3XNN
	dw handler_4XNN
	dw handler_5XY0
	dw handler_6XNN
	dw handler_7XNN
	dw handler_8XYN
	dw handler_9XY0
	dw handler_ANNN
	dw handler_BNNN
	dw handler_CXNN
	dw handler_DXYN
	dw handler_EXNN
	dw handler_FXNN

unknown:
	halt

handler_00EN:
	; Increment PC
	ldmia a!, {tmp0-tmp7}
	ldmia a!, {tmp0-tmp3}
	; Choose between 00E0 and 00EE based on bit 3 of the opcode
	stmib r15, {tmp0}
	stmia ptr3!, {a} ; Write back PC (for 00E0) and put SP in range of ptr3 (for 00EE)
	stmia tmp0, {tmp0}
	nopl ; Replaced
	dw 0
	dw handler_00EE
	dw 0
	dw handler_00E0

handler_00E0: ; Clear display
	call emulator_clear_screen
	ret

handler_00EE: ; Return
	; pop a
	ldmib ptr3, {ptr1} ; ptr1 = SP
	ldmdb ptr1!, {a}
	stmib ptr3, {ptr1} ; SP = SP - 1

	; PC = a
	stmdb ptr3, {a}
	ret

handler_1NNN: ; PC = NNN
	; b = NNN
	load_base offset_to_address_table
	call bin_to_ofs_12
	ldmia b, {b}

	; PC = b
	stmia ptr3, {b}
	ret

handler_2NNN: ; Call NNN
	; b = NNN
	load_base offset_to_address_table
	call bin_to_ofs_12
	ldmia b, {b}

	; push (PC + 16)
	ldmib ptr3!, {tmp, ptr1} ; ptr1 = SP
	stmia ptr1!, {a}
	stmda ptr3!, {ptr1} ; SP = SP + 1

	; PC = b
	stmdb ptr3, {b}
	ret

handler_3XNN: ; if (VX == NN)
	; ptr1 = &V[X]
	; a += 4
	get_register_msb ptr1
	; ptr2 = &NN
	move ptr2, a

	; c = *ptr1 == *ptr2
	call equal_8

	; if (c) ptr2 += 16;
	stmib r15, {c}
	stmia c, {c}
	stmia c, {c}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 12
	ldmia ptr2!, {tmp0-tmp7}
	ldmia ptr2!, {tmp0-tmp7}

	; PC = ptr2
	stmia ptr3, {ptr2}
	ret

handler_4XNN: ; if (VX != NN)
	; ptr1 = &V[X]
	; a += 16
	get_register_msb ptr1
	; ptr2 = &NN
	move ptr2, a

	; c = *ptr1 == *ptr2
	call equal_8

	; if (!c) ptr2 += 16;
	stmib r15, {c}
	stmia c, {c}
	stmia c, {c}
	nopl ; Replaced
	dw 0
	dw $ + 20
	dw 0
	dw $ + 4
	ldmia ptr2!, {tmp0-tmp7}
	ldmia ptr2!, {tmp0-tmp7}

	; PC = ptr2
	stmia ptr3, {ptr2}
	ret

handler_5XY0: ; if (VX == VY)
	; c = VX == VY
	; a += 8
	get_register_msb ptr1
	get_register_msb ptr2
	push {a}
	call equal_8
	pop {a}

	; if (c) a += 16
	stmib r15, {c}
	stmia c, {c}
	stmia c, {c}
	nopl ; Replaced
	dw 0
	dw $ + 12
	dw 0
	dw $ + 12
	ldmia a!, {tmp0-tmp7}
	ldmia a!, {tmp0-tmp7}

	; a += 4
	; PC = a
	ldmia a!, {tmp0-tmp3}
	stmia ptr3, {a}
	ret

handler_6XNN: ; VX = NN
	; ptr1 = &V[X]
	get_register_msb ptr1

	; *ptr1 = NN
	ldmia a!, {tmp0-tmp7}
	stmia ptr1, {tmp0-tmp7}

	; PC = PC + 16
	stmia ptr3, {a}
	ret

handler_7XNN: ; VX += NN
	; Get source address 1
	get_register_lsb ptr1

	; Write back PC
	ldmia a!, {tmp0-tmp7}
	stmia ptr3, {a}

	; Get source address 2
	ldmda a!, {tmp0}
	move ptr2, a

	; Add NN to VX
	call add_8
	ret

handler_8XYN:
	; Load VX and VY into d and e respectively
	; 8XYN opcodes will use the LSB forms of the registers because some need to add/subtract
	get_register_lsb ptr1
	get_register_lsb ptr2

	; Get handler
	load_base .handler_table_8XYN
	call bin_to_ofs_4

	; Write back PC
	stmia ptr3, {a}

	; Jump to handler
	ldmia b, {r15}

	.handler_table_8XYN:
		dw handler_8XY0
		dw handler_8XY1
		dw handler_8XY2
		dw handler_8XY3
		dw handler_8XY4
		dw handler_8XY5
		dw handler_8XY6
		dw handler_8XY7
		dw unknown
		dw unknown
		dw unknown
		dw unknown
		dw unknown
		dw unknown
		dw handler_8XYE
		dw unknown

handler_8XY0: ; VX = VY
	ldmda ptr2, {tmp0-tmp7}
	stmda ptr1, {tmp0-tmp7}
	ret

handler_8XY1: ; VX |= VY
	repeat 8
		ldmda ptr1, {a}
		ldmda ptr2!, {b}
		; OR
			push {r15}
			pop {tmp}
			stmib r15, {a}
			ldmia tmp!, {tmp1-tmp4}
			stmib tmp, {b}
			nopl ; Replaced
			dw true
			dw $ + 12
			dw 0 ; Replaced with b
			dw $ + 4
		stmda ptr1!, {c}
	end repeat

; Common return point for all logical operation opcodes (8XY1, 8XY2, and 8XY3) so all of them can be patched at once for the vF reset quirk
logical_end:
	; VF = 0
	dw 0xE89F800F ; ldmia r15, {tmp0-tmp3, r15}
	dw 0
	times 4 dw false
	dw $ + 4

	stmdb ptr3, {tmp0-tmp3}
	stmdb ptr3, {tmp0-tmp3}

	ret

handler_8XY2: ; VX &= VY
	repeat 8
		ldmda ptr1, {a}
		; AND
			stmib r15, {a}
		ldmda ptr2!, {b}
			stmia r15, {b}
			nopl ; Replaced
			dw 0 ; Replaced with b
			dw $ + 12
			dw false
			dw $ + 4
		stmda ptr1!, {c}
	end repeat
	jump logical_end

handler_8XY3: ; VX ^= VY
	repeat 8
		ldmda ptr1, {a}
		ldmda ptr2!, {b}
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
			stmib r15, {a}
			stmia a, {a}
			stmia a, {a}
			nopl ; Replaced
			dw false
			dw $ + 12
			dw true
			dw $ + 4
		stmda ptr1!, {c}
	end repeat
	jump logical_end

handler_8XY4: ; VX += VY
	; VX += VY
	call add_8

	; VF = carry
	write_to_vf c
	ret

handler_8XY5: ; VX -= VY
	; Destination is VX
	push {ptr3}
	move ptr3, d

	; VX = VX - VY
	call subtract_8

	; VF = carry
	pop {ptr3}
	write_to_vf c
	ret

handler_8XY6: ; VX >>= 1
	; Load VY shifted to the right
	ldmda ptr2, {tmp1-tmp7, a}

	; Set the MSB to 0
	dw 0xE81F8001 ; ldmda r15, {tmp0, r15}
	dw false
	dw $ + 4

	; Store the result back to VX
	stmda ptr1, {tmp0-tmp7}

	; Set VF
	write_to_vf a
	ret

handler_8XY7: ; VX = VY - VX
	; swap the source registers while keeping the destination the same
	push {ptr1, ptr2, ptr3}
	ldmia r13, {f} ; ptr3 = ptr1
	pop {ptr2} ; ptr2 = ptr1
	pop {ptr1} ; ptr1 = ptr2

	; VX = VY - VX
	call subtract_8

	; VF = carry
	pop {ptr3}
	write_to_vf c
	ret

handler_8XYE: ; VX >>= 1
	; Load VY shifted to the left
	ldmda ptr2, {tmp0-tmp7}

	; Set the new LSB to 0
	dw 0xE81F8100 ; ldmda r15, {a, r15}
	dw false
	dw $ + 4

	; Store the result shifted to the left back to VX
	stmda ptr1, {tmp1-tmp7, a}

	; Set VF
	write_to_vf tmp0
	ret

handler_9XY0: ; if (VX != VY)
	; c = VX == VY
	; a += 8
	get_register_msb ptr1
	get_register_msb ptr2
	push {a}
	call equal_8
	pop {a}

	; if (c) a += 16
	stmib r15, {c}
	stmia c, {c}
	stmia c, {c}
	nopl ; Replaced
	dw 0
	dw $ + 20
	dw 0
	dw $ + 4
	ldmia a!, {tmp0-tmp7}
	ldmia a!, {tmp0-tmp7}

	; a += 4
	; PC = a
	ldmia a!, {tmp0-tmp3}
	stmia ptr3, {a}
	ret

handler_ANNN: ; I = NNN
	load_base offset_to_address_table ; b = address LUT
	call bin_to_ofs_12 ; b = LUT + offset
	; I = *b
	ldmia b, {tmp}
	stmib f, {tmp}

	; PC = PC + 16
	stmia ptr3, {a}
	ret

handler_BNNN: ; PC = V0 + NNN
	; b = NNN
	load_base offset_to_address_table
	call bin_to_ofs_12

	; b += V0
	dw 0xE81F8100 ; ldmda r15, {a, r15}
	dw reg_V0
	dw $ + 4
	call bin_to_ofs_8

	; PC = b
	ldmia b, {b}
	stmia ptr3, {b}
	ret

; The HP48 implementation of CHIP-8 does BNNN a little weirdly
; They're different enough that it's easier to swap implementations than patch one of them
handler_BXNN_quirky: ; PC = VX + NNN
	push {a}

	; b = XNN
	load_base offset_to_address_table
	call bin_to_ofs_12

	; b += VX
	pop {a}
	push {b}
	get_register_msb a
	pop {b}
	call bin_to_ofs_8

	; PC = b
	ldmia b, {b}
	stmia ptr3, {b}
	ret

handler_CXNN: ; VX = rand() & NN
	; VX will also be used as a buffer for the unmasked random number
	get_register_msb ptr2

	; VX = TIMCNT0_L
		; Transform TIMCNT0_L into a LDM instruction
		dw 0xE89F8007 ; ldmia r15, {tmp0-tmp2, r15}
		dw 0
		dw REG_TM0CNT_L
		dw REG_SOUND4CNT_H
		dw REG_IE
		dw $ + 4

		.debug:
		ldmia tmp0, {d} ; d = TIMCNT0
		stmia tmp1, {d} ; SOUND4CNT_H = d
		ldmia tmp1, {d} ; d = SOUND4CNT_H (TIMCNT0 &= 0x40FF)
		stmia tmp2, {d} ; IE = d
		ldmia tmp2, {d} ; d = IE/IF (d = (TIMCNT0 & 0x3FFF) | 0x18100000)

		; d is a ldmneda r0, {TIMCNT0_L & 0xFF}
		; From here it's pretty standard

		dw 0xE89F86FF ; ldmia r15, {tmp0-tmp7, b, c, r15}
		dw 0
		times 8 dw false ; tmp0-tmp7
		dw .trap_return ; b
		dw .replace ; c
		dw $ + 4
		push {tmp, b}

		stmib r15, {d} ; Store trap
		stmia c, {d} ; Store real
		nopl
		nopl ; Replaced (trap)
		pop {tmp}
		stmeqia r2, {r2, r6, r10, r15} ; Open bus (trap) ; 0x08828444
		.replace: nopl ; Replaced (real)
		ldmia r15, {r15}
		dw true ; Open bus (real)
		dw $ + 4

		; tmp0-tmp7 now contains TIMCNT0_L & 0xFF
		; I just need to balance the stack and store them in VX
		pop {c}
		.trap_return:
		stmia ptr2, {tmp0-tmp7}

	; VX &= NN
	repeat 8
		ldmia ptr2, {b}
		; AND
			stmib r15, {b}
		ldmia a!, {b}
			stmia r15, {b}
			nopl ; Replaced
			dw 0 ; Replaced with b
			dw $ + 12
			dw false
			dw $ + 4
		stmia ptr2!, {c}
	end repeat

	; PC = PC + 16
	stmia ptr3, {a}

	ret

handler_DXYN: ; Draw sprite
	; VF = false
	dw 0xE89F80FF ; ldmia r15, {tmp0-tmp7, r15}
	nopl
	times 8 dw false
	dw $ + 4
	stmdb f, {tmp0-tmp7}

	; Get arguments and write back PC
		; d = &V[X]
		get_register_msb d
		; e = &V[Y]
		get_register_msb e
		; push N + 1
		load_base offset_to_number_table + 4
		call bin_to_ofs_4
		ldmia b, {b}
		push{b}
		; PC = PC + 16
		stmia f, {a}

	; Calculate starting addresses with some stack abuse
		; Move r13 to a
		stmdb r13, {r13}
		ldmdb r13, {a}
		; Assemble bits from VX and VY into an 11-bit number using the stack as a buffer
		ldmia d, {tmp0-tmp7}
		stmdb a!, {tmp2-tmp7, f} ; Store an extra register to make space for the call later
		ldmia e, {tmp0-tmp7}
		stmdb a!, {tmp3-tmp7}
		; Get pointer to the pixel entry
		load_base dxyn_ofs_to_entry
		call bin_to_ofs_11
		ldmia b, {b}
		push {b}
		; d = I
		ldmib f, {d}

	.debug:
	; Putting some commonly used values in tmp registers to keep the loop as small as possible
	pop {tmp1}
	dw 0xE89F80F0 ; ldmia r15, {tmp4-tmp7, r15}
	dw 0
	dw OFF_COLOR ; tmp4
	dw reg_VF + 28 ; tmp5
	dw true ; tmp6
	dw false ; tmp7
	dw $ + 8

	; VX and VY are no longer needed
	; Reminder on register assignments:
	; tmp0 = Y in bounds
	; tmp1 = pixel entry pointer
	; tmp2 = next line pointer
	; tmp3 = on color
	; tmp4 = off color
	; tmp5 = &VF.0
	; tmp6 = true
	; tmp7 = false
	; a = X in bounds
	; d = memory pointer
	; e = framebuffer pointer
	; f = VRAM pointer
	; tmp0,a,b,c = temp variables for loop body
	.loop:
		; Move pixel pointer to next line
		ldmdb r13, {tmp1}

		pop {b}
		; Check if all the lines have been drawn
			; Decrement N
			num_dec b ; b--
			; Exit the loop if N is 0
			ldmia b, {c} ; c = b.isZero
			stmib r15, {c}
			push {b}
			ldmia tmp1, {tmp0, tmp2}
			nopl ; Replaced
			dw 0
			dw .end
			dw 0
			dw $ + 4

		; Check if the Y coordinate is out of bounds
			stmib r15, {tmp0}
			stmdb r13, {tmp2} ; Like a push but I don't have to worry about balancing the stack
			nopl
			nopl ; Replaced
			dw 0
			dw $ + 12
			dw 0
			dw .end

		; line loop
		repeat 8
			ldmia tmp1!, {tmp0, tmp2, tmp3, a, e, f}

			; Check if the X coordinate is out of bounds
			stmib r15, {a}
			nopl
			nopl
			nopl ; Replaced
			dw 0
			dw $ + 20 + (4 * (9 - %))
			dw 0
			dw $ + 4

			; Advances the memory pointer to the next byte when we hit the edge
			; Inefficient but I just want to get this done
			times (9 - %) ldmia d!, {tmp0}
			jump .loop

			; a = *(d++)
			; b = *(e++)
			; f++
			; if (a) {
			;   if (b) {
			;     VF = true;
			;     *(e - 1) = false;
			;     *(f - 1) = offColor;
			;   } else {
			;     *(e - 1) = true;
			;     *(f - 1) = onColor;
			;   }
			; }

			; a = *(d++)
			ldmia d!, {a}
			; if (a) {
			stmib r15, {a}
			ldmia e!, {b} ; b = *(e++)
			ldmia f!, {tmp0} ; f++
			nopl ; Replaced with a
			dw 0
			dw $ + 12
			dw 0
			dw $ + 64
			;   if (b) {
			stmib r15, {b}
			stmdb b, {b}
			stmdb b, {b}
			nopl ; Replaced with b
			dw 0
			dw $ + 12
			dw 0
			dw $ + 24
			;     VF = true;
			stmia tmp5, {tmp6}
			;     *(e - 1) = false;
			stmdb e, {tmp7}
			;     *(f - 1) = offColor;
			stmdb f, {tmp4}
			;   } else {
			ldmdb r15, {r15}
			dw $ + 12
			;     *(e - 1) = true;
			stmdb e, {tmp6}
			;     *(f - 1) = onColor;
			stmdb f, {tmp3}
			;   }
			; }
		end repeat

		jump .loop

	.end:
		pop {b}
		; Set instruction timer to 1 to wait for next frame
		dw 0xE89F8003 ; ldmia r15, {tmp0, tmp1, r15}
		dw 0
		dw instruction_timer ; tmp0
		dw_number 1 ; tmp1
		dw $ + 4
		stmia tmp0, {tmp1}
		ret

handler_EXNN: ; if (keys[VX])
	; Get Vx and NN
	get_register_lsb ptr1
	ldmia a!, {tmp0-tmp7}
	push {tmp3, a}
	push {ptr1}
	pop {a, d, ptr2}
	ldmda a!, {tmp0-tmp2} ; Point to bottom nibble

	; Get key value
	load_base keymap
	call bin_to_ofs_4
	ldmia b, {a}
	ldmia a, {a}

	; We want different behavior for EX9E and EXA1
	; c = a XNOR d
	stmib r15, {d}
	nopl
	stmia r15, {a}
	nopl ; Replaced with d
	dw 0 ; Replaced with a
	dw $ + 44
	dw 0
	dw $ + 4
		; NOT a
		stmib r15, {a}
		nopl
		nopl
		nopl ; Replaced
		dw false
		dw $ + 12
		dw true
		dw $ + 4

	; Skip the next instruction
	stmib r15, {c}
	nopl
	nopl
	nopl ; Replaced with c
	dw 0
	dw $ + 12
	dw 0
	dw $ + 12
	ldmia ptr2!, {tmp0-tmp7}
	ldmia ptr2!, {tmp0-tmp7}

	; Write back PC
	stmia ptr3, {ptr2}
	ret

handler_FXNN:
	; Some instructions need VX and some need X directly
	; I'll skip over X and save it on the stack so they can decode it themselves
	push {a}
	ldmia a!, {tmp0-tmp3}

	; Get handler
	load_base .handler_table_FXNN
	call bin_to_ofs_8

	; Write back PC
	stmia ptr3, {a}
	pop {a}

	; Jump to handler
	ldmia b, {r15}

	; I know a giant 256 entry LUT is overkill for 9 instructions, but I have memory to spare
	.handler_table_FXNN:
	repeat 256
		val = % - 1
		if val = 0x07
			dw handler_FX07
		else if val = 0x0A
			dw handler_FX0A
		else if val = 0x15
			dw handler_FX15
		else if val = 0x18
			dw handler_FX18
		else if val = 0x1E
			dw handler_FX1E
		else if val = 0x29
			dw handler_FX29
		else if val = 0x33
			dw handler_FX33
		else if val = 0x55
			dw handler_FX55
		else if val = 0x65
			dw handler_FX65
		else
			dw unknown
		end if
	end repeat

handler_FX07: ; VX = DT
	; Get VX pointer
	get_register_msb ptr3

	; Read delay_timer
	ldmia ptr2, {a} ; a = &delay_timer
	ldmib a, {tmp, a} ; a = a->binary
	ldmia a, {tmp0-tmp7} ; tmp = *a

	; Write delay_timer to VX
	stmia ptr3, {tmp0-tmp7}
	ret

handler_FX0A: ; VX = wait_for_key()
	; Get VX pointer
	get_register_msb ptr2
	.debug:

	; Set the counter to 16
	; Get pointer to keymap
	dw 0xE89F8900 ; ldmia r15, {a, ptr1, r15}
	dw 0
	dw_number 16 ; a
	dw keymap_edge ; ptr1
	dw $ + 4

	; I have memory to spare so there's no harm in copy-pasting 16 times instead of comparing with the counter
	repeat 16
		; If key is true, jump to .key_pressed
		ldmia ptr1!, {c} ; Reads (falling edge) key value into c. Also increments keymap pointer
		ldmia c, {c}
		stmib r15, {c}
		num_dec a ; Decrement counter
		nopl
		nopl ; Replaced with c
		dw false
		dw .key_pressed
		dw_number 1
		dw $ + 4
	end repeat

	.no_keys:
		; Decrement PC so the instruction gets run again
		ldmia ptr3, {a}
		ldmda a!, {tmp0-tmp7}
		ldmda a!, {tmp0-tmp7}
		stmia ptr3, {a}

		; Set instruction timer to 1 to wait for next frame
		ldmia ptr3!, {tmp0, tmp1}
		stmib ptr3, {c}
		ret

	.key_pressed:
		; Clear key in case this instruction is called multiple times in the same frame
		ldmdb ptr1, {ptr1}
		stmia ptr1, {c}

		; Store binary representation of the counter value in VX
		ldmib a, {tmp, a}
		ldmia a, {tmp0-tmp7}
		stmia ptr2, {tmp0-tmp7}
		ret

handler_FX15: ; DT = VX
	; Convert VX to a linked list number
	get_register_msb a
	load_base offset_to_number_table
	call bin_to_ofs_8
	ldmia b, {a}

	; Write VX to delay_timer
	stmia ptr2, {a}
	ret

handler_FX18: ; ST = VX
	; Convert VX to a linked list number
	get_register_msb a
	load_base offset_to_number_table
	call bin_to_ofs_8
	ldmia b, {a}

	; Write VX to sound_timer
	stmib ptr2, {a}
	ret

handler_FX1E: ; I += VX
	; I made it through the entire emulator and was fixing the last bug of the last opcode when I realized this instruction is fundamentally incompatible with how I structured my emulator
	; I don't care. Just shift VX on the stack and add that. It's not clean but I'm so close to being done

	; Push 3 zeros onto the stack
	dw 0xE89F8007 ; ldmia r15, {tmp0-tmp2, r15}
	nopl
	times 3 dw false
	dw $ + 4
	push {tmp0-tmp2}

	; Push VX onto the stack
	get_register_msb a
	ldmia a, {tmp0-tmp7}
	push {tmp0-tmp7}

	; Move stack pointer to a
	stmdb r13, {r13}
	ldmdb r13, {a}

	; I += VX
	ldmib ptr3, {b}
	call bin_to_ofs_11
	stmib ptr3, {b}

	; Clear up the stack
	pop {tmp0-tmp7, a-c}
	ret

handler_FX29: ; I = &font[VX]
	; Get bottom nibble of VX
	get_register_lsb a
	ldmda a!, {tmp0-tmp2}

	; Get pointer to character
	load_base offset_to_font_table
	call bin_to_ofs_4
	ldmia b, {ptr1}

	; Set I to pointer
	stmib ptr3, {ptr1}
	ret

handler_FX33: ; Store BCD of VX
	; Get BCD digit pointers
	get_register_msb a
	load_base offset_to_bcd_table
	call bin_to_ofs_8
	ldmia b, {ptr1}
	ldmia ptr1, {a, b, c}

	; Get I
	ldmib f, {ptr2}

	; Copy BCD digits to memory
	ldmia a, {tmp0-tmp7}
	stmia ptr2!, {tmp0-tmp7}
	ldmia b, {tmp0-tmp7}
	stmia ptr2!, {tmp0-tmp7}
	ldmia c, {tmp0-tmp7}
	stmia ptr2!, {tmp0-tmp7}

	ret

handler_FX55: ; Store V0-VX
	; Convert X+1 to a linked list number
	load_base offset_to_number_table + 4
	call bin_to_ofs_4
	ldmia b, {a}

	; Get V0
	dw 0xE81F8800 ; ldmda r15, {ptr1, r15}
	dw reg_V0
	dw $ + 4

	; Get I
	ldmib ptr3, {ptr2}

	.loop:
		; *(I++) = V[N++]
		ldmia ptr1!, {tmp0-tmp7}
		stmia ptr2!, {tmp0-tmp7}

		; if (--X == 0) break;
		ldmdb a, {a} ; X--
		ldmia a, {b} ; b = X.isZero
		stmib r15, {b}
		stmia b, {b}
		stmia b, {b}
		nopl ; Replaced
		dw 0
		dw .break
		dw 0
		dw .loop

.break:
	ldmia ptr2!, {tmp} ; Increment I
	stmib ptr3, {ptr2} ; Update I
	ret

handler_FX65: ; Load V0-VX
	; Convert X+1 to a linked list number
	load_base offset_to_number_table + 4
	call bin_to_ofs_4
	ldmia b, {a}

	; Get V0
	dw 0xE81F8800 ; ldmda r15, {d, r15}
	dw reg_V0
	dw $ + 4

	; Get I
	ldmib ptr3, {ptr2}

	.loop:
		; V[N++] = *(I++)
		ldmia e!, {tmp0-tmp7}
		stmia d!, {tmp0-tmp7}

		; if (--X == 0) break;
		ldmdb a, {a} ; X--
		ldmia a, {b} ; b = X.isZero
		stmib r15, {b}
		stmia b, {b}
		stmia b, {b}
		nopl ; Replaced
		dw 0
		dw handler_FX55.break ; This makes implementing the quirks a little easier
		dw 0
		dw .loop

; Get the size of the emulator so the bootstrap knows how much to copy
emulator_end:
align 32 ; Aligned to make copying easier
emulator_end_aligned:
EMULATOR_SIZE_UNALIGNED equ (emulator_end - MEM_IWRAM)
EMULATOR_SIZE equ (emulator_end_aligned - MEM_IWRAM)

; Print some useful info to the console while assembling
display "Emulator entry point is at 0x"
display_hex emulator_start, 28
display_newline

display "Emulator is 0x"
display_hex EMULATOR_SIZE_UNALIGNED, 16
display "/0x8000 bytes (0x"
display_hex EMULATOR_SIZE, 16
display " bytes in ROM)."
display_newline
display_newline

display "Debug point is at 0x"
display_hex handler_DXYN.loop, 28
display_newline
