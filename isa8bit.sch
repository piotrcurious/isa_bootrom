EESchema Schematic File Version 4
LIBS:device
LIBS:74xx
LIBS:memory
LIBS:power
LIBS:isa_rom_card-rescue
EELAYER 25 0
EELAYER END
$Descr A4 11700 8267
encoding utf-8
Sheet 1 1
Title "ISA Boot ROM Card"
Date "2025-07-25"
Rev "1.0"
Comp ""
Comment1 "ISA Option ROM Card with 27C512 EEPROM (PLCC)"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr

$Comp
L power:+5V #PWR01
U 1 1 61000001
P 1000 1000
F 0 "#PWR01" H 1000 850 50  0001 C CNN
F 1 "+5V" H 1015 1173 50  0000 C CNN
F 2 "" H 1000 1000 50  0001 C CNN
F 3 "" H 1000 1000 50  0001 C CNN
	1    1000 1000
	1    0    0    -1
$EndComp

$Comp
L power:GND #PWR02
U 1 1 61000002
P 1000 2000
F 0 "#PWR02" H 1000 1750 50  0001 C CNN
F 1 "GND" H 1005 1827 50  0000 C CNN
F 2 "" H 1000 2000 50  0001 C CNN
F 3 "" H 1000 2000 50  0001 C CNN
	1    1000 2000
	1    0    0    -1
$EndComp

$Comp
L Memory_EEPROM:27C512 U1
U 1 1 61000003
P 4000 3000
F 0 "U1" H 4000 4250 50  0000 C CNN
F 1 "27C512" H 4000 4100 50  0000 C CNN
F 2 "Package_PLCC:PLCC-32_THT-Socket" H 4000 3000 50  0001 C CNN
F 3 "" H 4000 3000 50  0001 C CNN
	1    4000 3000
	1    0    0    -1
$EndComp

$Comp
L 74xx:74LS138 U2
U 1 1 61000004
P 7000 3000
F 0 "U2" H 7000 3600 50  0000 C CNN
F 1 "74LS138" H 7000 3500 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 7000 3000 50  0001 C CNN
F 3 "" H 7000 3000 50  0001 C CNN
	1    7000 3000
	1    0    0    -1
$EndComp

$Comp
L Connector_Generic:Conn_Edge_ISA_8bit J1
U 1 1 61000005
P 1500 3000
F 0 "J1" H 1500 4800 50  0000 C CNN
F 1 "ISA_EDGE" H 1500 4700 50  0000 C CNN
F 2 "Connector_ISA:ISA8_Edge" H 1500 3000 50  0001 C CNN
F 3 "" H 1500 3000 50  0001 C CNN
	1    1500 3000
	1    0    0    -1
$EndComp

# Connections from J1 to U1 and U2 not all fully shown here for brevity.
# Key routing:
#  - SA0–SA15 -> A0–A15 on U1
#  - SA16–SA18 -> U2 inputs A/B/C for decoding
#  - MEMR + AEN = decoder enable condition
#  - Decoder output (e.g., Y0) -> CE# on U1
#  - MEMR -> OE# on U1
#  - SD0–SD7 <-> Q0–Q7 (bi-directional bus)

$EndSCHEMATC
