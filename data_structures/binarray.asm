BITS 64


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
;--------- CONSTANTS ---------; 

global _start

; constants
;section .data

; variables 
;section .bss

; code
section .text

; arg1 = rdi
; arg2 = rsi
; arg3 = rdx
; arg4 = rcx
; arg5 = r8

;; int parent(int i)
parent:
    mov rax, rdi

    dec rax     ; (i - 1)
    sar rax, 1  ; / 2

    ret


;; int left_child(int i)
left_child:
    mov rax, rdi

    imul rax, 2
    inc rax

    ret


;; int right_child(int i)
right_child:
    mov rax, rdi

    imul rax, 2
    add rax, 2

    ret


;; void swap(int *a, int *b)
swap:
    mov rax, [rdi]
    xchg [rsi], rax
    mov [rdi], rax
    ret


;; void insert(int a[], int data, int *n)
insert:
    push rdi
    push rsi
    push r8
    push r9
    push r10

    mov r9, rdi

    ;; a[*n] = data;
    ;; *n = *n + 1;
    mov rax, [rdx]
    mov r8, rax             ; i = *n
    mov [rdi + rax*8], rsi
    inc rax
    mov [rdx], rax

heap_loop:
    ;; while (i != 0 && 
    test r8, r8
    jz insert_ret

    ;; a[parent(i)] < a[i])
    mov rdi, r8
    call parent
    mov r10, [r9 + r8*8]
    cmp [r9 + rax*8], r10
    jge insert_ret

    ;; swap(&a[parent(i)], &a[i])
    mov rdi, r9
    add rdi, rax
    mov rsi, r9
    add rsi, r8

    ;; i = parent(i)
    mov r8, rax
    call swap
    jmp heap_loop
    
insert_ret:
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret


;; void max_heapify(int a[], int i, int n)
max_heapify:
    push rdi
    push rsi
    push r8
    push r9
    push r10
    push r11
    
    mov r8, rdi

    ;; int left = left_child(i); (r10)
    ;; int right = right_child(i); (r11)
    mov rdi, rsi
    call left_child
    mov r10, rax
    call right_child
    mov r11, rax

    ;; int largest = i; (r9)
    mov r9, rsi

    ;; if (left <= n &&
    cmp r10, rdx
    jg left_not_larger

    ;; a[left] > a[largest])
    mov rax, [r8 + r9*8]
    cmp [r8 + r10*8], rax
    jle left_not_larger

    ;;      largest = left;
    mov r9, r10

left_not_larger:

    ;; if (right <= n && 
    cmp r11, rdx
    jg right_not_larger

    ;;a[right] > a[largest]) {
    mov rax, [r8 + r9*8]
    cmp [r8 + r11*8], rax
    jle right_not_larger

    ;;      largest = right;
    mov r9, r11

right_not_larger:

    ; if (largest != i) {
    cmp r9, rsi
    je i_not_largest

    mov rax, [r8 + rsi*8]
    xchg [r8 + r9*8], rax
    mov [r8 + rsi*8], rax
    mov rdi, r8
    mov rsi, r9
    call max_heapify

i_not_largest:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret


;; void build_max_heap(int a[], int n)
build_max_heap:
    push rsi
    push rcx

    ;; i = n/2
    mov r9, rsi
    sar rsi, 1

    ;; while (i >= 0)
build_max_heap_loop:
    cmp rsi, 0
    jl build_max_heap_loop_end

    ;;      max_heapify(a, i, n)
    mov rdx, r9
    call max_heapify
    dec rsi
    jmp build_max_heap_loop

build_max_heap_loop_end:
    pop rcx
    pop rsi
    ret


;; extract_max(int a[], int *n)
extract_max:
    push rsi
    push r8

    mov r8, [rdi]
    
    ;; *n = *n - 1;
    mov rax, [rsi]
    dec rax
    mov [rsi], rax

    ;; a[0] = a[*n - 1];
    mov rax, [rdi + rax*8]
    mov [rdi], rax
    
    ;; max_heapify(a, 0, *n);
    xor rsi, rsi
    mov rdx, rax
    call max_heapify

    mov rax, r8

    pop r8
    pop rsi
    ret


