; ROM select screen that shows after boot

menu_selected_position: ; How far the arrow is from the top of the list
	dw_number 0
menu_selected_position_inv: ; How far the arrow is from the bottom of the list
	dw_number 0 ; Will be set to *toc_size at initialization

menu_old_pressed_keys:
	times 10 dw false
menu_pressed_keys:
	times 10 dw false
menu_falling_edge_keys:
	times 10 dw false

; I got into the habit of splitting blocks of code off into functions for this mini program
; It makes the logic easier to follow and the wasted cycles don't matter
menu_start:
	; Initialization
	call menu_init_objects
	call menu_display_names

	.loop:
		call menu_read_input

		dw 0xE89F9800 ; ldmia r15, {ptr1, ptr2, r15}
		dw 0
		dw menu_falling_edge_keys ; ptr1
		dw menu_selected_position ; ptr2
		dw $ + 4

		; Controls:
		; A - tmp0 - Run the selected rom
		; Up - tmp6 - Move the arrow up
		; Down - tmp7 - Move the arrow down
		ldmia ptr1, {tmp0-tmp7}

		stmib r15, {tmp0}
		ldmia ptr2, {a} ; a = *menu_selected_position
		ldmib ptr2, {f} ; f = *menu_selected_position_inv
		nopl ; Replaced with tmp0
		dw 0
		dw .a_pressed
		dw 0
		dw $ + 4

		stmib r15, {tmp6}
		nopl
		nopl
		nopl ; Replaced with tmp6
		dw 0
		dw .up_pressed
		dw 0
		dw $ + 4

		stmib r15, {tmp7}
		nopl
		nopl
		nopl ; Replaced with tmp7
		dw 0
		dw .down_pressed
		dw 0
		dw .loop

	.a_pressed:
		; This pseudocode doesn't match perfectly but should do the same thing
		; a = *menu_selected_position
		; b = toc_start
		;
		; while (a != 0) {
		;     a--
		;     b++
		; }
		;
		; a = *b
		; goto load_rom

		; b = toc_start - 4
		load_base toc_start - 4
		.a_loop:
			; c = a.isZero
			; a = a - 1
			ldmda a, {a, c}
			; if (c)
			stmib r15, {c}
			ldmia b!, {tmp} ; b += 4
			nopl
			nopl ; Replaced with c
			dw 0
			dw .a_next
			dw 0
			dw .a_loop

		.a_next:
			ldmia b, {a}
			jump load_rom

	.up_pressed:
		; a = menu_selected_position
		; f = menu_selected_position_inv
		; if (*a-- != 0) {
		;     *f++
		;     move arrow up
		; }

		; a = *menu_selected_position
		; c = a.isZero
		ldmia a, {c}
		stmib r15, {c}
		num_dec a ; --a
		stmia ptr2, {a} ; menu_selected_position = a
		nopl ; Replaced with c
		dw 0
		dw .loop
		dw MEM_OAM
		dw $ + 4

		; Move arrow
		ldmia c, {a}
		ldmda a!, {tmp0, tmp1}
		stmia c, {a}

		; menu_selected_position_inv = ++f
		num_inc f
		stmib ptr2, {f}

		jump .loop

	.down_pressed:
		; a = menu_selected_position
		; f = menu_selected_position_inv
		; if (*f-- != 0) {
		;     *a++
		;     move arrow down
		; }

		; f = *menu_selected_position_inv
		; c = f.isZero
		ldmia f, {c}
		stmib r15, {c}
		num_dec f ; --f
		stmib ptr2, {f} ; menu_selected_position_inv = f
		nopl ; Replaced with c
		dw 0
		dw .loop
		dw MEM_OAM
		dw $ + 4

		; Move arrow
		ldmia c, {f}
		ldmia f!, {tmp0, tmp1}
		stmia c, {f}

		; menu_selected_position = ++a
		num_inc a
		stmia ptr2, {a}

		jump .loop

	jump load_rom

; Putting this in IWRAM in case I ever want to do something fancier with the objects
menu_init_objects:
	; Copy object info to OAM
	; - The arrow is a simple 16x8 object
	; - The logo is a 64x8 object that gets scaled to double its size
	dw 0xE89F81FF ; ldmia r15, {tmp0-tmp7, a, r15}
	dw 0
	; Arrow
	dh 0x6010 ; Y=16, normal, 8bpp, 16x8
	dh 0x0000 ; X=0, 16x8
	dh 0x0040 ; tile 32
	dh 0x0080 ; PA = 0.5
	; Logo
	dh 0x6300 ; Y=0, double size affine, 8bpp, 64x32
	dh 0xC038 ; X=56, matrix 1, 64x32
	dh 0x0000 ; tile 0
	dh 0x0000 ; PB = 0
	; Padding to fit the rest of the affine matrix
	times 3 dh 0x0200
	dh 0x0000 ; PC = 0
	times 3 dh 0x0200
	dh 0x0080 ; PD = 0.5
	dw MEM_OAM ; a
	dw $ + 4
	stmia a, {tmp0-tmp7}

	ret

; Also initializes menu_selected_position_inv because it's convenient
menu_display_names:
	dw 0xE89F8F00 ; ldmia r15, {a, b, c, ptr1, r15}
	dw 0
	dw toc_start ; a
	dw toc_size ; b
	dw menu_selected_position_inv ; c
	dw MEM_VRAM + 4 ; ptr1
	dw $ + 4

	ldmia b, {b}
	num_dec tmp, b
	stmia c, {tmp}
	.loop:
		; Copy name to VRAM
		ldmia a!, {ptr2}
		ldmia ptr2!, {tmp0-tmp7}
		stmia ptr1!, {tmp0-tmp7}
		ldmia ptr2!, {tmp0-tmp6}
		stmia ptr1!, {tmp0-tmp6}

		; Move VRAM pointer to next line
		ldmia ptr1!, {tmp}

		; Decrement counter
		num_dec b

		; Check if counter is 0
		ldmia b, {c}
		stmib r15, {c}
		nopl
		nopl
		nopl ; Replaced with c
		dw 0
		dw $ + 12
		dw 0
		dw .loop

	ret

; Coppied from the emulator
; Updates the value of each button and stores the edges in menu_falling_edge_keys
menu_read_input:
	; Make copy of old key values
	dw 0xE81F8400 ; ldmda r15, {c, d, r15}
	dw menu_pressed_keys
	dw $ + 4
	ldmia c, {r0-r9}
	stmdb c, {r0-r9}

	; Get input
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
		dw 0xE89FD800 ; ldmda r15, {ptr1-ptr3, r15}
		dw 0
		dw menu_pressed_keys ; ptr1
		dw menu_old_pressed_keys ; ptr2
		dw menu_falling_edge_keys ; ptr3
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

	ret

; Get the size of the menu program
menu_end:
align 32 ; Aligned to make copying easier
menu_end_aligned:
SELECT_MENU_SIZE_UNALIGNED equ (menu_end - MEM_IWRAM)
SELECT_MENU_SIZE equ (menu_end_aligned - MEM_IWRAM)

; Print info
display "Menu entry point is at 0x"
display_hex menu_start, 28
display_newline

display "Menu is 0x"
display_hex SELECT_MENU_SIZE_UNALIGNED, 16
display "/0x8000 bytes (0x"
display_hex SELECT_MENU_SIZE, 16
display " bytes in ROM)."
display_newline
