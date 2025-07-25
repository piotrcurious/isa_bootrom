org 0x0000

start:
    db 0x55, 0xAA
    db 0x10
    jmp init
    times 0x03 - ($ - $$) db 0

init:
    cli
    call init_serial

    mov si, msg_start
    call print_str

    ; Send request
    mov al, 'B'
    call send_byte

    ; Read 24-byte header into 0x0500
    xor ax, ax
    mov es, ax
    mov di, 0x0500
    mov cx, 24
.read_header:
    call recv_byte
    stosb
    loop .read_header

    ; Parse fields
    mov si, 0x0500
    ; Entry point
    mov ax, [si]
    mov dx, [si+2]
    mov [entry_off], ax
    mov [entry_seg], dx
    ; Payload
    mov ax, [si+4]
    mov dx, [si+6]
    mov [load_off], ax
    mov [load_seg], dx
    mov cx, [si+8]
    mov bx, [si+10]         ; dx:cx = payload size
    ; Cmdline
    mov ax, [si+12]
    mov dx, [si+14]
    mov [cmdline_off], ax
    mov [cmdline_seg], dx
    ; Initrd
    mov ax, [si+16]
    mov dx, [si+18]
    mov [initrd_off], ax
    mov [initrd_seg], dx
    mov si, [si+20]         ; initrd size in SI

    ; Load main payload
    mov ax, [load_seg]
    mov es, ax
    mov di, [load_off]
    mov si, msg_payload
    call print_str
    call load_data

    ; Load initrd if size > 0
    cmp si, 0
    jz .skip_initrd
    mov ax, [initrd_seg]
    mov es, ax
    mov di, [initrd_off]
    mov cx, si
    xor bx, bx
    mov si, msg_initrd
    call print_str
    call load_data

.skip_initrd:
    call print_newline

    ; Set ES:BX = cmdline
    mov es, [cmdline_seg]
    mov bx, [cmdline_off]

    ; Jump to loaded code
    jmp far [entry_ptr]

; ----------------------------
; Load DX:CX bytes to ES:DI
; ----------------------------
load_data:
    push ax
    push cx
    push bx
    push dx
    push si

    xor si, si
.load_loop:
    call recv_byte
    stosb
    inc si
    cmp si, 1024
    jne .nodot
    xor si, si
    call print_dot
.nodot:
    dec cx
    jnz .load_loop
    or bx, bx
    jz .done
    dec bx
    mov cx, 0xFFFF
    jmp .load_loop
.done:
    call print_newline
    pop si
    pop dx
    pop bx
    pop cx
    pop ax
    ret

; ----------------------------
; Serial and Display Routines
; ----------------------------
init_serial:
    mov dx, 0x3FB      ; LCR
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8      ; DLL
    mov al, 0x01
    out dx, al
    mov dx, 0x3F9      ; DLM
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x03       ; 8N1
    out dx, al
    ret

recv_byte:
    push dx
.wait_rx:
    mov dx, 0x3FD
    in al, dx
    test al, 1
    jz .wait_rx
    mov dx, 0x3F8
    in al, dx
    pop dx
    ret

send_byte:
    push dx
.wait_tx:
    mov dx, 0x3FD
    in al, dx
    test al, 0x20
    jz .wait_tx
    mov dx, 0x3F8
    out dx, al
    pop dx
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

; ----------------------------
; Variables
; ----------------------------
entry_seg dw 0
entry_off dw 0
load_seg  dw 0
load_off  dw 0
cmdline_seg dw 0
cmdline_off dw 0
initrd_seg dw 0
initrd_off dw 0
entry_ptr dw 0, 0

; ----------------------------
; Strings
; ----------------------------
msg_start:
    db "Serial Boot ROM - Waiting for header...", 0
msg_payload:
    db 13, 10, "Loading kernel...", 0
msg_initrd:
    db 13, 10, "Loading initrd...", 0

; ----------------------------
; Pad to 8 KiB
; ----------------------------
times 8192 - ($ - $$) db 0
