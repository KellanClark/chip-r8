; Header template modified from jsmolka
; ldm-only entry point method modified from zayd

format binary as 'gba'
processor 0xfe
coprocessor 0x0
org 0x8000000

include 'lib/constants.inc'
include 'lib/macros.s'
include 'lib/ll_number_macros.s'

gba_header:
	; Branch to starting point (4 bytes)
	;ldmib pc, {pc} ; (unconditional branch to 0x0A82843D, a convenient value obtained from the nintendo logo)
	if defined MGBA ; mGBA only allows the first instruction to be a branch
		bal 0x882843C
	else
		ldmib pc, {pc}
	end if

	; Nintendo logo (156 bytes)
	db	0x24,0xFF,0xAE,0x51,0x69,0x9A,0xA2,0x21,0x3D,0x84
	db	0x82,0x0A,0x84,0xE4,0x09,0xAD,0x11,0x24,0x8B,0x98
	db	0xC0,0x81,0x7F,0x21,0xA3,0x52,0xBE,0x19,0x93,0x09
	db	0xCE,0x20,0x10,0x46,0x4A,0x4A,0xF8,0x27,0x31,0xEC
	db	0x58,0xC7,0xE8,0x33,0x82,0xE3,0xCE,0xBF,0x85,0xF4
	db	0xDF,0x94,0xCE,0x4B,0x09,0xC1,0x94,0x56,0x8A,0xC0
	db	0x13,0x72,0xA7,0xFC,0x9F,0x84,0x4D,0x73,0xA3,0xCA
	db	0x9A,0x61,0x58,0x97,0xA3,0x27,0xFC,0x03,0x98,0x76
	db	0x23,0x1D,0xC7,0x61,0x03,0x04,0xAE,0x56,0xBF,0x38
	db	0x84,0x00,0x40,0xA7,0x0E,0xFD,0xFF,0x52,0xFE,0x03
	db	0x6F,0x95,0x30,0xF1,0x97,0xFB,0xC0,0x85,0x60,0xD6
	db	0x80,0x25,0xA9,0x63,0xBE,0x03,0x01,0x4E,0x38,0xE2
	db	0xF9,0xA2,0x34,0xFF,0xBB,0x3E,0x03,0x44,0x78,0x00
	db	0x90,0xCB,0x88,0x11,0x3A,0x94,0x65,0xC0,0x7C,0x63
	db	0x87,0xF0,0x3C,0xAF,0xD6,0x25,0xE4,0x8B,0x38,0x0A
	db	0xAC,0x72,0x21,0xD4,0xF8,0x07

	db	':3UwU:3oWo:3' ; Game title (12 bytes)
	db	':3:3'		; Game code (4 bytes)
	db	':3'		; Maker code (2 bytes)
	db	0x96		; Fixed (1 byte)
	db	0x00		; Unit code (1 byte)
	db	0x80		; Device type (1 byte)
	db	0,0,0,0,0,0,0	; Unused (7 bytes)
	db	0x69		; Game version (1 byte)
	db	0x84		; Complement (1 byte)
	db	0,0		; Reserved (2 bytes)

; Calculate header complement byte
; Algorithm from GBATEK:
;   chk=0:for i=0A0h to 0BCh:chk=chk-[i]:next:chk=(chk-19h) and 0FFh
chk = 0
repeat 0x1D
	load val byte from (0x80000A0 + % - 1)
	chk = (chk - val) and 0xFF
end repeat
chk = (chk - 0x19) and 0xFF
store byte chk at 0x80000BD

display "Header Complement Byte: 0x"
display_hex chk, 8
display_newline
display_newline

org MEM_IWRAM
include 'iwram/selectmenu.s'
org 0x80000C0 + SELECT_MENU_SIZE

org MEM_IWRAM
include 'iwram/emulator.s'
org 0x80000C0 + SELECT_MENU_SIZE + EMULATOR_SIZE

include 'main.s'

; Pad with 0 until nintendo_logo is located at 0x882843C
times ((0x882843C - $ - (20 * 4)) / 4) dw 0

; Important values/addresses needed by the loader script
dw true
dw false
dw number_0
dw NUMBER_SIZE
dw emu_unmapped_key
dw emu_pressed_keys
ldmda ptr1, {tmp1-tmp7, a}
ldmda ptr1, {tmp0-tmp7}
ldmda ptr2, {tmp1-tmp7, a}
ldmda ptr2, {tmp0-tmp7}
ldmda ptr2!, {tmp}
nopl
ret
stmib ptr3, {ptr2}
dw handler_BXNN_quirky
dw handler_BNNN
pop {b}
pop {b, r15}
dw 0xE89F800F ; ldmia r15, {r0-r3,r15}
ret

nintendo_logo:
	ldmdb pc, {pc}; (unconditional branch to main)
	dw main
	pop {c, r15}

toc_size: dw_number 0
toc_start:
	; Everything after this point is added by the loader script
