import sys

def writeComplement(file):
	file.seek(0)
	headerData = list(file.read(0xC0))

	complement = bytearray([0])
	for i in range(0xA0, 0xBD):
		complement[0] = (complement[0] - headerData[i]) & 0xFF
	complement[0] = (complement[0] - 0x19) & 0xFF

	file.seek(0xBD)
	file.write(complement)
	print("Wrote complement value " + hex(complement[0]) + " to header")
	return complement[0]

if __name__ == "__main__":
	if len(sys.argv) >= 2:
		with open(sys.argv[1], "r+b") as file:
			complement = writeComplement(file)
	else:
		print("Error: Not enough arguments")
