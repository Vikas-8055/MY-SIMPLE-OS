; ================================================================
; STAGE 1 BOOTLOADER - boot.asm
; ================================================================
; Purpose: Load the kernel from disk into memory and jump to it
; Size: 512 bytes (boot sector)
; ================================================================

BITS 16
ORG 0x7C00

; Constants
KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 16

; ================================================================
; Entry Point
; ================================================================
boot_start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Save boot drive number
    mov [boot_drive], dl

    ; Print loading message
    mov si, msg_loading
    call print_string

    ; Load kernel from disk
    call load_kernel

    ; Print success message
    mov si, msg_done
    call print_string

    ; Jump to loaded kernel
    jmp KERNEL_OFFSET

; ================================================================
; load_kernel: Load kernel sectors from disk
; ================================================================
load_kernel:
    pusha
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    xor bx, bx
    mov es, bx
    mov bx, KERNEL_OFFSET
    int 0x13
    jc disk_error
    cmp al, KERNEL_SECTORS
    jne disk_error
    popa
    ret

disk_error:
    mov si, msg_error
    call print_string
    jmp $

; ================================================================
; print_string: Print null-terminated string
; ================================================================
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; ================================================================
; Data
; ================================================================
boot_drive:     db 0
msg_loading:    db 'Loading SimpleOS...', 13, 10, 0
msg_done:       db 'OK', 13, 10, 0
msg_error:      db 'Disk Error!', 0

; ================================================================
; Boot Signature
; ================================================================
times 510-($-$$) db 0
dw 0xAA55
