; My attempt at loading bitmap files with macros

virtual at 0
bmp_file::
	; I can't figure out how to pass in the file name as a -D argument so we're doing this instead
	; bmp_file_name.s just contains `file "<path>"` and nothing else. The loader script can generate the contents
	include 'bmp_file_name.s'
end virtual

; Check for valid file header
load bmp_magic_number hword from bmp_file:0
if bmp_magic_number <> 0x4D42
	display "[BMP] Invalid BMP file header"
	display_newline
	err
else
	display "[BMP] Detected valid BMP file header"
	display_newline
end if

; Location of the pixel data in the header
load bmp_pixel_array word from bmp_file:10

; Only support BITMAPINFOHEADER and BITMAPVxHEADER
load bmp_dib_header_size word from bmp_file:14
if bmp_dib_header_size = 40
	display "[BMP] Detected BITMAPINFOHEADER DIB header"
	display_newline
else if bmp_dib_header_size = 52
	display "[BMP] Detected BITMAPV2INFOHEADER DIB header"
	display_newline
else if bmp_dib_header_size = 56
	display "[BMP] Detected BITMAPV3INFOHEADER DIB header"
	display_newline
else if bmp_dib_header_size = 108
	display "[BMP] Detected BITMAPV4INFOHEADER DIB header"
	display_newline
else if bmp_dib_header_size = 124
	display "[BMP] Detected BITMAPV5INFOHEADER DIB header"
	display_newline
else
	display "[BMP] Unknown or unsupported DIB header"
	display_newline
	err
end if

; Size of the image and color depth
load bmp_width word from bmp_file:18
load bmp_height word from bmp_file:22
load bmp_bpp hword from bmp_file:28

; Don't support compression
load bmp_compression word from bmp_file:30
if (bmp_compression <> 0) & (bmp_compression <> 3) & (bmp_compression <> 6)
	display "[BMP] Compressed images are not supported"
	display_newline
	err
end if

; Load bitmasks
if (bmp_compression = 3) | (bmp_compression = 6)
	load bmp_mask_r word from bmp_file:36h
	load bmp_mask_g word from bmp_file:3Ah
	load bmp_mask_b word from bmp_file:3Eh
else
	; I'm going to pretend 16, 24, and 32 BPP images all use bitmasks so I can use the same code
	if bmp_bpp = 16
		bmp_mask_r = 0x00007C00
		bmp_mask_g = 0x000003E0
		bmp_mask_b = 0x0000001F
	else
		; 24 and 32 can use the same masks because I don't care about alpha
		bmp_mask_r = 0x00FF0000
		bmp_mask_g = 0x0000FF00
		bmp_mask_b = 0x000000FF
	end if
end if

; Compute other data relating to the bitmasks
macro macro_ctz out, in {
	; Algorithm from https://graphics.stanford.edu/~seander/bithacks.html#ZerosOnRightParallel
	local v
	local c
	c = 32
	v = in and (in * -1)
	if v <> 0
		c = c - 1
	end if
	if (v and 0x0000FFFF) <> 0
		c = c - 16
	end if
	if (v and 0x00FF00FF) <> 0
		c = c - 8
	end if
	if (v and 0x0F0F0F0F) <> 0
		c = c - 4
	end if
	if (v and 0x33333333) <> 0
		c = c - 2
	end if
	if (v and 0x55555555) <> 0
		c = c - 1
	end if
	out = c
}

macro macro_popcnt out, in {
	; Algorithm from https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
	local v
	local c
	v = in
	v = (v - ((v shr 1) and 0x55555555)) and 0xFFFFFFFF
	v = ((v and 0x33333333) + ((v shr 2) and 0x33333333)) and 0xFFFFFFFF
	c = ((((v + (v shr 4)) and 0xF0F0F0F) * 0x1010101) and 0xFFFFFFFF) shr 24
	out = c
}

macro_ctz bmp_mask_shift_r, bmp_mask_r
macro_ctz bmp_mask_shift_g, bmp_mask_g
macro_ctz bmp_mask_shift_b, bmp_mask_b

macro_popcnt bmp_mask_size_r, bmp_mask_r
macro_popcnt bmp_mask_size_g, bmp_mask_g
macro_popcnt bmp_mask_size_b, bmp_mask_b

macro bmp_extract_masked_channel channel, source {
	local val
	local mask
	local mask_shift
	local mask_size

	mask = bmp_mask_#channel
	mask_shift = bmp_mask_shift_#channel
	mask_size = bmp_mask_size_#channel

	; Get channel from color
	val = (source and mask) shr mask_shift

	; Adjust until it's 5 bits
	if mask_size > 5
		val = val shr (mask_size - 5)
	else if mask_size = 4
		val = (val shl 1) or (val shr 3)
	else if mask_size = 3
		val = (val shl 2) or (val shr 1)
	else if mask_size = 2
		val = (val shl 3) or (val shl 1) or (val shr 1)
	else if mask_size = 1
		val = (val shl 4) or (val shl 3) or (val shl 2) or (val shl 1) or val
	else if mask_size = 0
		val = 0
	end if

	pix_#channel = val
}

; Find the color table
bmp_color_table = 14 + bmp_dib_header_size
if bmp_compression = 3
	bmp_color_table = bmp_compression + 12
else if bmp_compression = 6
	bmp_color_table = bmp_compression + 16
end if

if bmp_bpp >= 16
	display "[BMP] Red Mask   = "
	display_hex bmp_mask_r, bmp_bpp
	display_newline
	display "[BMP] Green Mask = "
	display_hex bmp_mask_g, bmp_bpp
	display_newline
	display "[BMP] Blue Mask  = "
	display_hex bmp_mask_b, bmp_bpp
	display_newline
else
	display "[BMP] Color Table Location = "
	display_hex bmp_color_table, 32
	display_newline
end if

; Rows get padded so they're a multiple of 4 bytes
; Equation from Wikipedia
bmp_row_stride = ((bmp_bpp * bmp_width + 31) / 32) * 4

virtual at 0
bmp_output::
	rh 32 * 64
end virtual

repeat 32
	; Data is stored left->right bottom->top so I need to keep track of where I am in the file and the buffer separately
	src_y = (% - 1 + bmp_height - (32 mod bmp_height)) mod bmp_height
	dst_y = 32 - %

	repeat 64
		src_x = (% - 1) mod bmp_width
		dst_x = % - 1
		src_addr = bmp_pixel_array + (src_y * bmp_row_stride) + (src_x * bmp_bpp / 8)
		dst_addr = (64 * dst_y + dst_x) * 2

		if bmp_bpp >= 16 ; Raw (masked) color data
			; Grab pixel from file
			load pix_src word from bmp_file:src_addr

			bmp_extract_masked_channel r, pix_src
			bmp_extract_masked_channel g, pix_src
			bmp_extract_masked_channel b, pix_src
		else ; Use color table
			load table_index byte from bmp_file:src_addr

			if bmp_bpp = 4
				table_index = (table_index shr (4 * (1 - (src_x mod 2)))) and 0xF
			else if bmp_bpp = 2
				table_index = (table_index shr (2 * (3 - (src_x mod 4)))) and 0x3
			else if bmp_bpp = 1
				table_index = (table_index shr (1 * (7 - (src_x mod 8)))) and 0x1
			end if

			load pix_src word from bmp_file:(bmp_color_table + (table_index * 4))

			pix_r = (pix_src shr 19) and 0x1F
			pix_g = (pix_src shr 11) and 0x1F
			pix_b = (pix_src shr 3) and 0x1F
		end if

		; Convert pixel to BGR555 and store in the output buffer
		pix_dst = pix_r or (pix_g shl 5) or (pix_b shl 10)
		store hword pix_dst at bmp_output:dst_addr

;		display_hex table_index, 8
;		display ":  "
;		display_hex pix_r, 8
;		display ", "
;		display_hex pix_g, 8
;		display ", "
;		display_hex pix_b, 8
;		display " -> "
;		display_hex dst_addr, 12
;		display ":  "
;		display_hex pix_dst, 16
;		display_newline
	end repeat
;	display_newline
end repeat
