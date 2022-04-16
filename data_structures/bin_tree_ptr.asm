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

extern malloc
extern free

; typedef struct binary_node {
;     int val
;     struct binary_tree_node *left
;     struct binary_tree_node *right
; } binary_node;

NODEVAL   equ 0
NODELEFT  equ 8
NODERIGHT equ 8*2 
NODESIZ   equ 8*3

;; binary_node *create_node(int val)
create_node:
    push rdi

    push rdi
    mov rdi, NODESIZ
    call malloc
    pop rdi
    test rax, rax
    jz create_node_ret

    mov [rax + NODEVAL], rdi
    xor rdi, rdi                 ; NULL
    mov [rax + NODELEFT], rdi
    mov [rax + NODERIGHT], rdi

create_node_ret:
    pop rdi
    ret


;; void insert_node(binary_node **base, int data)
insert_node:
    push rdi
    push rsi
    push r9

    mov r9, [rdi]

    ;; if (*tree == NULL)
    test r9, r9
    jnz insert_not_null

    ;; *base = create_node(data)
    push rdi
    mov rdi, rsi
    call create_node
    pop rdi
    mov [rdi], rax
    jmp insert_node_ret

insert_not_null:

    ;; if (data < (*tree)->data)
    cmp rsi, [r9 + NODEVAL]
    je insert_node_ret
    jg insert_not_left

    ;;      insert(&(*tree)->left, data);
    lea rdi, [r9 + NODELEFT]
    call insert_node
    jmp insert_node_ret

insert_not_left:

    ;; if (data > (*tree)->data)
    ;;      insert(&(*tree)->right, data);
    lea rdi, [r9 + NODERIGHT]
    call insert_node

insert_node_ret:
    pop r9
    pop rsi
    pop rdi
    ret


;; void delete_tree(binary_node *root)
delete_tree:
    push rdi
    push r8

    mov r8, rdi
    test r8, r8
    jz delete_tree_ret

    mov rdi, [r8 + NODELEFT]
    call delete_tree
    mov rdi, [r8 + NODERIGHT]
    call delete_tree
    mov rdi, r8
    call free

delete_tree_ret:
    pop r8
    pop rdi
    ret


; binary_node* search_tree(binary_node **root, int data)
search_tree:
    push rdi

    mov r9, [rdi]
    test r9, r9 
    jz search_tree_ret

    ;; if (data < (*root)->data)
    cmp rsi, [r9 + NODEVAL]
    je search_equal
    jg search_not_left

    ;;      search(&(*root)->left, data);
    lea rdi, [r9 + NODELEFT]
    call search_tree
    jmp search_tree_ret

search_not_left:

    ;; if (data > (*root)->data)
    ;;      insert(&(*root)->right, data);
    lea rdi, [r9 + NODERIGHT]
    call search_tree
    jmp search_tree_ret

    ;; if (data == (*tree)->data)
    ;;      ret *root
search_equal:
    mov rax, r9

search_tree_ret:
    pop rdi
    ret


