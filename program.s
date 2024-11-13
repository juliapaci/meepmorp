section .text
    default rel
    global _start

; moves argc to %rdi and argv to %rsi
load_arguments:
    ; offset by 16 because of call return address and alignment
    mov rdi, [rsp + 16]          ; argc
    lea rsi, [rsp + 24]      ; argv[0]

    ret

_start:
    push rbp
    mov rbp, rsp

    call load_arguments

    ; exits if no image/options was supplied
    cmp rdi, 1
    je .end

    extern printf
    mov rsi, rdi
    mov rdi, fmt
    mov rax, 0
    call printf wrt ..plt

    pop rbp

.end:
    mov rax, 60 ; exit syscall
    mov rdi, 0  ; EXIT_SUCCESS
    syscall

section .data
    fmt: db "%d", 0Ah, 0
