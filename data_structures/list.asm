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

; list macros
INTSIZ   equ 8
CHUNKSIZ equ 256
LISTSIZ  equ CHUNKSIZ*INTSIZ
;--------- CONSTANTS ---------; 

extern malloc
extern realloc
extern free

; arg1 = rdi
; arg2 = rsi
; arg3 = rdx
; arg4 = rcx
; arg5 = r8

;; struct list {
;;     int len
;;     int *items
;; }

;; struct list *init_list()
list:
    push rdi

    mov rdi, LISTSIZ+1  ; +1 for len
    call malloc
    test rax, rax
    jz list_fail

    mov qword [rax], 0   ; len 

list_fail:
    pop rdi
    ret


;; struct list *append(struct list *l, int val)
append:
    push rdi
    push r8

    ;; if l->len != 0 && (l->len)%CHUNKSIZ == 0: realloc()
    mov r8, [rdi]
    test r8, r8
    jz append_insert
    and r8, CHUNKSIZ-1      ; fast modulo
    test r8, r8
    jnz append_insert

    ;; increase space

    ;; rax = realloc(l, l->len+1+LISTSIZ)
    push rsi
    push rdi

    mov rsi, [rdi]
    inc rsi
    imul rsi, INTSIZ
    add rsi, LISTSIZ
    call realloc

    pop rdi
    pop rsi

    ;; if rax == NULL: ret NULL
    test rax, rax
    jz append_ret

    ;; else: l = rax
    mov rdi, rax

append_insert:
    mov r8, [rdi]
    inc r8 
    mov [rdi + r8*INTSIZ], rsi
    mov [rdi], r8
    mov rax, rdi
    
append_ret:
    pop r8
    pop rdi
    ret


;; int index(struct list *l, int val)
index:
    push r8
    push r9

    mov r8, [rdi]
    xor r9, r9
    inc r9

search:
    cmp [rdi + r9*INTSIZ], rsi
    je index_found
    inc r9
    cmp r9, r8
    jl search

    mov rax, -1
    jmp index_ret

index_found:
    dec r9
    mov rax, r9

index_ret:
    pop r9
    pop r8
    ret
    

;; int list_pop(struct list *l, int idx, int *err)
list_pop:
    push rdi
    push rsi

    ;; if idx > l->len: *err = -1; ret 
    cmp rsi, [rdi]
    jg list_pop_fail

    ;; i = l->len - idx - 1
    mov rcx, [rdi]
    sub rcx, rsi
    dec rcx

    ;; rdi = &l->items[idx]
    lea rdi, [rdi + 1 + rsi*INTSIZ]
    mov rax, [rdi]

    ;; while (i > 0)
list_shift:
    ;;      *rdi = *rdi + 1
    mov rsi, [rdi + INTSIZ]
    mov [rdi], rsi

    ;;      rdi++
    ;;      i--
    add rdi, INTSIZ
    loop list_shift

    mov qword [rdx], 0
    jmp list_pop_ret

list_pop_fail:
    mov qword [rdx], -1

list_pop_ret:
    pop rsi
    pop rdi
    ret


;; struct list *list_insert(struct list *l, int idx, int value)
list_insert:
    push rdi
    push rsi
    push r8
    push r9
    push r10

    mov rax, rdi

    mov r8, [rdi]
    cmp rsi, r8
    jl insert_within_bounds
    mov rsi, r8

    ;; if l->len != 0 && (l->len)%CHUNKSIZ == 0: realloc()
insert_within_bounds:
    test r8, r8
    jz insert_insert

    inc r8
    and r8, CHUNKSIZ-1      ; fast modulo
    test r8, r8
    jnz insert_insert

    ;; increase space
    ;; rax = realloc(l, l->len+1+LISTSIZ)
    push rsi

    mov rsi, [rdi]
    inc rsi
    imul rsi, INTSIZ
    add rsi, LISTSIZ
    call realloc
    test rax, rax
    jz list_insert_ret
    mov rdi, rax

    pop rsi

insert_insert:
    mov r8, [rdi]
    lea r8, [rdi + INTSIZ + r8*INTSIZ]   ; r8 = &l->items[-1]
    lea r9, [rdi + INTSIZ + rsi*INTSIZ]  ; r9 = &l->items[idx]

insert_shift: 
    mov r10, [r8]
    mov [r8 + INTSIZ], r10

    sub r8, INTSIZ
    cmp r8, r9
    jg insert_shift

    mov [r8], rdx

list_insert_ret:
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret


;; void reverse(struct list *l)
reverse:
    push r8
    push r9
    push r10

    mov r8, [rdi]     ; len
    mov r9, r8
    imul r9, INTSIZ
    add r9, rdi       ; &l->items[-1]
    sar r8, 1         ; / 2
    imul r8, INTSIZ
    sub r9, r8        ; r9 -= (len/2) * sizeof(int)
    add r8, INTSIZ    ; r8 = &l->items[(len/2) * sizeof(int)]
    add r8, rdi

rev:
    mov r10, [r8]
    xchg [r9], r10
    mov [r8], r10

    sub r8, INTSIZ
    add r9, INTSIZ

    cmp r8, rdi
    jne rev

    mov rax, r9
    sub rax, rdi

    pop r10
    pop r9
    pop r8
    ret


;; int mod_by_idx(struct list *l, int idx, int val)
mod_by_idx:

    xor rax, rax
    cmp rsi, [rdi]
    jg mod_by_idx_fail

    mov [rdi + 1 + rsi*INTSIZ], rdx
    jmp mod_by_idx_ret                      ; ret 0

mod_by_idx_fail:
    dec rax                                 ; ret -1

mod_by_idx_ret:
    ret


;; int get_by_idx(struct list *l, int idx)
get_by_idx:
    mov rax, [rdi + 1 + rsi*INTSIZ]
    ret


;; void free_list(struct list *l)
free_list:
    call free
    ret
