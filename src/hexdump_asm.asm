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
        dw 0x3030, 0x3130, 0x3230, 0x3330, 0x3430, 0x3530, 0x3630, 0x3730,
        dw 0x3830, 0x3930, 0x4130, 0x4230, 0x4330, 0x4430, 0x4530, 0x4630,
        dw 0x3031, 0x3131, 0x3231, 0x3331, 0x3431, 0x3531, 0x3631, 0x3731,
        dw 0x3831, 0x3931, 0x4131, 0x4231, 0x4331, 0x4431, 0x4531, 0x4631,
        dw 0x3032, 0x3132, 0x3232, 0x3332, 0x3432, 0x3532, 0x3632, 0x3732,
        dw 0x3832, 0x3932, 0x4132, 0x4232, 0x4332, 0x4432, 0x4532, 0x4632,
        dw 0x3033, 0x3133, 0x3233, 0x3333, 0x3433, 0x3533, 0x3633, 0x3733,
        dw 0x3833, 0x3933, 0x4133, 0x4233, 0x4333, 0x4433, 0x4533, 0x4633,
        dw 0x3034, 0x3134, 0x3234, 0x3334, 0x3434, 0x3534, 0x3634, 0x3734,
        dw 0x3834, 0x3934, 0x4134, 0x4234, 0x4334, 0x4434, 0x4534, 0x4634,
        dw 0x3035, 0x3135, 0x3235, 0x3335, 0x3435, 0x3535, 0x3635, 0x3735,
        dw 0x3835, 0x3935, 0x4135, 0x4235, 0x4335, 0x4435, 0x4535, 0x4635,
        dw 0x3036, 0x3136, 0x3236, 0x3336, 0x3436, 0x3536, 0x3636, 0x3736,
        dw 0x3836, 0x3936, 0x4136, 0x4236, 0x4336, 0x4436, 0x4536, 0x4636,
        dw 0x3037, 0x3137, 0x3237, 0x3337, 0x3437, 0x3537, 0x3637, 0x3737,
        dw 0x3837, 0x3937, 0x4137, 0x4237, 0x4337, 0x4437, 0x4537, 0x4637,
        dw 0x3038, 0x3138, 0x3238, 0x3338, 0x3438, 0x3538, 0x3638, 0x3738,
        dw 0x3838, 0x3938, 0x4138, 0x4238, 0x4338, 0x4438, 0x4538, 0x4638,
        dw 0x3039, 0x3139, 0x3239, 0x3339, 0x3439, 0x3539, 0x3639, 0x3739,
        dw 0x3839, 0x3939, 0x4139, 0x4239, 0x4339, 0x4439, 0x4539, 0x4639,
        dw 0x3041, 0x3141, 0x3241, 0x3341, 0x3441, 0x3541, 0x3641, 0x3741,
        dw 0x3841, 0x3941, 0x4141, 0x4241, 0x4341, 0x4441, 0x4541, 0x4641,
        dw 0x3042, 0x3142, 0x3242, 0x3342, 0x3442, 0x3542, 0x3642, 0x3742,
        dw 0x3842, 0x3942, 0x4142, 0x4242, 0x4342, 0x4442, 0x4542, 0x4642,
        dw 0x3043, 0x3143, 0x3243, 0x3343, 0x3443, 0x3543, 0x3643, 0x3743,
        dw 0x3843, 0x3943, 0x4143, 0x4243, 0x4343, 0x4443, 0x4543, 0x4643,
        dw 0x3044, 0x3144, 0x3244, 0x3344, 0x3444, 0x3544, 0x3644, 0x3744,
        dw 0x3844, 0x3944, 0x4144, 0x4244, 0x4344, 0x4444, 0x4544, 0x4644,
        dw 0x3045, 0x3145, 0x3245, 0x3345, 0x3445, 0x3545, 0x3645, 0x3745,
        dw 0x3845, 0x3945, 0x4145, 0x4245, 0x4345, 0x4445, 0x4545, 0x4645,
        dw 0x3046, 0x3146, 0x3246, 0x3346, 0x3446, 0x3546, 0x3646, 0x3746,
        dw 0x3846, 0x3946, 0x4146, 0x4246, 0x4346, 0x4446, 0x4546, 0x4646
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
    ;mov edx, 0x20202020
    ;mov rsi, 0xA
.loop:
    movzx rax, BYTE [buff + BUFF_OFF]           ; Zero extend rax and copy current character into rax
    ; Redundant
    ;lea rsi, [hex_table + rax * 2]              ; Lookup its address in hex_table
    ;movzx rax, WORD [rsi]                       ; Zero extend rax and copy it into rax
    movzx rax, WORD [hex_table + rax * 2]
    mov WORD [buff_out + BUFF_OUT_OFF], ax      ; Write it to buff_out
    add BUFF_OUT_OFF, 0x2                       ; Move BUFF_OUT_OFF ahead by 2 bytes

    ;mov rax, HEX_DELIM                          ; Move a ' ' into rax
    ;mov [buff_out + BUFF_OUT_OFF], al           ; Write it to buff_out

    ; Seems like using a register to hold trivial values like this one
    ; causes higher stalled frontend cycles, using immediate values
    ; might be better
    mov BYTE [buff_out + BUFF_OUT_OFF], HEX_DELIM
    ;mov BYTE [buff_out + BUFF_OUT_OFF], dl
    inc BUFF_OUT_OFF                            ; Move BUFF_OUT_OFF ahead by 1 byte

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
    movzx rax, BYTE [buff + CHAR_COUNT]         ; Zero extend rax and copy current character into it
    ; Redundant
    ;lea rax, [ascii_table + rax]                ; Lookup address of current character in ascii_table
    ;mov al, [rax]                               ; Copy it into al
    movzx rax, BYTE [ascii_table + rax]
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
    movzx rax, BYTE [buff + BUFF_OFF]           ; Zero extend rax and copy current character into rax
    ; Redundant
    ;lea rsi, [hex_table + rax * 2]              ; Lookup its address in hex_table
    ;movzx rax, WORD [rsi]                       ; Copy it into rax
    movzx rax, WORD [hex_table + rax * 2]
    mov WORD [buff_out + BUFF_OUT_OFF], ax      ; Write it to buff_out
    add BUFF_OUT_OFF, 0x2                       ; Move BUFF_OUT_OFF ahead by 2 bytes

    inc BUFF_OFF                                ; Increment BUFF_OFF
    ;dec BYTES_READ                              ; Decrement BYTES_READ
    sub BYTES_READ, 0x1


; Print characters if 16 hex values have been printed
;check_char_count_tail:
    je print_padding_tail                       ; If BYTES_READ is 0 print padding

    ;mov rax, HEX_DELIM                          ; Move ' ' into rax
    ;mov BYTE [buff_out + BUFF_OUT_OFF], cl           ; Write it to buff_out
    mov BYTE [buff_out + BUFF_OUT_OFF], HEX_DELIM
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
    movzx rax, BYTE [buff + CHAR_COUNT]         ; Zero extend rax and copy current character into it
    ; Redundant
    ;lea rax, [ascii_table + rax]                ; Lookup address of current character in ascii_table
    ;mov al, [rax]                               ; Copy it into al
    movzx rax, BYTE [ascii_table + rax]
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
