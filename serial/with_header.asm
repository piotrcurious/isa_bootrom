org 0x0000

start:
    db 0x55, 0xAA      ; ROM signature
    db 0x10            ; 8 KiB ROM size
    jmp init

    times 0x03 - ($-$$) db 0

init:
    cli
    call init_serial

    ; Print boot message
    mov si, msg_start
    call print_str

    ; Send boot request
    mov al, 'B'
    call send_byte

    ; Read 16-byte header into buffer at 0x0500
    xor ax, ax
    mov es, ax
    mov di, 0x0500
    mov cx, 16
.read_hdr:
    call recv_byte
    stosb
    loop .read_hdr

    ; Parse header
    mov si, 0x0500
    ; entry_point = [0x0500 + 0]
    mov ax, [si]
    mov dx, [si+2]
    mov [entry_seg], dx
    mov [entry_off], ax

    ; load_address = [0x0500 + 4]
    mov ax, [si+4]
    mov dx, [si+6]
    mov [load_seg], dx
    mov [load_off], ax

    ; payload_size = [0x0500 + 8]
    mov cx, [si+8]          ; low
    mov bx, [si+10]         ; high
    ; combine into dx:cx = total size
    ; Assume < 512KB for now

    ; cmdline_ptr = [0x0500 + 12]
    mov ax, [si+12]
    mov dx, [si+14]
    mov [cmdline_seg], dx
    mov [cmdline_off], ax

    ; Display progress
    mov si, msg_receiving
    call print_str

    ; Start loading payload at [load_seg:load_off]
    mov ax, [load_seg]
    mov es, ax
    mov di, [load_off]

    mov si, 0              ; progress counter
.read_payload:
    call recv_byte
    stosb
    inc si
    cmp si, 1024
    jne .no_dot
    xor si, si
    call print_dot
.no_dot:
    dec cx
    jnz .read_payload
    or bx, bx
    jz .done_recv
    dec bx
    mov cx, 0xFFFF
    jmp .read_payload

.done_recv:
    call print_newline

    ; If cmdline_ptr != 0, pass in ES:BX
    mov dx, [cmdline_seg]
    mov bx, [cmdline_off]
    mov es, dx

    ; Jump to entry_point
    jmp far [entry_ptr]

; ---------------
; Data area
; ---------------
entry_seg dw 0
entry_off dw 0
load_seg dw 0
load_off dw 0
cmdline_seg dw 0
cmdline_off dw 0
entry_ptr dw 0, 0

; After header parsed:
;   [entry_off], [entry_seg] = target
;   [load_off], [load_seg] = where to store
;   [cmdline_off], [cmdline_seg] = string pointer (if any)

; ---------------
; Serial I/O
; ---------------
COM1         equ 0x3F8
DATA_REG     equ COM1 + 0
LCR_REG      equ COM1 + 3
LSR_REG      equ COM1 + 5
DLL_REG      equ COM1 + 0
DLM_REG      equ COM1 + 1

init_serial:
    mov dx, LCR_REG
    mov al, 0x80
    out dx, al
    mov dx, DLL_REG
    mov al, 0x01
    out dx, al
    mov dx, DLM_REG
    xor al, al
    out dx, al
    mov dx, LCR_REG
    mov al, 0x03
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

; ---------------
; Printing
; ---------------
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

print_str:
.next:
    lodsb
    or al, al
    jz .done
    call putc
    jmp .next
.done:
    ret

msg_start:
    db "Serial Boot ROM - Awaiting header...", 0

msg_receiving:
    db 13, 10, "Receiving payload: ", 0

; -----------------------
; Pad to 8 KiB
; -----------------------
times 8192 - ($ - $$) db 0
