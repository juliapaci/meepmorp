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

; https://en.wikipedia.org/wiki/HSL_and_HSV
; args rgb (first 3 bytes of %rdi) to hsv
; returned in (rax, rbx, rcx) -> (h, s, v)
; hue in degrees [0, 360]
rgb_to_hsv:
    mov eax, edi
    shr eax, 0x10 ; b
    ; (dl, dh, al) -> (r, g, b)

    xor bx, bx
    ; %bl = min(r, g, b)
    cmp dl, dh
    cmovl bl, dl
    cmp bl, al
    cmovl bl, al
    ; %bh = max(r, g, b)
    cmp dl, dh
    cmovg bh, dl
    cmp bh, al
    cmovg bh, al

    ; %cl = delta hue (c)
    mov cl, bh
    sub cl, bl

    ; Hue
    cvtsi2sd xmm1, cl

    cmp bh, bl
    je .zero
    cmp bh, dl
    je .red
    cmp bh, dh
    je .green
    cmp bh, al
    je .blue

    .zero:  ; prevent divide by zero
        ; undefined
        xor r8b, r8b
        jmp .hue_end

    .red: ; (g - b)/c % 6
        movzx r8b, dh
        sub r8b, al

        cvtsi2sd xmm0, r8b
        divsd xmm0, xmm1

        ._mod_six_loop:
            comisd xmm0, 0x06
            jb .hue_end
            subsd xmm0, 0x06
            jmp ._mod_six_loop

    .green: ; (b - r)/c + 2
        movzx r8b, al
        sub r8b, dl

        cvtsi2sd xmm0, r8b
        divsd xmm0, xmm1

        addsd xmm0, 0x02
        jmp .hue_end
    .blue: ; (r - g)/c + 4
        movzx r8b, dl
        sub r8b, dh

        cvtsi2sd xmm0, r8b
        divsd xmm0, xmm1

        addsd xmm0, 0x04
        jmp .hue_end

    .hue_end:
        movsd xmm2, 0x3c
        mulsd xmm0, xmm2
        cvttsd2si eax, xmm0

    ; Saturation
    ; c/max(r, g, b)
    ; TODO: check for c = 0 -> s = 0
    cvtsi2sd xmm0, bh
    divsd xmm1, xmm0
    cvttsd2si rbx, xmm1

    ; Value
    ; max(r, g, b)
    movzx rcx, bh

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
    mov r8, 3           ; req_comp = 3 (rgb)
    call stbi_load      ; rax = pixel byte buffer
    ; TODO: check stb errors
    ; TODO: free

    add rsp, 0x10

    pop rbp
    ret

; random number between 0 and rsi using 32 bit xorshift
; does not use `getrandom` syscall
; returns a single integer in rax (eax because 32 bit image dimensions) based on seed in rdi
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


    call random
    ; prints a random number
    mov rdi, print_hex
    mov rsi, rax
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
