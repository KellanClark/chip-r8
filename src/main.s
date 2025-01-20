include 'tables/ll_numbers.s'
include 'tables/ascii_tiles.s'
include 'tables/font.s'
include 'tables/dxyn_luts.s'
include 'tables/misc_tables.s'

literal_pool:
	; Set up interrupts
	dw REG_IME
	dw 0x00000000 ; Disable interrupts
	dw REG_IE
	dw 0xFFFF0000 ; Clear IF
	dw REG_KEYINPUT
	dw 0xC0000000 ; Trigger a keypad interrupt
	dw REG_DMA3SAD
	dw 0
	dw 0
	dh 1
	dh DMACNT_H_IMMEDIATELY or DMACNT_H_IRQ or DMACNT_H_ENABLE ; Trigger a DMA 3 interrupt

	; Set up timers
	dw REG_TM0CNT_L
	dh 0x0000
	dh TMCNT_H_DIV_1 or TMCNT_H_START ; Really fast counter used for RNG
	dh 0xFFFF
	dh TMCNT_H_DIV_1 or TMCNT_H_IRQ or TMCNT_H_START ; Constantly trigger Timer 1 interrupts
	; Timer 0 is the source of randomness, so I want to get it running as early as possible

	; Set the speed of ROM and EWRAM
	dw REG_WAITCNT
	if defined WAITCNT
		dw WAITCNT
	else
		dw 0x4317 ; This should be a safe value that all commercial cartridges use
	end if
	dw REG_INTMEMCNT
	if defined INTMEMCNT
		dw INTMEMCNT
	else
		dw 0x0D000020 ; Another safe value. 0x0E000020 is faster but apparently doesn't work on the GBA Micro
	end if

	; Set up sound registers
	dw REG_SOUND2CNT_L
	dw 0xF080 ; 50% duty cycle, no envelope
	dw 0x877D ; ~1000 Hz
	dw REG_SOUNDCNT_L
	dw 0x00020077 ; Disable all channels
	dw 0x80

	; Set up graphics registers
	dw REG_DISPCNT
	dw DISPCNT_BGMODE0 or DISPCNT_OBJ_1D or DISPCNT_DISPLAY_BG0 or DISPCNT_DISPLAY_OBJ
	dw REG_BG0CNT
	dw BGCNT_CB3 or BGCNT_8BIT or BGCNT_SB0 or BGCNT_256x256
	dw REG_BG0HOFS
	dh 0 ; No X scroll
	dh 0xFFF0 ; Move the screen down 16 pixels
	dw MEM_PALETTE
	dw MEM_PALETTE_OBJ
	dh 0x0000 ; Black
	dh 0xFFFF ; White

	; Copy tiles to charblocks 3 and 4
	dw ascii_tiles_start
	dw MEM_VRAM_OBJ ; Squeezing in the logo with this block
	dw MEM_VRAM_OBJ + 0x800
	dw MEM_VRAM + (0x4000 * 3) + 0x800

	; Clear OAM
	times 16 dh 0x0200
	dw MEM_OAM

	; Copy select menu program to IWRAM
	dw 0x80000C0
	dw MEM_IWRAM

	; Set stack pointer and jump to menu program
	dw MEM_IWRAM + 0x80000 ; Point to to the end of IWRAM
	dw menu_start

main:
	; Initialize literal pool pointer
	dw 0xE81FA000 ; ldmda r15, {r13, r15}
	dw literal_pool
	dw $ + 4

	; Set up interrupts
	pop {r0-r9}
	stmia r0, {r1}
	stmia r2, {r3}
	stmia r4, {r5}
	stmia r6, {r7-r9}

	; Set up timers
	pop {r0-r2}
	stmia r0, {r1, r2}

	; Set the speed of ROM and EWRAM
	pop {r0-r3}
	stmia r0, {r1}
	stmia r2, {r3}

	; Set up sound registers
	pop {r0-r5}
	stmib r3, {r5} ; SOUNDCNT_X must be enabled before anything else can be written to
	stmia r0, {r1, r2}
	stmia r3, {r4}

	; Set up graphics registers
	pop {r0-r8}
	stmia r0, {r1}
	stmia r2, {r3}
	stmia r4, {r5}
	stmia r6, {r8}
	stmia r7, {r8}

	; Copy tiles to charblocks 3 and 4
	pop {a-d}
	repeat 32
		ldmia a!, {tmp0-tmp7}
		stmia b!, {tmp0-tmp7}
	end repeat
	repeat 32
		ldmia a!, {tmp0-tmp7}
		stmia c!, {tmp0-tmp7}
	end repeat
	repeat 256 - 64
		ldmia a!, {tmp0-tmp7}
		stmia d!, {tmp0-tmp7}
	end repeat

	; Clear OAM
	pop {tmp0-tmp7, a}
	repeat 32
		stmia a!, {tmp0-tmp7}
	end repeat

	; Copy select menu program to IWRAM
	pop {a, b}
	repeat SELECT_MENU_SIZE / 32
		ldmia a!, {tmp0-tmp7}
		stmia b!, {tmp0-tmp7}
	end repeat

	; Set stack pointer and jump to menu program
	ldmia r13, {r13, r15}

; Called by the select menu when a rom has been chosen
; a = pointer to rom header
load_rom:
	; Skip over rom name
	ldmia a!, {tmp0-tmp7}
	ldmia a!, {tmp0-tmp5}
	push {a}

	dw 0xE89F8FFF ; ldmia r15, {tmp0-tmp7,a-d,r15}
	dw 0
	times 8 dw false ; tmp0-tmp7
	dw 0x80000C0 + SELECT_MENU_SIZE ; a
	dw MEM_IWRAM ; b
	dw 0 ; c
	dw C8MEM_START ; d
	dw $ + 4

	; Set 0x000 through 0x1FF to 0
	repeat 512 * 8 * 4 / 32
		stmia d!, {tmp0-tmp7}
	end repeat

	; Copy emulator to IWRAM
	repeat EMULATOR_SIZE / 32
		ldmia a!, {tmp0-tmp7}
		stmia b!, {tmp0-tmp7}
	end repeat

	; Clear the screen and initialize the framebuffer
	call emulator_clear_screen

	; Set up graphics
	dw 0xE89F83FF ; ldmia r15, {r0-r9,r15}
	dw 0
	dw REG_DISPCNT
	dw DISPCNT_BGMODE5 or DISPCNT_FRAME0 or DISPCNT_DISPLAY_BG2
	dw 0x0000 ; LYC = 0
	dw REG_BG2CNT
	dw BGCNT_AFF_TRANS
	dw REG_BG2PA
	dh 0x0100 ; PA = 1
	dh 0x0000 ; PB = 0
	dh 0x0000 ; PC = 0
	dh 0x0080 ; PD = 0.5
	dw -56 shl 8 ; X = -56
	dw -24 shl 8 ; Y = -24
	dw $ + 4

	stmia r0, {r1, r2}
	stmia r3, {r4}
	stmia r5, {r6-r9}

	; Restore rom header pointer
	pop {ptr3}

	; Patch the keymap with values from the header
	load_base keymap
	push {ptr3}
	repeat 16
		ldmia ptr3!, {a}
		stmia b!, {a}
	end repeat
	pop {ptr3}

	; Do it again but offset the pointers so they point to places in emu_falling_edge_keys instead of emu_pressed_keys
	repeat 16
		ldmia ptr3!, {a}
		ldmia a!, {tmp0-tmp5}
		ldmia a!, {tmp0-tmp4}
		stmia b!, {a}
	end repeat

	; Patch certain addresses in the emulator with values from the game's header to select quirks
	dw 0xE89F803F ; ldmia r15, {r0-r5,r15}
	dw 0
	dw handler_8XY6 ; r0
	dw handler_8XYE ; r1
	dw handler_FX55.break ; r2
	dw handler_table + 44 ; r3
	dw handler_DXYN.end ; r4
	dw logical_end ; r5
	dw $ + 4
	ldmia ptr3!, {r6-r12}

	stmia r0, {r6}
	stmia r1, {r7}
	stmia r2, {r8, r9}
	stmia r3, {r10}
	stmia r4, {r11}
	stmia r5, {r12}

	; Load rom into memory
	load_base C8MEM_START + (0x200 * 8 * 4)
	repeat (4096 - 512) * 8 * 4 / 32
		ldmia ptr3!, {tmp0-tmp7}
		stmia b!, {tmp0-tmp7}
	end repeat

	; Jump to emulator
	jump emulator_start

; This needs to be used by the emulator and I don't want to spend a quarter of IWRAM on it
emulator_clear_screen:
	; Clear VRAM
	dw 0xE89F88FF ; ldmia r15, {tmp0-tmp7, d, r15}
	nopl
	times 8 dw OFF_COLOR
	dw MEM_VRAM
	dw $ + 4

	repeat 160 * 32 * 2 / 32
		stmia d!, {tmp0-tmp7}
	end repeat

	; Clear framebuffer
	dw 0xE89F88FF ; ldmia r15, {tmp0-tmp7, d, r15}
	nopl
	times 8 dw false
	dw FRAMEBUFFER_START
	dw $ + 4

	repeat 64 * 32 / 8
		stmia d!, {tmp0-tmp7}
	end repeat

	ret
