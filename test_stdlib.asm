BITS 64

%include "lib/stdlib.asm"
%include "lib/socket.asm"

global _start

; constants
section .data
string_const: db "hey, yo?", 0x0
string_const2: db "wtf?", 0x0
gets_prompt: db "Please enter something: ", 0x0
gets_prompt_len equ $-gets_prompt

nstr: db "g",0x0
iip: db "0.255.253.0",0x0

; variables
section .bss
string_var: resb 10

; code
section .text

; arg1 = rdi
; arg2 = rsi
; arg3 = rdx
; arg4 = rcx
; arg5 = r8

_start:

    ; pow test
    mov rdi, 5
    mov rsi, 3
    call pow
    mov rdi, rax
    call itoa
    mov rdi, rax
    call puts

    xor rdi, rdi
    xor rax, rax
    xor rdx, rdx
    inc rdi
    mov rsi, gets_prompt
    mov dl, gets_prompt_len
    mov al, SYS_WRITE
    syscall
    

    ; gets test
    sub rsp, 0x200
    mov rdi, rsp
    add rsp, 0x200
    call gets
    call puts

    ; test string moving 
    mov rdi, string_var
    call puts
    mov rsi, string_const
    call strcpy
    call puts
    mov rsi, string_const2
    call strcpy
    call puts
    mov sil, "5"
    mov rdx, 10
    call memset
    call puts
    mov rsi, string_const
    call memcpy
    call puts

    ; test inet
    mov rdi, iip
    call inet_addr
    cmp rax, 0xfdff00
    mov rdi, 44
    jne exit

    ; test strtoul
    mov rdi, nstr
    xor rsi, rsi
    mov rdx, 17
    call strtoul
    cmp rax, 0x10
    mov rdi, 33
    jne exit

    ; test itoa
    mov rdi, 0b11111111111111111111111111111111  ; 4294967295
    call itoa
    mov rsi, rax
    mov rdi, 1
    mov rdx, 11
    mov rax, SYS_WRITE
    syscall

    ; if argc < 3 exit
    mov rdi, [rsp]
    cmp rdi, 3
    jl exit

    ; if strcmp(argv[1], argv[2]) != 0 
    mov rdi, [rsp+2*8] 
    mov rsi, [rsp+3*8]
    call strcmp
    test rax, rax
    mov rdi, 4
    jnz exit

    ; if atoi(argv[2]) != 123
    mov rdi, rsi
    call atoi
    cmp rax, 123
    jne exit

    ; write(1, argv[1] + "\n", strlen(argv[1] + "\n"))
    call strlen
    mov rdx, rax

    xor rax, rax
    mov rsi, rdi
    mov rdi, 1
    mov [rsi+rdx], byte 0xa         ; add newline '\n'
    inc rdx

    mov al, SYS_WRITE
    syscall
    
    xor rdi, rdi
    call exit


