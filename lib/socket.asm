BITS 64

;%include "stdlib.asm"


; uint32_t inet_addr(char* rdi)
inet_addr:
    ; save args
    push rdi
    push rcx 
    push rsi
    push rdx
    push r8
    push 0

    ; counter
    mov rcx, 3
    mov r8, rsp

inet_addr_loop:
    ; get next "."
    mov sil, "."
    call strchr
    test rax, rax
    jz inet_addr_fail
    
    ; strtoul till next "."
    mov rsi, rax
    mov rdx, 0xa
    call strtoul

    ; assert rax < 0xff
    test ah, ah
    jnz inet_addr_fail

    ; put result on stack
    mov [r8], byte al 
    mov rdi, rsi
    inc r8 
    inc rdi
    loop inet_addr_loop

    ; same as above but for nullbyte
    xor sil, sil
    call strchr
    test rax, rax
    jz inet_addr_fail
    mov rsi, rax
    mov rdx, 0xa
    call strtoul
    mov [r8], byte al 

    jmp inet_addr_ret

inet_addr_fail:
    mov qword [rsp], -1

inet_addr_ret:

    ; pop result off stack
    pop rax
    
    ; restore args
    pop r8
    pop rdx
    pop rsi
    pop rcx 
    pop rdi
    ret
    






    



