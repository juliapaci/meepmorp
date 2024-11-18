section .text
    default rel
    global _start

    extern printf
    extern stbi_load    ; "stb_image.h"

; moves argc to %rax and argv to %rbx
load_arguments:
    ; offset by 16 because of call return address and alignment
    mov rax, [rsp + 0x10] ; argc
    lea rbx, [rsp + 0x18] ; argv

    ret

; loads image pixel data into a buffer
; expects file name in rdi
get_image_data:
    push rbp
    mov rbp, rsp

    mov rax, rdi

    sub rsp, 0x10

    ; load image data
    mov rdi, [rax]      ; filename = argv[1]
    lea rsi, [rsp]      ; [ *x  ]   <- rsp
    lea rdx, [rsp + 0x4]; [ *y  ]   <- rsp + sizeof(i32)
    lea rcx, [rsp + 0x8]; [*comp]   <- rsp + 2*sizeof(i32)
    xor r8, r8          ; req_comp = 0
    call stbi_load      ; rax = pixel byte buffer
    ; TODO: check stb errors
    ; TODO: free

    add rsp, 0x10

    ; mov rax, 9          ; mmap
    ; xor rdi, rdi        ; addr = NULL
    ; moc rsi,

    pop rbp
    ret

; random number between 0 and rsi using 32 bit xorshift
; does not use `getrandom` syscall
; returns a single integer in rax (eax because 32 bit width and height) based on seed in rdi
; use division and its remainder to find x and y coordinate of the single number
random:
    ; xorshift
    mov rax, rdi

    shl rdi, 13
    xor rax, rdi

    mov rdi, rax
    shr rdi, 17
    xor rax, rdi

    mov rdi, rax
    shl rdi, 17
    xor rax, rdi

    ; clamp
    ; remainder of edx:eax by ebx
    ; rax (eax) is already populated
    xor edx, edx

    mov rbx, rsi

    div ebx

    mov eax, edx

    ret

_start:
    push rbp
    mov rbp, rsp

    call load_arguments

    ; exits if no image/options was supplied
    cmp rax, 1
    je .end

    add rbx, 0x8    ; argv[0] -> argv[1] (because of char **)
    push rbx        ; save argv[1] (image file name)

    ; print argv[1]
    mov rdi, selected_file
    mov rsi, [rbx]
    xor rax, rax
    call printf wrt ..plt

    pop rdi         ; argv[1]
    call get_image_data

    ; print firs pixel red component value
    mov rdi, print_hex
    movzx rsi, byte [rax]
    xor rax, rax
    call printf wrt ..plt

    pop rbp

.end:
    mov rax, 60     ; exit syscall
    xor rdi, rdi    ; EXIT_SUCCESS
    syscall

section .data
    selected_file: db "selected file %s", 0Ah, 0
    print_hex: db "%x", 0Ah, 0
