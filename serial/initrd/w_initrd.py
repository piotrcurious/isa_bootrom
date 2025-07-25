import serial
import struct

PORT = "/dev/ttyUSB0"
BAUD = 115200

ENTRY  = 0x100000
LOAD   = 0x100000
CMD    = "root=/dev/ram0 console=ttyS0"
INITRD = "initrd.img"
KERNEL = "vmlinuz"

with open(KERNEL, "rb") as f:
    kernel = f.read()

with open(INITRD, "rb") as f:
    initrd = f.read()

cmdline = CMD.encode("ascii") + b'\x00'
kernel_with_cmd = kernel + cmdline
cmd_ptr = LOAD + len(kernel)

header = struct.pack(
    "<IIIIII",
    ENTRY,              # entry_point
    LOAD,               # load_address
    len(kernel_with_cmd), # payload size
    cmd_ptr,            # cmdline ptr
    0x200000,           # initrd load addr
    len(initrd)         # initrd size
)

assert len(header) == 24

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    while True:
        if ser.read(1) == b'B':
            break
    print("Sending header + kernel + initrd...")
    ser.write(header)
    ser.write(kernel_with_cmd)
    ser.write(initrd)
