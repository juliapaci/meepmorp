section .data
str: db "Hello, World", 0Ah
str_len: equ $ - str

section .text
global _start

_start:
    push rbp
    mov rbp, rsp

    [extern stbi_load]
    ; TODO: get file name from command arguments
    ; cmp dword [rbp - 4], 1
    ; je .end

    mov rax, 1  ; write syscall
    mov rdi, 1  ; stdout file descriptor
    lea rsi, str
    mov rdx, str_len
    syscall

.end:
    mov rax, 60 ; exit syscall
    mov rdi, 0  ; EXIT_SUCCESS
    syscall
