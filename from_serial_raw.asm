org 0x0000

start:
    ; ROM Header (55AA + size = 0x10 = 8 KiB)
    db 0x55, 0xAA
    db 0x10
    jmp init
    times 0x03 - ($-$$) db 0     ; Padding

init:
    cli
    xor ax, ax
    mov es, ax
    mov di, 0x7C00               ; Destination: 0x0000:0x7C00

    call init_serial

    ; Display startup message
    mov si, bootmsg
    call print_str

    ; Send request character
    mov al, 'B'
    call send_byte

    ; Wait for and receive 64 KiB
    call recv_byte              ; First byte
    stosb
    mov cx, 65535
    call recv_loop

    ; Jump to 0x7C00
    jmp 0x0000:0x7C00

; -------------------------------
; Serial I/O (COM1 base = 0x3F8)
; -------------------------------
COM1         equ 0x3F8
DATA_REG     equ COM1 + 0
LCR_REG      equ COM1 + 3
LSR_REG      equ COM1 + 5
DLL_REG      equ COM1 + 0
DLM_REG      equ COM1 + 1

init_serial:
    mov dx, LCR_REG
    mov al, 0x80                ; Enable DLAB
    out dx, al

    mov dx, DLL_REG
    mov al, 0x01                ; 115200 baud divisor LSB
    out dx, al
    mov dx, DLM_REG
    xor al, al                  ; Divisor MSB = 0
    out dx, al

    mov dx, LCR_REG
    mov al, 0x03                ; 8N1
    out dx, al
    ret

send_byte:
    push dx
.wait_tx:
    mov dx, LSR_REG
    in al, dx
    test al, 0x20
    jz .wait_tx
    mov dx, DATA_REG
    out dx, al
    pop dx
    ret

recv_byte:
    push dx
.wait_rx:
    mov dx, LSR_REG
    in al, dx
    test al, 0x01
    jz .wait_rx
    mov dx, DATA_REG
    in al, dx
    pop dx
    ret

recv_loop:
    push ax
    push cx
    push si

    mov si, 0                   ; progress counter

.recv_next:
    call recv_byte
    stosb

    inc si
    cmp si, 1024
    jne .skip_print
    xor si, si
    call print_dot

.skip_print:
    loop .recv_next

    call print_newline
    pop si
    pop cx
    pop ax
    ret

; -------------------------------
; Display Helpers (INT 0x10)
; -------------------------------
print_str:
.next:
    lodsb
    or al, al
    jz .done
    call putc
    jmp .next
.done:
    ret

putc:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    ret

print_dot:
    mov al, '.'
    call putc
    ret

print_newline:
    mov al, 0x0D
    call putc
    mov al, 0x0A
    call putc
    ret

bootmsg:
    db "Serial Boot ROM - Waiting for data (64KB) ", 0
; -------------------------------

; Pad ROM to 8 KiB
times 8192 - ($ - $$) db 0
