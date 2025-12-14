; ================================================================
; SimpleOS KERNEL v3.0 - kernel.asm
; ================================================================
; 13 Functions with RAM-based File System 
; ================================================================

BITS 16
ORG 0x1000

; Constants
MAX_FILES       equ 8
FILENAME_LEN    equ 8
FILE_DATA_SIZE  equ 64
FILE_ENTRY_SIZE equ 76
VIDEO_SEG       equ 0xB800

; ================================================================
; KERNEL ENTRY POINT
; ================================================================
kernel_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov byte [current_color], 0x0F
    mov byte [cursor_row], 0
    mov byte [cursor_col], 0
    call init_filesystem
    call clear_screen
    call show_welcome

; ================================================================
; MAIN SHELL LOOP
; ================================================================
shell_loop:
    mov si, prompt
    call print_string
    mov di, input_buffer
    call read_line
    call process_command
    jmp shell_loop

; ================================================================
; WELCOME SCREEN
; ================================================================
show_welcome:
    mov si, welcome_1
    call print_string
    mov si, welcome_2
    call print_string
    mov si, welcome_3
    call print_string
    mov si, welcome_4
    call print_string
    mov si, welcome_5
    call print_string
    ret

; ================================================================
; COMMAND PROCESSOR
; ================================================================
process_command:
    pusha
    mov si, input_buffer
    cmp byte [si], 0
    je .done

    mov di, cmd_help
    call str_cmp_i
    jc do_help

    mov si, input_buffer
    mov di, cmd_list
    call str_cmp_i
    jc do_list

    mov si, input_buffer
    mov di, cmd_clear
    call str_cmp_i
    jc do_clear

    mov si, input_buffer
    mov di, cmd_time
    call str_cmp_i
    jc do_time

    mov si, input_buffer
    mov di, cmd_date
    call str_cmp_i
    jc do_date

    mov si, input_buffer
    mov di, cmd_reboot
    call str_cmp_i
    jc do_reboot

    mov si, input_buffer
    mov di, cmd_files
    call str_cmp_i
    jc do_files

    mov si, input_buffer
    mov di, cmd_echo
    call str_starts_with
    jc do_echo

    mov si, input_buffer
    mov di, cmd_peek
    call str_starts_with
    jc do_peek

    mov si, input_buffer
    mov di, cmd_poke
    call str_starts_with
    jc do_poke

    mov si, input_buffer
    mov di, cmd_create
    call str_starts_with
    jc do_create

    mov si, input_buffer
    mov di, cmd_delete
    call str_starts_with
    jc do_delete

    mov si, input_buffer
    mov di, cmd_rename
    call str_starts_with
    jc do_rename

    mov si, msg_unknown
    call print_string
.done:
    popa
    ret

; ================================================================
; FUNCTION 1: HELP
; ================================================================
do_help:
    mov si, help_header
    call print_string
    mov si, help_sep
    call print_string
    mov si, help_1
    call print_string
    mov si, help_2
    call print_string
    mov si, help_3
    call print_string
    mov si, help_4
    call print_string
    mov si, help_5
    call print_string
    mov si, help_6
    call print_string
    mov si, help_7
    call print_string
    mov si, help_8
    call print_string
    mov si, help_9
    call print_string
    mov si, help_sep2
    call print_string
    mov si, help_10
    call print_string
    mov si, help_11
    call print_string
    mov si, help_12
    call print_string
    mov si, help_13
    call print_string
    mov si, help_sep
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 2: LIST
; ================================================================
do_list:
    call print_newline
    mov si, list_header
    call print_string
    mov si, help_sep
    call print_string
    mov si, list_mem
    call print_string
    int 0x12
    call print_decimal
    mov si, list_kb
    call print_string
    mov si, list_cpu
    call print_string
    mov si, list_video
    call print_string
    mov si, list_boot
    call print_string
    mov si, list_os
    call print_string
    mov si, help_sep
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 3: CLEAR
; ================================================================
do_clear:
    call clear_screen
    jmp process_command.done

; ================================================================
; FUNCTION 4: ECHO
; ================================================================
do_echo:
    mov si, input_buffer
    add si, 5
.skip:
    cmp byte [si], ' '
    jne .print
    inc si
    jmp .skip
.print:
    call print_string
    call print_newline
    jmp process_command.done

; ================================================================
; FUNCTION 5: TIME
; ================================================================
do_time:
    mov si, time_msg
    call print_string
    mov ah, 0x02
    int 0x1A
    mov al, ch
    call print_bcd
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char
    mov al, dh
    call print_bcd
    call print_newline
    jmp process_command.done

; ================================================================
; FUNCTION 6: DATE
; ================================================================
do_date:
    mov si, date_msg
    call print_string
    mov ah, 0x04
    int 0x1A
    mov al, dh
    call print_bcd
    mov al, '/'
    call print_char
    mov al, dl
    call print_bcd
    mov al, '/'
    call print_char
    mov al, ch
    call print_bcd
    mov al, cl
    call print_bcd
    call print_newline
    jmp process_command.done

; ================================================================
; FUNCTION 7: PEEK
; ================================================================
do_peek:
    mov si, input_buffer
    add si, 5
.skip_space:
    cmp byte [si], ' '
    jne .parse
    inc si
    jmp .skip_space
.parse:
    call parse_hex
    mov bx, ax
    mov si, peek_addr
    call print_string
    mov ax, bx
    call print_hex_word
    mov si, peek_val
    call print_string
    mov al, [bx]
    call print_hex_byte
    call print_newline
    jmp process_command.done

; ================================================================
; FUNCTION 8: POKE
; ================================================================
do_poke:
    mov si, input_buffer
    add si, 5
.skip1:
    cmp byte [si], ' '
    jne .get_addr
    inc si
    jmp .skip1
.get_addr:
    call parse_hex
    mov bx, ax
.skip2:
    cmp byte [si], ' '
    je .found_space
    cmp byte [si], 0
    je .error
    inc si
    jmp .skip2
.found_space:
    inc si
.skip3:
    cmp byte [si], ' '
    jne .get_value
    inc si
    jmp .skip3
.get_value:
    call parse_hex
    mov [bx], al
    mov si, poke_done
    call print_string
    jmp process_command.done
.error:
    mov si, poke_usage
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 9: REBOOT
; ================================================================
do_reboot:
    mov si, reboot_msg
    call print_string
    xor ax, ax
    int 0x16
    jmp 0xFFFF:0x0000

; ================================================================
; FUNCTION 10: CREATE
; ================================================================
do_create:
    mov si, input_buffer
    add si, 7
.skip_space:
    cmp byte [si], ' '
    jne .get_filename
    inc si
    jmp .skip_space
.get_filename:
    mov di, temp_filename
    xor cx, cx
.copy_name:
    mov al, [si]
    cmp al, ' '
    je .name_done
    cmp al, 0
    je .no_content
    cmp cx, FILENAME_LEN
    jge .skip_extra
    cmp al, 'a'
    jb .store_char
    cmp al, 'z'
    ja .store_char
    sub al, 32
.store_char:
    mov [di], al
    inc di
    inc cx
.skip_extra:
    inc si
    jmp .copy_name
.name_done:
    mov al, ' '
.pad_name:
    cmp cx, FILENAME_LEN
    jge .get_content
    mov [di], al
    inc di
    inc cx
    jmp .pad_name
.get_content:
    mov byte [di], 0
    inc si
.skip_content_space:
    cmp byte [si], ' '
    jne .have_content
    inc si
    jmp .skip_content_space
.have_content:
    mov [content_ptr], si
    mov bx, file_table
    xor cx, cx
.find_slot:
    cmp cx, MAX_FILES
    jge .table_full
    cmp byte [bx], 0
    je .found_slot
    add bx, FILE_ENTRY_SIZE
    inc cx
    jmp .find_slot
.found_slot:
    mov byte [bx], 1
    push bx
    inc bx
    mov di, bx
    mov si, temp_filename
    mov cx, FILENAME_LEN
    rep movsb
    pop bx
    mov si, [content_ptr]
    push bx
    add bx, 9
    mov di, bx
    xor cx, cx
.copy_data:
    mov al, [si]
    cmp al, 0
    je .content_done
    cmp cx, FILE_DATA_SIZE-1
    jge .content_done
    mov [di], al
    inc si
    inc di
    inc cx
    jmp .copy_data
.content_done:
    mov byte [di], 0
    pop bx
    mov [bx+73], cx
    mov si, file_created
    call print_string
    jmp process_command.done
.table_full:
    mov si, file_table_full
    call print_string
    jmp process_command.done
.no_content:
    mov si, create_usage
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 11: DELETE
; ================================================================
do_delete:
    mov si, input_buffer
    add si, 7
.skip_space:
    cmp byte [si], ' '
    jne .get_filename
    inc si
    jmp .skip_space
.get_filename:
    mov di, temp_filename
    xor cx, cx
.copy_name:
    mov al, [si]
    cmp al, ' '
    je .pad_name
    cmp al, 0
    je .pad_name
    cmp cx, FILENAME_LEN
    jge .skip_char
    cmp al, 'a'
    jb .store_char
    cmp al, 'z'
    ja .store_char
    sub al, 32
.store_char:
    mov [di], al
    inc di
    inc cx
.skip_char:
    inc si
    jmp .copy_name
.pad_name:
    mov al, ' '
.pad_loop:
    cmp cx, FILENAME_LEN
    jge .search_file
    mov [di], al
    inc di
    inc cx
    jmp .pad_loop
.search_file:
    mov byte [di], 0
    mov bx, file_table
    xor cx, cx
.search_loop:
    cmp cx, MAX_FILES
    jge .not_found
    cmp byte [bx], 0
    je .next_slot
    push cx
    push bx
    inc bx
    mov si, temp_filename
    mov di, bx
    mov cx, FILENAME_LEN
    call str_ncmp_i
    pop bx
    pop cx
    jc .found_file
.next_slot:
    add bx, FILE_ENTRY_SIZE
    inc cx
    jmp .search_loop
.found_file:
    mov byte [bx], 0
    mov si, file_deleted
    call print_string
    jmp process_command.done
.not_found:
    mov si, file_not_found
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 12: RENAME
; ================================================================
do_rename:
    mov si, input_buffer
    add si, 7
.skip_space1:
    cmp byte [si], ' '
    jne .get_oldname
    inc si
    jmp .skip_space1
.get_oldname:
    mov di, temp_filename
    xor cx, cx
.copy_old:
    mov al, [si]
    cmp al, ' '
    je .pad_old
    cmp al, 0
    je .usage_error
    cmp cx, FILENAME_LEN
    jge .skip_old
    cmp al, 'a'
    jb .store_old
    cmp al, 'z'
    ja .store_old
    sub al, 32
.store_old:
    mov [di], al
    inc di
    inc cx
.skip_old:
    inc si
    jmp .copy_old
.pad_old:
    mov al, ' '
.pad_old_loop:
    cmp cx, FILENAME_LEN
    jge .get_newname
    mov [di], al
    inc di
    inc cx
    jmp .pad_old_loop
.get_newname:
    mov byte [di], 0
    inc si
.skip_space2:
    cmp byte [si], ' '
    jne .copy_new
    inc si
    jmp .skip_space2
.copy_new:
    mov di, temp_filename2
    xor cx, cx
.copy_new_loop:
    mov al, [si]
    cmp al, ' '
    je .pad_new
    cmp al, 0
    je .pad_new
    cmp cx, FILENAME_LEN
    jge .skip_new
    cmp al, 'a'
    jb .store_new
    cmp al, 'z'
    ja .store_new
    sub al, 32
.store_new:
    mov [di], al
    inc di
    inc cx
.skip_new:
    inc si
    jmp .copy_new_loop
.pad_new:
    cmp cx, 0
    je .usage_error
    mov al, ' '
.pad_new_loop:
    cmp cx, FILENAME_LEN
    jge .do_rename_search
    mov [di], al
    inc di
    inc cx
    jmp .pad_new_loop
.do_rename_search:
    mov byte [di], 0
    mov bx, file_table
    xor cx, cx
.search_loop:
    cmp cx, MAX_FILES
    jge .not_found
    cmp byte [bx], 0
    je .next_slot
    push cx
    push bx
    inc bx
    mov si, temp_filename
    mov di, bx
    mov cx, FILENAME_LEN
    call str_ncmp_i
    pop bx
    pop cx
    jc .found_file
.next_slot:
    add bx, FILE_ENTRY_SIZE
    inc cx
    jmp .search_loop
.found_file:
    inc bx
    mov di, bx
    mov si, temp_filename2
    mov cx, FILENAME_LEN
    rep movsb
    mov si, file_renamed
    call print_string
    jmp process_command.done
.not_found:
    mov si, file_not_found
    call print_string
    jmp process_command.done
.usage_error:
    mov si, rename_usage
    call print_string
    jmp process_command.done

; ================================================================
; FUNCTION 13: FILES
; ================================================================
do_files:
    call print_newline
    mov si, files_header
    call print_string
    mov si, help_sep
    call print_string
    mov bx, file_table
    xor cx, cx
    xor dx, dx
.list_loop:
    cmp cx, MAX_FILES
    jge .list_done
    cmp byte [bx], 0
    je .next_file
    mov si, files_prefix
    call print_string
    push bx
    push cx
    inc bx
    mov cx, FILENAME_LEN
.print_name:
    mov al, [bx]
    call print_char
    inc bx
    loop .print_name
    pop cx
    pop bx
    mov si, files_size
    call print_string
    push bx
    mov ax, [bx+73]
    call print_decimal
    pop bx
    mov si, files_bytes
    call print_string
    inc dx
.next_file:
    add bx, FILE_ENTRY_SIZE
    inc cx
    jmp .list_loop
.list_done:
    mov si, help_sep
    call print_string
    mov si, files_total
    call print_string
    mov ax, dx
    call print_decimal
    mov si, files_suffix
    call print_string
    jmp process_command.done

; ================================================================
; FILESYSTEM INITIALIZATION
; ================================================================
init_filesystem:
    pusha
    mov di, file_table
    mov cx, MAX_FILES * FILE_ENTRY_SIZE
    xor al, al
    rep stosb
    popa
    ret

; ================================================================
; PRINT_CHAR - Direct Video Memory (COLORS WORK!)
; ================================================================
print_char:
    pusha
    cmp al, 13
    je .do_cr
    cmp al, 10
    je .do_lf
    cmp al, 8
    je .do_bs
    
    push ax
    xor ax, ax
    mov al, [cursor_row]
    mov bx, 80
    mul bx
    xor bh, bh
    mov bl, [cursor_col]
    add ax, bx
    shl ax, 1
    mov di, ax
    pop ax
    
    push es
    mov bx, VIDEO_SEG
    mov es, bx
    mov [es:di], al
    mov al, [current_color]
    mov [es:di+1], al
    pop es
    
    inc byte [cursor_col]
    cmp byte [cursor_col], 80
    jl .update
    mov byte [cursor_col], 0
    inc byte [cursor_row]
    cmp byte [cursor_row], 25
    jl .update
    call scroll_screen
    mov byte [cursor_row], 24
    jmp .update
    
.do_cr:
    mov byte [cursor_col], 0
    jmp .update
.do_lf:
    inc byte [cursor_row]
    cmp byte [cursor_row], 25
    jl .update
    call scroll_screen
    mov byte [cursor_row], 24
    jmp .update
.do_bs:
    cmp byte [cursor_col], 0
    je .update
    dec byte [cursor_col]
.update:
    call update_cursor
    popa
    ret

; ================================================================
; SCROLL_SCREEN
; ================================================================
scroll_screen:
    pusha
    push es
    mov ax, VIDEO_SEG
    mov es, ax
    mov di, 0
    mov si, 160
    mov cx, 80 * 24
.copy:
    mov ax, [es:si]
    mov [es:di], ax
    add si, 2
    add di, 2
    loop .copy
    mov di, 80 * 24 * 2
    mov cx, 80
    mov ah, [current_color]
    mov al, ' '
.clear:
    mov [es:di], ax
    add di, 2
    loop .clear
    pop es
    popa
    ret

; ================================================================
; UPDATE_CURSOR
; ================================================================
update_cursor:
    pusha
    xor ax, ax
    mov al, [cursor_row]
    mov bx, 80
    mul bx
    xor bh, bh
    mov bl, [cursor_col]
    add ax, bx
    mov bx, ax
    mov al, 14
    mov dx, 0x3D4
    out dx, al
    mov al, bh
    mov dx, 0x3D5
    out dx, al
    mov al, 15
    mov dx, 0x3D4
    out dx, al
    mov al, bl
    mov dx, 0x3D5
    out dx, al
    popa
    ret

; ================================================================
; CLEAR_SCREEN - Direct Video Memory
; ================================================================
clear_screen:
    pusha
    push es
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, 80 * 25
    mov ah, [current_color]
    mov al, ' '
.clear:
    mov [es:di], ax
    add di, 2
    loop .clear
    mov byte [cursor_row], 0
    mov byte [cursor_col], 0
    call update_cursor
    pop es
    popa
    ret

; ================================================================
; OTHER UTILITY FUNCTIONS
; ================================================================
print_string:
    pusha
.loop:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    popa
    ret

print_newline:
    pusha
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    popa
    ret

print_bcd:
    pusha
    mov bl, al
    shr al, 4
    add al, '0'
    call print_char
    mov al, bl
    and al, 0x0F
    add al, '0'
    call print_char
    popa
    ret

print_decimal:
    pusha
    xor cx, cx
    mov bx, 10
.divide:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .divide
.print:
    pop ax
    add al, '0'
    call print_char
    loop .print
    popa
    ret

print_hex_byte:
    pusha
    mov bl, al
    shr al, 4
    call .nibble
    mov al, bl
    and al, 0x0F
    call .nibble
    popa
    ret
.nibble:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    call print_char
    ret

print_hex_word:
    pusha
    mov bx, ax
    mov al, bh
    call print_hex_byte
    mov al, bl
    call print_hex_byte
    popa
    ret

parse_decimal:
    push bx
    push cx
    push dx
    xor ax, ax
    xor cx, cx
.loop:
    mov cl, [si]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    mov bx, 10
    mul bx
    sub cl, '0'
    add ax, cx
    inc si
    jmp .loop
.done:
    pop dx
    pop cx
    pop bx
    ret

parse_hex:
    push bx
    push cx
    xor ax, ax
    cmp byte [si], '0'
    jne .loop
    cmp byte [si+1], 'x'
    jne .check_X
    add si, 2
    jmp .loop
.check_X:
    cmp byte [si+1], 'X'
    jne .loop
    add si, 2
.loop:
    mov cl, [si]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    jbe .is_digit
    cmp cl, 'A'
    jb .done
    cmp cl, 'F'
    jbe .is_upper
    cmp cl, 'a'
    jb .done
    cmp cl, 'f'
    ja .done
    sub cl, 'a'
    add cl, 10
    jmp .add_digit
.is_upper:
    sub cl, 'A'
    add cl, 10
    jmp .add_digit
.is_digit:
    sub cl, '0'
.add_digit:
    shl ax, 4
    xor ch, ch
    add ax, cx
    inc si
    jmp .loop
.done:
    pop cx
    pop bx
    ret

read_line:
    pusha
    xor cx, cx
.read:
    xor ax, ax
    int 0x16
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    cmp cx, 62
    jge .read
    stosb
    inc cx
    call print_char
    jmp .read
.backspace:
    cmp cx, 0
    je .read
    dec di
    dec cx
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .read
.done:
    mov byte [di], 0
    call print_newline
    popa
    ret

str_cmp_i:
    pusha
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, 'a'
    jb .check_bl
    cmp al, 'z'
    ja .check_bl
    sub al, 32
.check_bl:
    cmp bl, 'a'
    jb .compare
    cmp bl, 'z'
    ja .compare
    sub bl, 32
.compare:
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

str_ncmp_i:
    pusha
.loop:
    cmp cx, 0
    je .equal
    mov al, [si]
    mov bl, [di]
    cmp al, 'a'
    jb .up_bl
    cmp al, 'z'
    ja .up_bl
    sub al, 32
.up_bl:
    cmp bl, 'a'
    jb .cmp
    cmp bl, 'z'
    ja .cmp
    sub bl, 32
.cmp:
    cmp al, bl
    jne .not_equal
    inc si
    inc di
    dec cx
    jmp .loop
.equal:
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

str_starts_with:
    pusha
.loop:
    mov bl, [di]
    cmp bl, 0
    je .match
    mov al, [si]
    cmp al, 'a'
    jb .upper_bl
    cmp al, 'z'
    ja .upper_bl
    sub al, 32
.upper_bl:
    cmp bl, 'a'
    jb .cmp
    cmp bl, 'z'
    ja .cmp
    sub bl, 32
.cmp:
    cmp al, bl
    jne .no_match
    inc si
    inc di
    jmp .loop
.match:
    popa
    stc
    ret
.no_match:
    popa
    clc
    ret

; ================================================================
; DATA SECTION
; ================================================================
current_color:  db 0x0F
cursor_row:     db 0
cursor_col:     db 0
input_buffer:   times 64 db 0
temp_filename:  times 12 db 0
temp_filename2: times 12 db 0
content_ptr:    dw 0

prompt: db 'SimpleOS> ', 0

welcome_1: db '================================================', 13, 10, 0
welcome_2: db '   SimpleOS v3.0 - With File System            ', 13, 10, 0
welcome_3: db '   13 Functions - Type HELP for commands       ', 13, 10, 0
welcome_4: db '   Internal color system enabled               ', 13, 10, 0
welcome_5: db '================================================', 13, 10, 13, 10, 0

cmd_help:   db 'HELP', 0
cmd_list:   db 'LIST', 0
cmd_clear:  db 'CLEAR', 0
cmd_echo:   db 'ECHO', 0
cmd_time:   db 'TIME', 0
cmd_date:   db 'DATE', 0
cmd_peek:   db 'PEEK', 0
cmd_poke:   db 'POKE', 0
cmd_reboot: db 'REBOOT', 0
cmd_create: db 'CREATE', 0
cmd_delete: db 'DELETE', 0
cmd_rename: db 'RENAME', 0
cmd_files:  db 'FILES', 0

msg_unknown: db 'Unknown command. Type HELP for list.', 13, 10, 0

help_header: db 13, 10, 'AVAILABLE COMMANDS (13 Functions):', 13, 10, 0
help_sep:    db '----------------------------------------', 13, 10, 0
help_sep2:   db '--- File Commands ----------------------', 13, 10, 0
help_1:      db '  HELP            - Show this help', 13, 10, 0
help_2:      db '  LIST            - Display system info', 13, 10, 0
help_3:      db '  CLEAR           - Clear screen', 13, 10, 0
help_4:      db '  ECHO <text>     - Print text', 13, 10, 0
help_5:      db '  TIME            - Show current time', 13, 10, 0
help_6:      db '  DATE            - Show current date', 13, 10, 0
help_7:      db '  PEEK <addr>     - View memory (hex)', 13, 10, 0
help_8:      db '  POKE <a> <v>    - Write memory (hex)', 13, 10, 0
help_9:      db '  REBOOT          - Restart computer', 13, 10, 0
help_10:     db '  CREATE <n> <d>  - Create file', 13, 10, 0
help_11:     db '  DELETE <name>   - Delete file', 13, 10, 0
help_12:     db '  RENAME <o> <n>  - Rename file', 13, 10, 0
help_13:     db '  FILES           - List all files', 13, 10, 0

list_header: db 'SYSTEM INFORMATION:', 13, 10, 0
list_mem:    db '  Memory:  ', 0
list_kb:     db ' KB', 13, 10, 0
list_cpu:    db '  CPU:     x86 16-bit Real Mode', 13, 10, 0
list_video:  db '  Video:   VGA 80x25 Text Mode', 13, 10, 0
list_boot:   db '  Boot:    Floppy/USB Image', 13, 10, 0
list_os:     db '  OS:      SimpleOS v3.0', 13, 10, 0

time_msg:       db 'Time: ', 0
date_msg:       db 'Date: ', 0
peek_addr:      db 'Address 0x', 0
peek_val:       db ' = 0x', 0
poke_done:      db 'Memory written!', 13, 10, 0
poke_usage:     db 'Usage: POKE <addr> <value>', 13, 10, 0
reboot_msg:     db 'Press any key to reboot...', 0

file_created:    db 'File created!', 13, 10, 0
file_deleted:    db 'File deleted!', 13, 10, 0
file_renamed:    db 'File renamed!', 13, 10, 0
file_not_found:  db 'Error: File not found!', 13, 10, 0
file_table_full: db 'Error: File table full!', 13, 10, 0
create_usage:    db 'Usage: CREATE <name> <content>', 13, 10, 0
rename_usage:    db 'Usage: RENAME <old> <new>', 13, 10, 0
files_header:    db 'FILES IN MEMORY:', 13, 10, 0
files_prefix:    db '  ', 0
files_size:      db '  Size: ', 0
files_bytes:     db ' bytes', 13, 10, 0
files_total:     db 'Total files: ', 0
files_suffix:    db 13, 10, 0

file_table: times (MAX_FILES * FILE_ENTRY_SIZE) db 0

times 8192-($-$$) db 0
