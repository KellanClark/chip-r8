; Numbers implemented as a linked list and all associated tables

NUMBER_SIZE = 20

;Fields:
; +0  = next lowest number
; +4  = is zero
; +8  = can play sound
; +12 = binary representation
; +16 = next highest number
number_0:
repeat 256
	val = % - 1
	if val = 0
		dw_number 0
	else
		dw_number val - 1
	end if

	if val = 0
		dw true
	else
		dw false
	end if

	if val >= 2
		dw true
	else
		dw false
	end if

	dw bin_constants + (val * 32)

	if val = 255
		dw_number 255
	else
		dw_number val + 1
	end if
end repeat
; Note: The emulator only uses the first 4 fields. The ability to increment was only added for the rom select menu where it isn't a performance concern anyway.

; Binary representations of every 8-bit number
; Needed to convert from linked list numbers to binary numbers
bin_constants:
repeat 256
	val = % - 1
	repeat 8
		if ((val shr (8 - %)) and 1) = 1
			dw true
		else
			dw false
		end if
	end repeat
end repeat

; Table for converting from binary numbers to linked list numbers
offset_to_number_table:
repeat 256
	dw number_0 + ((% - 1) * NUMBER_SIZE) + 4
end repeat
