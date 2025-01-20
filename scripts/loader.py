# Script to easily assemble the rom and include a list of CHIP-8 games

# To reduce confusion, I try to distinguish between the GBA and CHIP-8 by using slightly different terminology
# - "rom" refers to the GBA ROM that is being created/modified
# - "game" refers to the user-specified CHIP-8 ROMs
# - "button" refers to physical buttons on the GBA
# - "key" refers to buttons on the CHIP-8's keypad

MAX_GAMES = 18

import argparse
import hashlib
import json
import os
import struct
import subprocess

# Get command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('-o', '--outfile', default='chip-r8.gba')
parser.add_argument('--on', type=int, help='Replace the default white with a BGR555 color value')
parser.add_argument('--off', type=int, help='Replace the default black with a BGR555 color value')
parser.add_argument('-p', '--pattern', help='Instead of a solid color, use a bitmap image for the on pixels')
parser.add_argument('--waitcnt', type=int, help='Set the WAITCNT register to a custom value (default 0x4317)')
parser.add_argument('--intmemcnt', type=int, help='Set the undocumented memory control register to a custom value (default 0x0D000020)')
parser.add_argument('--mgba', action='store_true', help='Use a branch for the first instruction so the rom appears valid to mGBA')
parser.add_argument('games', action='extend', nargs='+', help='A list of CHIP-8 game files you want to encode into the rom')
args = parser.parse_args()

if len(args.games) > MAX_GAMES:
	print('ERROR: Too many games provided (max ' + MAX_GAMES + ')')
	exit()

# Remove the old rom so everything fails if there's an assember error
if os.path.exists(args.outfile):
	print('[ Removing Old ROM ]')
	os.remove(args.outfile)

# Assemble the rom
print('[ Assembling ROM ]')
fasm_args = ['./FASMARM/fasmarm.exe' if os.name == 'nt' else './FASMARM/fasmarm', './src/header.s', args.outfile]
if args.on:
	fasm_args.append('-D')
	fasm_args.append('ON_COLOR_D=' + str(args.on))
if args.off:
	fasm_args.append('-D')
	fasm_args.append('OFF_COLOR_D=' + str(args.off))
if args.pattern:
	with open('./src/lib/bmp_file_name.s', mode='w') as bmp_file_name_s:
		# Find a relative path from bmp_file_name.s to the given file
		pattern_path = os.path.relpath(os.path.abspath(args.pattern), start='./src/lib/')
		bmp_file_name_s.write('file \"' + pattern_path + '\"')

		fasm_args.append('-D')
		fasm_args.append('USE_BMP_PATTERN=1')
if args.waitcnt:
	fasm_args.append('-D')
	fasm_args.append('WAITCNT=' + str(args.waitcnt))
if args.intmemcnt:
	fasm_args.append('-D')
	fasm_args.append('INTMEMCNT=' + str(args.intmemcnt))
if args.mgba:
	fasm_args.append('-D')
	fasm_args.append('MGBA=1')
subprocess.run(fasm_args)

rom_file = open(args.outfile, "r+b")

# Run postprocessing script
print('[ Reversing FASMARM LDM/STM to LDR/STR Optimizations ]')
import unoptimize
unoptimize.unoptimize(rom_file)

# Load the game database
with open('scripts/chip-8-database/database/programs.json', 'r', encoding="utf-8") as file:
	database_programs = json.load(file)
with open('scripts/chip-8-database/database/sha1-hashes.json', 'r', encoding="utf-8") as file:
	database_hashes = json.load(file)
with open('scripts/chip-8-database/database/platforms.json', 'r', encoding="utf-8") as file:
	database_platforms = json.load(file)
with open('scripts/chip-8-database/database/quirks.json', 'r', encoding="utf-8") as file:
	database_quirks = json.load(file)

# Get important values/addresses
print('[ Grabbing Values From ROM ]')
rom_file.seek(0x82843C - (20 * 4))

def read_word():
	return struct.unpack('<I', rom_file.read(4))[0]

true_value = read_word()
false_value = read_word()
number_table = read_word()
number_size = read_word()
unmapped_key = read_word()
key_status = read_word()
quirks_shift_true_1 = read_word()
quirks_shift_true_2 = read_word()
quirks_shift_false_1 = read_word()
quirks_shift_false_2 = read_word()
quirks_memoryIncrementByX_true = read_word()
quirks_memoryIncrementByX_false = read_word()
quirks_memoryLeaveIUnchanged_true = read_word()
quirks_memoryLeaveIUnchanged_false = read_word()
quirks_jump_true = read_word()
quirks_jump_false = read_word()
quirks_vblank_true = read_word()
quirks_vblank_false = read_word()
quirks_logic_true = read_word()
quirks_logic_false = read_word()

print("True Value: " + hex(true_value))
print("False Value: " + hex(false_value))
print("Number Table Address: " + hex(number_table))
print("Number Size: " + str(number_size))
print("Unmapped Key Value: " + hex(unmapped_key))
print("Key Status Address: " + hex(key_status))
print("Shift Quirk True Value 1:" + hex(quirks_shift_true_1))
print("Shift Quirk True Value 2:" + hex(quirks_shift_true_2))
print("Shift Quirk False Value 1:" + hex(quirks_shift_false_1))
print("Shift Quirk False Value 2:" + hex(quirks_shift_false_2))
print("L/S Quirk 1 True Value: " + hex(quirks_memoryIncrementByX_true))
print("L/S Quirk 1 False Value: " + hex(quirks_memoryIncrementByX_false))
print("L/S Quirk 2 True Value: " + hex(quirks_memoryLeaveIUnchanged_true))
print("L/S Quirk 2 False Value: " + hex(quirks_memoryLeaveIUnchanged_false))
print("Jump Quirk True Value: " + hex(quirks_jump_true))
print("Jump Quirk False Value: " + hex(quirks_jump_false))
print("vBlank Quirk True Value: " + hex(quirks_vblank_true))
print("vBlank Quirk False Value: " + hex(quirks_vblank_false))
print("vF Reset Quirk True Value: " + hex(quirks_logic_true))
print("vF Reset Quirk False Value: " + hex(quirks_logic_false))

# Count number of roms and leave space for the TOC
rom_file.seek(0x82843C + 12)
rom_file.write(struct.pack('<I', number_table + 4 + (number_size * len(args.games))))
toc_ptr = rom_file.tell()
rom_file.seek(4 * len(args.games), 1)

# Load each game into the rom
for game in args.games:
	print('[ Loading ' + game + ' ]')

	# Read the file
	with open(game, 'rb') as game_file:
		game_data = game_file.read()

	# Default information
	game_name = os.path.basename(game) # TODO: This function isn't a consistent way of extracting the file name
	quirks = {}
	for quirk in database_quirks:
		quirks[quirk["id"]] = quirk["default"]
	key_map = [-1]*16

	# Compute its SHA1 hash
	game_hash = hashlib.sha1(game_data, usedforsecurity=False).hexdigest()
	print("\tSHA1 hash is " + game_hash)

	# Try to look up game information in the database
	if game_hash in database_hashes:
		game_index = database_hashes[game_hash]
		print("\tGame found in database. Index: " + str(game_index))
		metadata = database_programs[game_index]
		entry = metadata["roms"][game_hash]

		# Get title
		if "title" in metadata:
			game_name = metadata["title"]
		elif "file" in entry:
			game_name = entry["file"]

		# Select the prefered platform
		game_platform = ""
		supported_platfroms = ["originalChip8", "modernChip8", "chip48"]
		print("\tEmulator Supported Platforms: " + str(supported_platfroms))
		print("\tGame Supported Platforms: " + str(entry["platforms"]))
		for platform in entry["platforms"]:
			if platform in supported_platfroms:
				game_platform = platform
				break
		if game_platform == "":
			print("\tERROR: Platform(s) not supported")
			exit()
		print("\tChosen Platform: " + game_platform)

		# Grab quirks for platform
		for platform in database_platforms:
			if platform["id"] == game_platform:
				for quirk in platform["quirks"]:
					quirks[quirk] = platform["quirks"][quirk]
				break

		# Look for any game-specific quirks
		if "quirkyPlatforms" in entry:
			if platform in entry["quirkyPlatforms"]:
				for quirk in entry["quirkyPlatforms"][platform]:
					quirks[quirk] = entry["quirkyPlatforms"][platform][quirk]

		# Try to make a working keymap from this limited information and buttons
		unasigned_buttons = list(range(10))
		if "keys" in entry:
			db_keys = entry["keys"]

			# Player 1 buttons are normal
			if "up" in db_keys:
				key_map[db_keys["up"]] = 6
				unasigned_buttons.remove(6)
			if "down" in db_keys:
				key_map[db_keys["down"]] = 7
				unasigned_buttons.remove(7)
			if "left" in db_keys:
				key_map[db_keys["left"]] = 5
				unasigned_buttons.remove(5)
			if "right" in db_keys:
				key_map[db_keys["right"]] = 4
				unasigned_buttons.remove(4)
			if "a" in db_keys:
				key_map[db_keys["a"]] = 0
				unasigned_buttons.remove(0)
			if "b" in db_keys:
				key_map[db_keys["b"]] = 1
				unasigned_buttons.remove(1)

			# There aren't enough buttons to map all of player 2
			# Luckily that's not a huge deal because the database only actually uses player2Up and player2Down
			# For now, I'm going to make up this mapping that's somewhat biased towards people playing on an emulator with a keyboard
			#   Up & Left -> Select
			#   Down & Right -> Start
			#   A -> R
			#   B -> L
			if "player2Up" in db_keys:
				key_map[db_keys["player2Up"]] = 2
				unasigned_buttons.remove(2)
			if "player2Down" in db_keys:
				key_map[db_keys["player2Down"]] = 3
				unasigned_buttons.remove(3)
			if "player2Left" in db_keys:
				key_map[db_keys["player2Left"]] = 2
				unasigned_buttons.remove(2)
			if "player2Right" in db_keys:
				key_map[db_keys["player2Right"]] = 3
				unasigned_buttons.remove(3)
			if "player2A" in db_keys:
				key_map[db_keys["player2A"]] = 8
				unasigned_buttons.remove(8)
			if "player2B" in db_keys:
				key_map[db_keys["player2B"]] = 9
				unasigned_buttons.remove(9)
		# Try to fill in unmapped keys with random unused buttons
		for i in range(16):
			if len(unasigned_buttons) == 0:
				break

			if key_map[i] == -1:
				key_map[i] = unasigned_buttons[0]
				unasigned_buttons.pop(0)
	else:
		print("\tGame not found in database. Using defaults.")

		for i in range(16):
			if i >= 10:
				key_map[i] = -1 # Unmapped
			else:
				key_map[i] = i # Position in KEYINPUT

	# Put a pointer to this data in the TOC
	game_ptr = rom_file.tell()
	rom_file.seek(toc_ptr)
	rom_file.write(struct.pack('<I', game_ptr + 0x8000000))
	toc_ptr = rom_file.tell()
	rom_file.seek(game_ptr)

	# Insert game title into the rom
	game_name = '{:28.28}'.format(game_name) # Pad/truncate the name to 28 characters
	print("\tName: " + game_name)
	for char in game_name:
		rom_file.write(struct.pack('<H', ord(char)))

	# Insert keymap into the rom
	print("\tKeymap:")
	for i in range(16):
		# Convert into usable addresses
		if key_map[i] == -1:
			rom_file.write(struct.pack('<I', unmapped_key)) # Unmapped
		else:
			rom_file.write(struct.pack('<I', key_status + (key_map[i] * 4))) # Position in KEYINPUT

		# Print it out
		key_name = "Unmapped"
		match key_map[i]:
			case 0:
				key_name = "A"
			case 1:
				key_name = "B"
			case 2:
				key_name = "Select"
			case 3:
				key_name = "Start"
			case 4:
				key_name = "Right"
			case 5:
				key_name = "Left"
			case 6:
				key_name = "Up"
			case 7:
				key_name = "Down"
			case 8:
				key_name = "R"
			case 9:
				key_name = "L"

		print(f'\t\t{i:X} -> {key_name}')

	# Insert quirk patch values into the rom
	print("\tQuirks:")
	print("\t\tShift quirk = " + str(quirks["shift"]))
	print("\t\tL/S: Increment index register by X = " + str(quirks["memoryIncrementByX"]))
	print("\t\tL/S: Leave index register unchanged = " + str(quirks["memoryLeaveIUnchanged"]))
	print("\t\tWrap quirk (UNSUPPORTED) = " + str(quirks["wrap"]))
	print("\t\tJump quirk = " + str(quirks["jump"]))
	print("\t\tvBlank quirk = " + str(quirks["vblank"]))
	print("\t\tvF reset quirk = " + str(quirks["logic"]))
	if quirks["shift"]:
		rom_file.write(struct.pack('<I', quirks_shift_true_1))
		rom_file.write(struct.pack('<I', quirks_shift_true_2))
	else:
		rom_file.write(struct.pack('<I', quirks_shift_false_1))
		rom_file.write(struct.pack('<I', quirks_shift_false_2))
	rom_file.write(struct.pack('<I', quirks_memoryIncrementByX_true if quirks["memoryIncrementByX"] else quirks_memoryIncrementByX_false))
	rom_file.write(struct.pack('<I', quirks_memoryLeaveIUnchanged_true if quirks["memoryLeaveIUnchanged"] else quirks_memoryLeaveIUnchanged_false))
	#
	rom_file.write(struct.pack('<I', quirks_jump_true if quirks["jump"] else quirks_jump_false))
	rom_file.write(struct.pack('<I', quirks_vblank_true if quirks["vblank"] else quirks_vblank_false))
	rom_file.write(struct.pack('<I', quirks_logic_true if quirks["logic"] else quirks_logic_false))

	# Insert game data into the rom
	for byte in game_data:
		for bit in range(8):
			if ((byte >> (7 - bit)) & 1) == 1:
				rom_file.write(struct.pack('<I', true_value))
			else:
				rom_file.write(struct.pack('<I', false_value))

	# Pad game to 3584 bytes
	for i in range((3584 - len(game_data)) * 8):
		rom_file.write(struct.pack('<I', false_value))

rom_file.close()
