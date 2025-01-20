offset_to_address_table:
repeat 4096
	dw C8MEM_START + ((% - 1) * 32)
end repeat

offset_to_vram_table:
repeat 32
	line = % - 1
	repeat 64
		dw MEM_VRAM + (line * 320) + ((% - 1) * 4)
	end repeat
end repeat

; +0 = BCD hundreds digit
; +4 = BCD tens digit
; +8 = BCD ones digit
offset_to_bcd_table:
repeat 256
	dw bcd_table + ((% - 1) * 12)
end repeat

bcd_table:
repeat 256
	dw bin_constants + (((% - 1) / 100) * 32)
	dw bin_constants + ((((% - 1) / 10) mod 10) * 32)
	dw bin_constants + (((% - 1) mod 10) * 32)
end repeat
