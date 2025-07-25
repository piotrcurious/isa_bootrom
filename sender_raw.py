import serial
import time

# Settings
PORT = "/dev/ttyUSB0"
BAUD = 115200
PAYLOAD = "bootcode.bin"

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    input("Power on target. Press Enter to send boot request...")

    # Wait for request byte from target
    while True:
        if ser.read(1) == b'B':
            print("Request received!")
            break

    with open(PAYLOAD, "rb") as f:
        data = f.read()
        data += b'\x00' * (65536 - len(data))  # Pad to 64KB
        print("Sending payload...")
        for i in range(0, len(data), 1024):
            ser.write(data[i:i+1024])
            time.sleep(0.01)  # Give time to receive
            print(f"{i//1024 + 1}KB sent")

    print("Done.")
