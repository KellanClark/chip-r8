; Lookup tables and associated macro stuff needed for DXYN

if defined ON_COLOR_D
	ON_COLOR = ((ON_COLOR_D and 0xFFFF) shl 16) or (ON_COLOR_D and 0xFFFF)
else
	ON_COLOR = 0xFFFFFFFF ; Default to white
end if

if defined OFF_COLOR_D
	OFF_COLOR = ((OFF_COLOR_D and 0xFFFF) shl 16) or (OFF_COLOR_D and 0xFFFF)
else
	OFF_COLOR = 0x00000000 ; Default to black
end if

if defined USE_BMP_PATTERN
	include '../lib/bmp_loader.s'
end if


macro dw_dxyn_entry x, y {
	dw dxyn_entries + 24 * ((y) * 65 + (x))
}

; +0 = Y in bounds
; +4 = Next line pointer
; +8 = On color
; +12 = X in bounds
; +16 = Framebuffer pointer
; +20 = VRAM pointer
dxyn_entries:
repeat 33
	y = % - 1
	repeat 65
		x = % - 1

		; Y in bounds
		if y < 32
			dw true
		else
			dw false
		end if

		; Next line pointer
		if x <= 24
			dw_dxyn_entry x, (y + 1)
		else
			dw_dxyn_entry x, (y + 1)
		end if

		; On color
		; Ok so I might've rewritten DXYN to use this dumb table system for a dumb pride flag joke
		; Then I might've rewritten it again and made a bitmap file parser with macros so I could make it amogus
		; Thanks to https://www.flagcolorcodes.com/flags/pride for the pride flag color codes
		if defined USE_BMP_PATTERN ; Colors loaded from bitmap file
			if (y < 32) & (x < 64)
				load pix hword from bmp_output:((64 * y + x) * 2)
				dw pix or (pix shl 16)
			else
				dw 0
			end if
		else ; Solid color
			dw ON_COLOR
		end if

		; X in bounds
		if x < 64
			dw true
		else
			dw false
		end if

		; Frambuffer pointer
		dw FRAMEBUFFER_START + (y * 64 * 4) + (x * 4)

		; VRAM pointer
		dw MEM_VRAM + (y * 160 * 2) + (x * 4)
	end repeat
end repeat

dxyn_ofs_to_entry:
repeat 32
	y = % - 1
	repeat 64
		x = % - 1
		dw_dxyn_entry x, y
	end repeat
end repeat
