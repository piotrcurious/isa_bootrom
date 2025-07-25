import serial
import struct

PORT = "/dev/ttyUSB0"
BAUD = 115200
ENTRY = 0x100000         # Target entry point
LOAD  = 0x100000         # Where to load it
CMD   = "console=ttyS0 root=/dev/ram0"

payload = open("vmlinuz.bin", "rb").read()
cmd_bytes = CMD.encode('ascii') + b'\x00'

# We append command line string after payload
load_image = payload + cmd_bytes

# Pointer to cmdline in memory (after payload)
cmd_ptr = LOAD + len(payload)

header = struct.pack("<IIII", ENTRY, LOAD, len(load_image), cmd_ptr)

assert len(load_image) < 512 * 1024

with serial.Serial(PORT, BAUD) as ser:
    while True:
        if ser.read(1) == b'B':
            break

    ser.write(header)
    ser.write(load_image)
