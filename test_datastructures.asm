BITS 64

; ----------------- test.asm ----------------
;    
;    tests basic list structure
;    binary heap array
;    binary heap with pointers
;    various list operations
;
;    PIPE OUTPUT TO xxd OR hexdump 
;
; -------------------------------------------

;--------- CONSTANTS ---------; 

; file syscall numbers
SYS_WRITE   equ 0x1         
SYS_READ    equ 0x0         
SYS_CLOSE   equ 0x3         
SYS_EXIT    equ 0x3c        
SYS_OPEN    equ 0x2         

; open macros
O_RDONLY equ 0x0
O_WRONLY equ 0x1
O_CREAT  equ 0x40
BUFSIZ   equ 0x2000

; stat macros
SYS_FSTAT equ 0x5

S_IFIFO      equ 0x1000
S_IFMT       equ 0xf000
ST_MODE_OSET equ 0x18
STATSIZ      equ 0x90
;--------- CONSTANTS ---------; 

%include "data_structures/list.asm"
%include "data_structures/binarray.asm"
%include "data_structures/bin_tree_ptr.asm"

global main

; constants
section .data
    warning: db "Pipe output to hexdumper like hexdump or xxd to protect your teminal", 0xa
    warning_len equ $-warning

    info1: db 0xa, "Big list:", 0xa, "---------", 0xa
    info1_len equ $-info1
    info2: db 0xa, "Reversed", 0xa, "---------", 0xa
    info2_len equ $-info2
    info3: db 0xa, "Binary heap", 0xa, "---------", 0xa
    info3_len equ $-info3

    info4: db 0xa, "Created binary tree size 0x5000", 0xa, "---------", 0xa
    info4_len equ $-info4
    info5: db 0xa, "Found number '25' in binary tree", 0xa, "---------", 0xa
    info5_len equ $-info5


; variables 
;section .bss

; code
section .text

; arg1 = rdi
; arg2 = rsi
; arg3 = rdx
; arg4 = rcx
; arg5 = r8

;; ---- stack -- | vars @ rbp + 
head               equ 0x0
err                equ 0x8
stat               equ err + 0x8
stackspace         equ stat + STATSIZ
;; ------------- | 
main:

    ;;  allocate stack
    push rbp
    mov rbp, rsp
    sub rsp, stackspace

    ;; stat stdout file descriptor
    xor rax, rax
    xor rdi, rdi
    inc rdi
    lea rsi, [rbp + stat]
    mov al, SYS_FSTAT
    syscall
    test rax, rax
    jnz broke

    ;; check output is piped
    mov rax, [rbp + stat + ST_MODE_OSET]
    and rax, S_IFMT
    cmp rax, S_IFIFO
    je test_list

    ;; warn and exit if not
    xor rax, rax
    xor rdi, rdi
    inc rdi
    mov rsi, warning
    mov rdx, warning_len
    mov al, SYS_WRITE
    syscall
    jmp broke


    ;; --------------- list and binary heap array -----
test_list:

    ;; initialise list
    call list 
    mov [rbp + head], rax

    ;; append 0x500000 integers
    mov rdi, [rbp + head]
    mov r8, 0x500000
    mov rdx, 8
fill_list:
    mov rsi, r8
    call append
    test rax, rax
    jz broke
    mov rdi, rax 
    dec r8
    test r8, r8
    jnz fill_list
    mov [rbp + head], rdi

    ;; print
    mov rdi, 2
    mov rsi, info1
    mov rdx, info1_len
    mov rax, SYS_WRITE
    syscall
    dec rdi
    mov rsi, [rbp + head]
    mov rdx, 8*20 
    mov rax, SYS_WRITE
    syscall


    ;; reverse array
    mov rdi, [rbp + head]
    call reverse

    ;; print
    mov rdi, 2
    mov rsi, info2
    mov dl, info2_len
    mov rax, SYS_WRITE
    syscall
    dec rdi
    mov rsi, [rbp + head]
    mov rdx, 8*20 
    mov rax, SYS_WRITE
    syscall


    ;; create binary heap
    mov rdi, rsi
    add rdi, 8
    mov rsi, [rsi]
    call build_max_heap

    ;; print 
    mov rdi, 2
    mov rsi, info3
    mov rdx, info3_len
    mov rax, SYS_WRITE
    syscall
    dec rdi
    mov rsi, [rbp + head]
    mov rdx, 8*20 
    mov rax, SYS_WRITE
    syscall


    ;; test pop
    mov rdi, [rbp + head]
    mov rsi, 4000
    lea rdx, [rbp + err]
    call list_pop

    cmp qword [rdx], -1
    je broke


    ;; test insert
    mov rdi, [rbp + head]
    mov rsi, 4000
    mov rdx, 20
    call list_insert

    test rax, rax
    jz broke

    mov [rbp + head], rax


    ;; free allocated memory
    mov rdi, [rbp + head]
    call free_list
    ;; ------------------------------------------------


    ;; ------------------ pointer based binary heap ----

    ;; reuse variables
    xor rax, rax
    mov [rbp + head], rax    ;; head = NULL


    ;; fill tree with 0x5000 integers (too slow for more)
    lea rdi, [rbp + head]
    mov rsi, 0x5000
fill_tree:
    call insert_node
    dec rsi
    test rsi, rsi
    jnz fill_tree

    ;; print info
    mov rdi, 2
    mov rsi, info4
    mov rdx, info4_len
    mov rax, SYS_WRITE
    syscall
 

    ;; search tree for '25' (fast)
    lea rdi, [rbp + head]
    mov rsi, 25
    call search_tree

    cmp qword [rax + NODEVAL], 25
    jne broke

    mov rdi, 2
    mov rsi, info5
    mov rdx, info5_len
    mov rax, SYS_WRITE
    syscall
 

    ;; free allocated memory
    mov rdi, [rbp + head]
    call delete_tree
    ;; ------------------------------------------------


    ;; exit success
    xor rdi, rdi
    jmp exit

    ;; exit failure
broke:
    mov rdi, 1

exit:
    xor rax, rax
    mov al, SYS_EXIT 
    syscall

