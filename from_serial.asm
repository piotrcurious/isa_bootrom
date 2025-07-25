org 0x0000

start:
    ; ROM header (required for BIOS detection)
    db 0x55, 0xAA                ; BIOS signature
    db 0x10                      ; ROM size in 512-byte units (0x10 = 8 KiB)

    jmp init                     ; Entry point at byte 3

    times 0x03 - ($-$$) db 0     ; Padding

init:
    cli
    call init_serial

    ; Send boot request signal (e.g., ASCII 'B')
    mov al, 'B'
    call send_byte

    ; Wait for data to start coming in
wait_for_data:
    call recv_byte
    mov [es:di], al              ; Begin storing at 0x0000:0x7C00
    inc di
    call recv_bytes_loop         ; Receive the rest

    jmp 0x0000:0x7C00            ; Jump to loaded code

; ---------------------------------------
; Serial I/O: COM1 (0x3F8 base)
; ---------------------------------------

COM_PORT       equ 0x3F8
DATA_REG       equ COM_PORT + 0
LCR_REG        equ COM_PORT + 3
LSR_REG        equ COM_PORT + 5
DLL_REG        equ COM_PORT + 0
DLM_REG        equ COM_PORT + 1
IER_REG        equ COM_PORT + 1

init_serial:
    mov dx, LCR_REG
    mov al, 0x80                 ; Enable DLAB
    out dx, al

    mov dx, DLL_REG
    mov al, 0x01                 ; 115200 baud
    out dx, al
    mov dx, DLM_REG
    xor al, al
    out dx, al

    mov dx, LCR_REG
    mov al, 0x03                 ; 8N1
    out dx, al

    ret

send_byte:
    push dx
.wait:
    mov dx, LSR_REG
    in al, dx
    test al, 0x20                ; Transmit holding empty?
    jz .wait
    mov dx, DATA_REG
    out dx, al
    pop dx
    ret

recv_byte:
    push dx
.wait:
    mov dx, LSR_REG
    in al, dx
    test al, 0x01                ; Data ready?
    jz .wait
    mov dx, DATA_REG
    in al, dx
    pop dx
    ret

recv_bytes_loop:
    ; ES:DI points to 0x0000:0x7C01 now, we've already stored one byte
    ; Receive 65536 - 1 = 65535 more bytes
    mov cx, 0xFF00               ; Load in chunks
.more:
    call recv_byte
    mov [es:di], al
    inc di
    loop .more
    mov cx, 0x0100
.more2:
    call recv_byte
    mov [es:di], al
    inc di
    loop .more2
    ret

; ---------------------------------------
; Reserve space and pad ROM to 8 KiB
; ---------------------------------------
times 0x7C00 - ($-$$) db 0       ; Reserve space before payload copy
times 8192 - ($-$$) db 0         ; Pad ROM to 8 KiB
