default rel

; Define some macros
%define FILENAME_ADDR       [rsp + 0x10]        ; Address of argv[1]
%define BUFF_LEN            0x200000             ; Length of file buffer
%define HEX_PER_LINE        0x10                ; Number of hex chars per line
%define HEX_DELIM           0x20                ; Delimiter between hex chars
%define HEX_DELIM_NUM       0x1                 ; Number of delims between chars
%define COLUMN_DELIM_NUM    0x4                 ; Number of delims between cloumns
; Calculate size of buff_out based on other params
%define BUFF_OUT_LEN        ((BUFF_LEN * 0x3) + ((BUFF_LEN / 0x10) * (HEX_PER_LINE + COLUMN_DELIM_NUM)))

; Define registers for holding bytes read, argc, argv, etc
%define BYTES_READ          rbx                 ; RBX - Return value of sys_read
; R12 - Reserved for byte offset column
%define BUFF_OFF            r13                 ; R13 - Buff offset
%define BUFF_OUT_OFF        r14                 ; R14 - Output buffer offset
%define CHAR_COUNT          r15                 ; R15 - Number of characters printed so far
;

SECTION .data
    err_msg: db "Usage: hexdump_asm <file>",0xA   ; Error msg for incorrect usage of program
    err_msg_len: equ $-err_msg                  ; Error msg length
    col_nl: db ":",0xA                          ; A colon and new line
    space: db "    "                            ; 4 spaces
    hex_table:                                  ; Lookup table for hex values
        dd 0x00203030, 0x00203130, 0x00203230, 0x00203330, 0x00203430, 0x00203530, 0x00203630, 0x00203730,
        dd 0x00203830, 0x00203930, 0x00204130, 0x00204230, 0x00204330, 0x00204430, 0x00204530, 0x00204630,
        dd 0x00203031, 0x00203131, 0x00203231, 0x00203331, 0x00203431, 0x00203531, 0x00203631, 0x00203731,
        dd 0x00203831, 0x00203931, 0x00204131, 0x00204231, 0x00204331, 0x00204431, 0x00204531, 0x00204631,
        dd 0x00203032, 0x00203132, 0x00203232, 0x00203332, 0x00203432, 0x00203532, 0x00203632, 0x00203732,
        dd 0x00203832, 0x00203932, 0x00204132, 0x00204232, 0x00204332, 0x00204432, 0x00204532, 0x00204632,
        dd 0x00203033, 0x00203133, 0x00203233, 0x00203333, 0x00203433, 0x00203533, 0x00203633, 0x00203733,
        dd 0x00203833, 0x00203933, 0x00204133, 0x00204233, 0x00204333, 0x00204433, 0x00204533, 0x00204633,
        dd 0x00203034, 0x00203134, 0x00203234, 0x00203334, 0x00203434, 0x00203534, 0x00203634, 0x00203734,
        dd 0x00203834, 0x00203934, 0x00204134, 0x00204234, 0x00204334, 0x00204434, 0x00204534, 0x00204634,
        dd 0x00203035, 0x00203135, 0x00203235, 0x00203335, 0x00203435, 0x00203535, 0x00203635, 0x00203735,
        dd 0x00203835, 0x00203935, 0x00204135, 0x00204235, 0x00204335, 0x00204435, 0x00204535, 0x00204635,
        dd 0x00203036, 0x00203136, 0x00203236, 0x00203336, 0x00203436, 0x00203536, 0x00203636, 0x00203736,
        dd 0x00203836, 0x00203936, 0x00204136, 0x00204236, 0x00204336, 0x00204436, 0x00204536, 0x00204636,
        dd 0x00203037, 0x00203137, 0x00203237, 0x00203337, 0x00203437, 0x00203537, 0x00203637, 0x00203737,
        dd 0x00203837, 0x00203937, 0x00204137, 0x00204237, 0x00204337, 0x00204437, 0x00204537, 0x00204637,
        dd 0x00203038, 0x00203138, 0x00203238, 0x00203338, 0x00203438, 0x00203538, 0x00203638, 0x00203738,
        dd 0x00203838, 0x00203938, 0x00204138, 0x00204238, 0x00204338, 0x00204438, 0x00204538, 0x00204638,
        dd 0x00203039, 0x00203139, 0x00203239, 0x00203339, 0x00203439, 0x00203539, 0x00203639, 0x00203739,
        dd 0x00203839, 0x00203939, 0x00204139, 0x00204239, 0x00204339, 0x00204439, 0x00204539, 0x00204639,
        dd 0x00203041, 0x00203141, 0x00203241, 0x00203341, 0x00203441, 0x00203541, 0x00203641, 0x00203741,
        dd 0x00203841, 0x00203941, 0x00204141, 0x00204241, 0x00204341, 0x00204441, 0x00204541, 0x00204641,
        dd 0x00203042, 0x00203142, 0x00203242, 0x00203342, 0x00203442, 0x00203542, 0x00203642, 0x00203742,
        dd 0x00203842, 0x00203942, 0x00204142, 0x00204242, 0x00204342, 0x00204442, 0x00204542, 0x00204642,
        dd 0x00203043, 0x00203143, 0x00203243, 0x00203343, 0x00203443, 0x00203543, 0x00203643, 0x00203743,
        dd 0x00203843, 0x00203943, 0x00204143, 0x00204243, 0x00204343, 0x00204443, 0x00204543, 0x00204643,
        dd 0x00203044, 0x00203144, 0x00203244, 0x00203344, 0x00203444, 0x00203544, 0x00203644, 0x00203744,
        dd 0x00203844, 0x00203944, 0x00204144, 0x00204244, 0x00204344, 0x00204444, 0x00204544, 0x00204644,
        dd 0x00203045, 0x00203145, 0x00203245, 0x00203345, 0x00203445, 0x00203545, 0x00203645, 0x00203745,
        dd 0x00203845, 0x00203945, 0x00204145, 0x00204245, 0x00204345, 0x00204445, 0x00204545, 0x00204645,
        dd 0x00203046, 0x00203146, 0x00203246, 0x00203346, 0x00203446, 0x00203546, 0x00203646, 0x00203746,
        dd 0x00203846, 0x00203946, 0x00204146, 0x00204246, 0x00204346, 0x00204446, 0x00204546, 0x00204646
    ascii_table:                                ; Lookup table for ascii
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        db 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
        db 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        db 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
        db 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
        db 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
        db 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
        db 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
        db 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
        db 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
        db 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
        db 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E,
        db 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E, 0x2E

SECTION .bss
    buff: resb BUFF_LEN                         ; A buffer to hold files
    buff_out: resb BUFF_OUT_LEN                 ; A buffer to hold output

SECTION .text

global _start

_start:
    mov rax, [rsp]                              ; Copy argc into rax

    ; Check if a filename was passed
    cmp rax, 0x2                                ; If there aren't two arguments
    jnz err_exit                                ; Print error msg and exit


; Calculate length of the filename passed
filename_len:
    mov rax, FILENAME_ADDR                      ; Move address of argv[1] into rax
; Length counting loop
.loop:
    inc rdx                                     ; Keep count of arg length
    cmp BYTE [rax + rdx], 0x0                   ; Compare till null terminator
    jne .loop                                   ; is encountered


; Print the filename to the screen
print_filename:
    ; Print the filename itself
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    mov rsi, FILENAME_ADDR                      ; Specify address of argv[1]
                                                ; Length of argv[1] was calculated in filename_len
    syscall                                     ; Call sys_write

    ; Print a colon and newline after it
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    lea rsi, col_nl                             ; Specify address of ":\n"
    mov rdx, 0x2                                ; Specify length of the string
    syscall                                     ; Call sys_write


; Open the filename passed to the program
open_file:
    mov rax, 0x2                                ; Specify sys_open
    mov rdi, FILENAME_ADDR                      ; Specify address of the filename
    xor rsi, rsi                                ; Specify opening flags 0x0: Read Only
    syscall                                     ; Call sys_open

    push rax                                    ; Save the fd returned by sys_open


; Read the file into a buffer
read_file:
    xor rax, rax                                ; Specify sys_read
    pop rdi                                     ; Pop FD from stack into rdi
    lea rsi, buff                               ; Specify buffer address to read into
    mov rdx, BUFF_LEN                           ; Specify length of the buffer
    syscall                                     ; Call sys_read

    test rax, rax                               ; Empty file?
    jz close_file                               ; Close file and exit

    push rdi                                    ; Store FD back onto the stack

    ; Zero out all the counting registers
    xor BUFF_OFF, BUFF_OFF
    xor CHAR_COUNT, CHAR_COUNT
    xor BYTES_READ, BYTES_READ
    xor BUFF_OUT_OFF, BUFF_OUT_OFF
    ;

    mov BYTES_READ, rax                         ; Save number of bytes read by sys_read

    cmp BYTES_READ, 0x10                        ; If less than 16 bytes read
    jb print_hex_tail                           ; Jump to tail process


; Print the raw bytes in the file as hex values
print_hex:
    mov rcx, 0x10                               ; Use rcx as counter
    ; Maybe not efficient
    ;mov rdx, 0x20202020
    ;mov rsi, 0xA
    ;mov rdx, ' '
    ;shl rdx, 16
.loop:
    movzx rdx, BYTE [buff + BUFF_OFF]           ; Zero extend rax and copy current character into rax
    ; Redundant
    ;lea rsi, [hex_table + rax * 2]              ; Lookup its address in hex_table
    ;movzx rax, WORD [rsi]                       ; Zero extend rax and copy it into rax
    ;movzx rax, WORD [hex_table + rax * 2]
    movzx rax, DWORD [hex_table + rdx * 4]
    ;or rax, rdx
    ;mov WORD [buff_out + BUFF_OUT_OFF], ax      ; Write it to buff_out
    ;add BUFF_OUT_OFF, 0x2                       ; Move BUFF_OUT_OFF ahead by 2 bytes

    ;mov rax, HEX_DELIM                          ; Move a ' ' into rax
    ;mov [buff_out + BUFF_OUT_OFF], al           ; Write it to buff_out
    mov DWORD [buff_out + BUFF_OUT_OFF], eax
    add BUFF_OUT_OFF, 0x3

    ; Seems like using a register to hold trivial values like this one
    ; causes higher stalled frontend cycles, using immediate values
    ; might be better
    ;mov BYTE [buff_out + BUFF_OUT_OFF], HEX_DELIM
    ;mov BYTE [buff_out + BUFF_OUT_OFF], dl
    ;inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    inc BUFF_OFF                                ; Increment the character offset
    ;dec rcx                                     ; Decrement counter
    sub rcx, 0x1

    jnz .loop                                   ; Keep looping till its zero


; Print padding
print_padding:
    ;mov esi, DWORD [space]                    ; Zero extend rsi and move '    ' into rsi
    ;mov [buff_out + BUFF_OUT_OFF], esi          ; Write it to buff_out
    ;mov DWORD [buff_out + BUFF_OUT_OFF], edx
    mov DWORD [buff_out + BUFF_OUT_OFF], 0x20202020
    add BUFF_OUT_OFF, 0x3                       ; Move BUFF_OUT_OFF by 3 bytes


; Print characters
print_ascii:
    mov rcx, 0x10                               ; Use rcx as counter
.loop:
    movzx rdx, BYTE [buff + CHAR_COUNT]         ; Zero extend rax and copy current character into it
    ; Redundant
    ;lea rax, [ascii_table + rax]                ; Lookup address of current character in ascii_table
    ;mov al, [rax]                               ; Copy it into al
    movzx rax, BYTE [ascii_table + rdx]
    mov BYTE [buff_out + BUFF_OUT_OFF], al      ; Write it to buff_out
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    inc CHAR_COUNT                              ; Point to next character
    ;dec rcx                                     ; Decrement counter
    sub rcx, 0x1
    jnz .loop                                   ; Keep looping till its zero


; Print a newline after characters have been printed
; and jump to read_file if all bytes have been printed
; otherwise jump back to print_hex
print_newline:
    ;movzx rax, BYTE [col_nl+0x1]                ; Zero extend rax and move '\n' into rax
    ;mov [buff_out + BUFF_OUT_OFF], al           ; Write it to buff_out
    ;mov BYTE [buff_out + BUFF_OUT_OFF], sil
    mov BYTE [buff_out + BUFF_OUT_OFF], 0xA
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    sub BYTES_READ, 0x10                        ; Subtract 16 from number of bytes read

    ;test BYTES_READ, BYTES_READ                 ; Test if all bytes have been processed
    jz flush_buff                               ; Print buff_out if they have been

    cmp BYTES_READ, 0x10                        ; Jump to tail process if less than 16
    jb print_hex_tail                           ; bytes left

    jmp print_hex                               ; Jump back to printing hex characters


; Close the file as good programmers should
close_file:
    mov rax, 0x3                                ; Specify sys_close
    pop rdi                                     ; Pop FD into rdi
    syscall                                     ; Call sys_close


; Exit gracefully
exit:
    mov rax, 0x3c                               ; Specify sys_exit
    xor rdi, rdi                                ; Specify return value
    syscall                                     ; Call sys_exit


; Print buff_out to STDOUT once its filled
flush_buff:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x1                                ; Specify STDOUT
    lea rsi, buff_out                           ; Load address of buff_out
    mov rdx, BUFF_OUT_OFF                       ; Specify number of bytes written to buff_out
    syscall                                     ; Call sys_write

    jmp read_file                               ; Call sys_write


print_hex_tail:
    ;mov ecx, 0x20202020
    ;mov rdx, 0xA
.loop:
    movzx rdx, BYTE [buff + BUFF_OFF]           ; Zero extend rax and copy current character into rax
    ; Redundant
    ;lea rsi, [hex_table + rax * 2]              ; Lookup its address in hex_table
    ;movzx rax, WORD [rsi]                       ; Copy it into rax
    movzx rax, DWORD [hex_table + rdx * 4]
    mov DWORD [buff_out + BUFF_OUT_OFF], eax    ; Write it to buff_out
    add BUFF_OUT_OFF, 0x2                       ; Move BUFF_OUT_OFF ahead by 2 bytes

    inc BUFF_OFF                                ; Increment BUFF_OFF
    ;dec BYTES_READ                              ; Decrement BYTES_READ
    sub BYTES_READ, 0x1


; Print characters if 16 hex values have been printed
;check_char_count_tail:
    je print_padding_tail                       ; If BYTES_READ is 0 print padding

    ;mov rax, HEX_DELIM                          ; Move ' ' into rax
    ;mov BYTE [buff_out + BUFF_OUT_OFF], cl           ; Write it to buff_out
    ;mov BYTE [buff_out + BUFF_OUT_OFF], HEX_DELIM
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    ;jmp print_hex_tail                          ; Jump back to print_hex
    jmp .loop


; Prints padding and sets up char count so it can be used as the buff offset
print_padding_tail:
    mov rax, BUFF_OFF                           ; Store BUFF_OFF in rax
    sub rax, CHAR_COUNT                         ; Subtract CHAR_COUNT to get required padding count
    sub rax, 0x10                               ; Subtract 16 from it
    neg rax                                     ; Negate it

    ;movzx rsi, DWORD [space]                    ; Zero extend rsi and move '    ' into rsi

    ;mov [buff_out + BUFF_OUT_OFF], esi          ; Write it to buff_out
    ;mov DWORD [buff_out + BUFF_OUT_OFF], ecx
    mov DWORD [buff_out + BUFF_OUT_OFF], 0x20202020
    add BUFF_OUT_OFF, 0x4                       ; Move BUFF_OUT_OFF ahead by 4 bytes


; The loop to print spaces
padding_loop_tail:
    ;mov [buff_out + BUFF_OUT_OFF], esi          ; Write it to buff_out
    ;mov DWORD [buff_out + BUFF_OUT_OFF], ecx
    mov DWORD [buff_out + BUFF_OUT_OFF], 0x20202020
    add BUFF_OUT_OFF, 0x3                       ; Move BUFF_OUT_OFF ahead by 3 bytes

    ;dec rax                                     ; Decrement rax
    sub rax, 0x1

    jnz padding_loop_tail                       ; Loop till enough padding has been written


; Print characters
print_ascii_tail:
    movzx rdx, BYTE [buff + CHAR_COUNT]         ; Zero extend rax and copy current character into it
    ; Redundant
    ;lea rax, [ascii_table + rax]                ; Lookup address of current character in ascii_table
    ;mov al, [rax]                               ; Copy it into al
    movzx rax, BYTE [ascii_table + rdx]
    mov BYTE [buff_out + BUFF_OUT_OFF], al      ; Write it to buff_out
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    inc CHAR_COUNT                              ; Point to next character

    cmp CHAR_COUNT, BUFF_OFF                    ; If theres still characters left to
    jnz print_ascii_tail                        ; print jump back to print_ascii_tail


print_newline_tail:
    ;movzx rax, BYTE [col_nl+0x1]                ; Move '\n' into al
    ;mov [buff_out + BUFF_OUT_OFF], al           ; Write it to buff_out
    mov [buff_out + BUFF_OUT_OFF], 0xA
    ;mov BYTE [buff_out + BUFF_OUT_OFF], dl
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

    jmp flush_buff                              ; Print buff_out


; If no file was specified, print an example of how the
; program should be used to STDERR and exit
err_exit:
    mov rax, 0x1                                ; Specify sys_write
    mov rdi, 0x2                                ; Specify STDERR
    lea rsi, err_msg                            ; Error msg
    mov rdx, err_msg_len                        ; Error msg len
    syscall                                     ; Call sys_write

    mov rax, 0x3C                               ; Specify sys_exit
    mov rdi, 0x1                                ; Specify return value
    syscall                                     ; Call sys_exit
