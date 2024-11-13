section .text
    default rel
    global _start

_start:
    push rbp
    mov rbp, rsp

    ; [extern stbi_load]
    ; cmp dword [rbp - 4], 1
    ; je .end

    [extern printf]
    mov rdi, fmt
    mov rsi, str
    mov rax, 0
    call printf wrt ..plt

    pop rbp
.end:
    mov rax, 60 ; exit syscall
    mov rdi, 0  ; EXIT_SUCCESS
    syscall

section .data
    str: db "Hello, World", 0Ah, 0
    str_len: equ $ - str
    fmt: db "%s", 0Ah, 0
