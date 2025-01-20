; CHIP-8 emulator variables
; Located at the beginning of IWRAM to make debugging easier

C8MEM_START = MEM_EWRAM
;FRAMEBUFFER_START = MEM_EWRAM + 0x20000
FRAMEBUFFER_START = MEM_VRAM + 0xA000
;INSTRUCTIONS_PER_FRAME = 9 ; 540 Hz
INSTRUCTIONS_PER_FRAME = 12

; General purpose registers
reg_V0: times 8 dw false
reg_V1: times 8 dw false
reg_V2: times 8 dw false
reg_V3: times 8 dw false
reg_V4: times 8 dw false
reg_V5: times 8 dw false
reg_V6: times 8 dw false
reg_V7: times 8 dw false
reg_V8: times 8 dw false
reg_V9: times 8 dw false
reg_VA: times 8 dw false
reg_VB: times 8 dw false
reg_VC: times 8 dw false
reg_VD: times 8 dw false
reg_VE: times 8 dw false
reg_VF: times 8 dw false

; Special registers
reg_PC: dw C8MEM_START + (0x200 * 8 * 4) ; PC starts pointing to address 0x200
reg_I: dw C8MEM_START ; I starts pointing to address 0
reg_SP: dw stack_start

; Timers
instruction_timer: dw_number 0
delay_timer: dw_number 0
sound_timer: dw_number 0

emu_old_pressed_keys:
	times 10 dw false
emu_unmapped_key:
	dw false
emu_pressed_keys:
	times 10 dw false
dw false ; I'm too lazy to fix the keymap loader properly
emu_falling_edge_keys:
	times 10 dw false

keymap:
	times 16 dw emu_unmapped_key ; Unmapped
keymap_edge:
	times 16 dw emu_unmapped_key ; Unmapped

stack_start:
	times 12 dw C8MEM_START
