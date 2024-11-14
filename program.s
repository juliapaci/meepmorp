section .text
    default rel
    global _start

; moves argc to %rax and argv to %rbx
load_arguments:
    ; offset by 16 because of call return address and alignment
    mov rax, [rsp + 16] ; argc
    lea rbx, [rsp + 24] ; argv[0]

    ret

; loads image pixel data into a buffer
; expects file name in rdi
get_image_data:
    push rbp
    mov rbp, rsp

    lea rax, [rdi]

    ; load image data
    extern stbi_load    ; "stb_image.h"
    lea rdi, [rax]      ; filename = argv[0]
    lea rsi, [rsp]      ; [ *x  ]   <- rsp
    lea rdx, [rsp + 64] ; [ *y  ]   <- rsp + sizeof(size_t)
    lea rcx, [rsp + 128]; [*comp]   <- rsp + 2*sizeof(size_t)
    xor r8, r8          ; req_comp = 0
    call stbi_load      ; rax = pixel byte buffer
    ; TODO: check stb errors

    ; mov rax, 9          ; mmap
    ; xor rdi, rdi        ; addr = NULL
    ; moc rsi,

    pop rbp
    ret

_start:
    push rbp
    mov rbp, rsp

    call load_arguments

    ; exits if no image/options was supplied
    cmp rdi, 1
    je .end

    push rbx

    ; print argc
    extern printf
    mov rdi, fmt
    mov rsi, rax
    xor rax, rax
    call printf wrt ..plt

    pop rdi         ; save argv[0] (image file name)
    call get_image_data

    pop rbp

.end:
    mov rax, 60     ; exit syscall
    xor rdi, rdi    ; EXIT_SUCCESS
    syscall

section .data
    fmt: db "%d", 0Ah, 0
