BITS 64

;--------- CONSTANTS ---------; 

; open macros
O_RDONLY equ 0x0
O_WRONLY equ 0x1
O_CREAT  equ 0x40

;--------- CONSTANTS ---------; 

hex: db "0123456789abcdef"

;; void exit(int rdi)
exit:
    xor rax, rax
    mov al, SYS_EXIT 
    syscall

;; int strcmp(char *rdi, char *rsi)
strcmp:
    ; push and clear
    push dx
    push bx
    push rdi
    push rsi 
    xor rax, rax
    xor rdx, rdx
    xor rbx, rbx

strcmp_loop:
    mov dl, byte [rdi] 
    mov bl, byte [rsi] 

    test dl, dl
    jz test2
    sub dl, bl
    add rax, rdx 
    inc rdi
    inc rsi
    jmp strcmp_loop

test2:
    test bl, bl
    jz strcmp_ret
    sub dl, bl
    add rax, rdx 

strcmp_ret:
    pop rsi 
    pop rdi
    pop bx
    pop dx
    ret

;; int strncmp(char *rdi, char *rsi, int rdx)
strncmp:
    ; push and clear
    push rdx
    push rcx
    push rbx
    push rdi
    push rsi 

    mov rcx, rdx
    xor rax, rax
    xor rdx, rdx
    xor rbx, rbx

strncmp_loop:
    mov dl, byte [rdi] 
    mov bl, byte [rsi] 

    test rcx, rcx
    jz strncmp_ret 
    test dl, dl
    jz testn
    sub dl, bl
    add rax, rdx 
    inc rdi
    inc rsi
    dec rcx
    jmp strncmp_loop

testn:
    test bl, bl
    jz strncmp_ret
    sub dl, bl
    add rax, rdx 

strncmp_ret:
    pop rsi 
    pop rdi
    pop rbx
    pop rcx
    pop rdx
    ret

;; char *strchr(char *rdi, char sil)
strchr:
    push rdi

strchr_loop:
    ; compare byte
    mov dl, byte [rdi]
    cmp dl, sil
    je strchr_ret

    ; check not null
    test dl, dl
    je strchr_fail

    ; loop
    inc rdi
    jmp strchr_loop

strchr_fail:
    ; zero rdi for rax
    xor rdi, rdi 

strchr_ret:
    ; retval
    mov rax, rdi

    ; restore args
    pop rdi
    ret

;; int strlen(char *rdi) 
strlen:
    push rdi

strlen_loop:
    cmp byte [rdi], 0
    je strlen_ret
    inc rdi
    jmp strlen_loop

strlen_ret:
    mov rax, rdi
    pop rdi
    sub rax, rdi
    ret

;; long strtoul(char *rdi, void *rsi, int rdx)
strtoul:
    ; save args
    push rdi
    push rsi
    push rdx
    push rcx
    push r8 
    push r9
    push r10

    ; save base and caculate max char
    mov r9, rdx
    mov r10b, r9b
    add r10b, "0"

   ; check if arg2 is NULL
    test rsi, rsi
    jz strtoul_ptr_null; -------|
    mov rax, rsi             ;  |
    jmp strtoul_len ; --------| |
                             ;| |
strtoul_ptr_null: ; < --------|-|            
    call strchr             ; | 
                            ; |
strtoul_len: ; <--------------|
    sub rax, rdi

    mov r8, rax
    xor rax, rax

; while r8 != 0 
strtoul_loop:
    xor rdx, rdx
    test r8, r8 
    jz strtoul_ret

    ; get char and check numeric
    mov dl, byte [rdi]
    cmp dl, "0" 
    jl strtoul_fail
    cmp dl, "9"
    jl strtoul_convert

strtoul_checkhex_upper:
    sub dl, "A" - "9" - 1
    cmp dl, r10b
    jl strtoul_convert

strtoul_checkhex_lower:
    sub dl, "a" - "A"
    cmp dl, r10b
    jg strtoul_fail

strtoul_convert:
    ; convert to int
    sub rdx, '0'

    ; get power of ten, if 0, skip
    mov rcx, r8
    dec rcx
    test rcx, rcx
    jz strtoul_loop2_end

    ; rax *= 10 ecx times
strtoul_loop2:              
    imul rdx, r9 
    loop strtoul_loop2

    ; pass final int to rax
strtoul_loop2_end:
    add rax, rdx 
    inc rdi
    dec r8 
    jmp strtoul_loop

strtoul_fail:
    mov rax, -1

strtoul_ret:
    pop r10
    pop r9
    pop r8 
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

;; strcat(char *rdi, char *rsi)
strcat:
    push rdi
    push rsi
    push r8

    call strlen
    add rdi, rax

cat_loop:
    mov al, byte [rsi]
    mov [rdi], al
    test al, al
    jz strcat_ret
    inc rsi
    jmp cat_loop

strcat_ret:
    pop r8
    pop rsi
    pop rdi
    ret

;; int atoi(char *rdi)    
atoi:
    ; save args
    push rdi
    
    ; get string length
    call strlen
    mov r8, rax
    xor rax, rax

; while r8 != 0 
atoi_loop:
    xor rdx, rdx
    test r8, r8 
    jz atoi_ret

    ; get char and check numeric
    mov dl, byte [rdi]
    cmp dl, '0' 
    jl atoi_fail
    cmp dl, '9' 
    jg atoi_fail

    ; convert to int
    sub rdx, '0'

    ; get power of ten, if 0, skip
    mov rcx, r8
    dec rcx
    test rcx, rcx
    jz atoi_loop2_end

    ; rax *= 10 ecx times
atoi_loop2:              
    imul rdx, 0xa
    loop atoi_loop2

    ; pass final int to rax
atoi_loop2_end:
    add rax, rdx 
    inc rdi
    dec r8 
    jmp atoi_loop

atoi_fail:
    mov rax, -1

atoi_ret:
    pop rdi
    ret

;; log10(int rdi)
log10:
    xor rax, rax
    bsr rax, rdi
    movzx eax, byte maxdigits[1+rax]
    cmp rdi, qword powers[eax*8]
    sbb al, 0

log10_ret:
    ret

maxdigits:
times 4 db 0
times 3 db 1
times 3 db 2
times 4 db 3
times 3 db 4
times 3 db 5
times 4 db 6
times 3 db 7
times 3 db 8
times 4 db 9
times 3 db 10
times 3 db 11
times 4 db 12
times 3 db 13
times 3 db 14
times 4 db 15
times 3 db 16
times 3 db 17
times 4 db 18
times 3 db 19

powers: dq 0, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000, 1000000000000, 10000000000000, 100000000000000, 1000000000000000, 10000000000000000, 100000000000000000, 1000000000000000000, 10000000000000000000        


;; char *itoa(int rdi)
itoa:
    ; prologue
    push rbp
    mov rbp, rsp
    sub rsp, 0x28     ; 8 for rdi + 19 for max int string + 8 for ret + 1 null byte

    ; save args
    push rdi
    push rcx
    push r8 
    push r9 

    ; get number of digits
    call log10
    mov rcx, rax
    inc rcx

    ; check smaller than max int
    xor r8, r8
    mov r8d, edi 
    cmp r8, rdi
    jne itoa_fail
    
    ; assign vars
    mov r9, rsp
    add r9, 0x1c ; r9 = retstr
    mov r8, 10   ; r8 = 10

    ; put null
    mov [r9+rcx+1], byte 0x00

    ; eax will be used for the div operation
    mov eax, edi

itoa_loop:
    xor edx, edx

    ; this puts eax%10 in edx and divdes eax by 10
    div r8 

    ; make dl a number and put on stack
    add dl, "0"
    mov [r9+rcx], byte dl

    loop itoa_loop

    mov rax, r9
    cmp [r9], byte 0
    jne itoa_ret
    inc rax
    jmp itoa_ret

itoa_fail:
    xor rax, rax 

itoa_ret:
    pop r9 
    pop r8 
    pop rcx
    pop rdi

    leave
    ret

;; int strcpy(char *rdi, char *rsi)
strcpy:
    push rdi
    push rsi
    push r9

strcpy_loop:
    ; get byte, check not zero
    mov r9b, byte [rsi]
    test r9b, r9b
    jz strcpy_loop_end

    mov [rdi], byte r9b
    inc rdi
    inc rsi
    inc rax
    jmp strcpy_loop

strcpy_loop_end:
    pop r9
    pop rsi
    pop rdi
    ret

;; memset(void *rdi, char sil, int rdx)
memset:
    push rdi
    push rcx

    mov rcx, rdx
    
memset_loop:
    mov [rdi], byte sil
    inc rdi
    loop memset_loop

    pop rcx
    pop rdi
    ret

;; memcpy(void *rdi, void *rsi, int rdx)
memcpy:
    push rcx
    push r8

    mov rcx, rdx
    rep movsb 

    pop r8
    pop rcx
    ret

;void puts(char *rdi)
puts:
    push rdi
    push rsi
    push rdx

    call strlen
    mov rdx, rax
    mov rsi, rdi
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall

    push 0xa
    mov rsi, rsp
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall

    add rsp, 0x8
    pop rdx
    pop rsi
    pop rdi
    ret

; char *gets(char *rdi)
gets:
    ; save args
    push rdi
    push rsi
    push rdx

    ; read(0, rdi, 0x20)
    mov rsi, rdi
    xor rdi, rdi
    mov rdx, 0x20

    ; while (rax = (read(0, rdi, 0x20)) > 0)  rsi += rax
gets_loop:
    xor rax, rax
    mov rax, SYS_READ
    syscall

    add rsi, rax
    cmp byte [rsi-1], 0xa
    je gets_line_ret

    cmp rax, 0
    jg  gets_loop
    jmp gets_ret

gets_line_ret:
    mov byte [rsi-1], 0

gets_ret:
    mov rax, rsi

    pop rdx
    pop rsi
    pop rdi

    ret

;; long pow(rdi, rsi)
pow:
    mov r8, rdi
    xor rdi, rdi
    inc rdi

pow2:
    push rdi
    push rsi

    mov rax, rdi

    test rsi, rsi
    je pow_ret

    imul rdi, r8
    dec rsi
    call pow2

pow_ret:
    pop rsi
    pop rdi
    ret


;------------- SYSCALLS ------------; 
SYS_READ                   equ 0x0
SYS_WRITE                  equ 0x1
SYS_OPEN                   equ 0x2
SYS_CLOSE                  equ 0x3
SYS_STAT                   equ 0x4
SYS_FSTAT                  equ 0x5
SYS_LSTAT                  equ 0x6
SYS_POLL                   equ 0x7
SYS_LSEEK                  equ 0x8
SYS_MMAP                   equ 0x9
SYS_MPROTECT               equ 0xa
SYS_MUNMAP                 equ 0xb
SYS_BRK                    equ 0xc
SYS_RT_SIGACTION           equ 0xd
SYS_RT_SIGPROCMASK         equ 0xe
SYS_RT_SIGRETURN           equ 0xf
SYS_IOCTL                  equ 0x10
SYS_PREAD64                equ 0x11
SYS_PWRITE64               equ 0x12
SYS_READV                  equ 0x13
SYS_WRITEV                 equ 0x14
SYS_ACCESS                 equ 0x15
SYS_PIPE                   equ 0x16
SYS_SELECT                 equ 0x17
SYS_SCHED_YIELD            equ 0x18
SYS_MREMAP                 equ 0x19
SYS_MSYNC                  equ 0x1a
SYS_MINCORE                equ 0x1b
SYS_MADVISE                equ 0x1c
SYS_SHMGET                 equ 0x1d
SYS_SHMAT                  equ 0x1e
SYS_SHMCTL                 equ 0x1f
SYS_DUP                    equ 0x20
SYS_DUP2                   equ 0x21
SYS_PAUSE                  equ 0x22
SYS_NANOSLEEP              equ 0x23
SYS_GETITIMER              equ 0x24
SYS_ALARM                  equ 0x25
SYS_SETITIMER              equ 0x26
SYS_GETPID                 equ 0x27
SYS_SENDFILE               equ 0x28
SYS_SOCKET                 equ 0x29
SYS_CONNECT                equ 0x2a
SYS_ACCEPT                 equ 0x2b
SYS_SENDTO                 equ 0x2c
SYS_RECVFROM               equ 0x2d
SYS_SENDMSG                equ 0x2e
SYS_RECVMSG                equ 0x2f
SYS_SHUTDOWN               equ 0x30
SYS_BIND                   equ 0x31
SYS_LISTEN                 equ 0x32
SYS_GETSOCKNAME            equ 0x33
SYS_GETPEERNAME            equ 0x34
SYS_SOCKETPAIR             equ 0x35
SYS_SETSOCKOPT             equ 0x36
SYS_GETSOCKOPT             equ 0x37
SYS_CLONE                  equ 0x38
SYS_FORK                   equ 0x39
SYS_VFORK                  equ 0x3a
SYS_EXECVE                 equ 0x3b
SYS_EXIT                   equ 0x3c
SYS_WAIT4                  equ 0x3d
SYS_KILL                   equ 0x3e
SYS_UNAME                  equ 0x3f
SYS_SEMGET                 equ 0x40
SYS_SEMOP                  equ 0x41
SYS_SEMCTL                 equ 0x42
SYS_SHMDT                  equ 0x43
SYS_MSGGET                 equ 0x44
SYS_MSGSND                 equ 0x45
SYS_MSGRCV                 equ 0x46
SYS_MSGCTL                 equ 0x47
SYS_FCNTL                  equ 0x48
SYS_FLOCK                  equ 0x49
SYS_FSYNC                  equ 0x4a
SYS_FDATASYNC              equ 0x4b
SYS_TRUNCATE               equ 0x4c
SYS_FTRUNCATE              equ 0x4d
SYS_GETDENTS               equ 0x4e
SYS_GETCWD                 equ 0x4f
SYS_CHDIR                  equ 0x50
SYS_FCHDIR                 equ 0x51
SYS_RENAME                 equ 0x52
SYS_MKDIR                  equ 0x53
SYS_RMDIR                  equ 0x54
SYS_CREAT                  equ 0x55
SYS_LINK                   equ 0x56
SYS_UNLINK                 equ 0x57
SYS_SYMLINK                equ 0x58
SYS_READLINK               equ 0x59
SYS_CHMOD                  equ 0x5a
SYS_FCHMOD                 equ 0x5b
SYS_CHOWN                  equ 0x5c
SYS_FCHOWN                 equ 0x5d
SYS_LCHOWN                 equ 0x5e
SYS_UMASK                  equ 0x5f
SYS_GETTIMEOFDAY           equ 0x60
SYS_GETRLIMIT              equ 0x61
SYS_GETRUSAGE              equ 0x62
SYS_SYSINFO                equ 0x63
SYS_TIMES                  equ 0x64
SYS_PTRACE                 equ 0x65
SYS_GETUID                 equ 0x66
SYS_SYSLOG                 equ 0x67
SYS_GETGID                 equ 0x68
SYS_SETUID                 equ 0x69
SYS_SETGID                 equ 0x6a
SYS_GETEUID                equ 0x6b
SYS_GETEGID                equ 0x6c
SYS_SETPGID                equ 0x6d
SYS_GETPPID                equ 0x6e
SYS_GETPGRP                equ 0x6f
SYS_SETSID                 equ 0x70
SYS_SETREUID               equ 0x71
SYS_SETREGID               equ 0x72
SYS_GETGROUPS              equ 0x73
SYS_SETGROUPS              equ 0x74
SYS_SETRESUID              equ 0x75
SYS_GETRESUID              equ 0x76
SYS_SETRESGID              equ 0x77
SYS_GETRESGID              equ 0x78
SYS_GETPGID                equ 0x79
SYS_SETFSUID               equ 0x7a
SYS_SETFSGID               equ 0x7b
SYS_GETSID                 equ 0x7c
SYS_CAPGET                 equ 0x7d
SYS_CAPSET                 equ 0x7e
SYS_RT_SIGPENDING          equ 0x7f
SYS_RT_SIGTIMEDWAIT        equ 0x80
SYS_RT_SIGQUEUEINFO        equ 0x81
SYS_RT_SIGSUSPEND          equ 0x82
SYS_SIGALTSTACK            equ 0x83
SYS_UTIME                  equ 0x84
SYS_MKNOD                  equ 0x85
SYS_USELIB                 equ 0x86
SYS_PERSONALITY            equ 0x87
SYS_USTAT                  equ 0x88
SYS_STATFS                 equ 0x89
SYS_FSTATFS                equ 0x8a
SYS_SYSFS                  equ 0x8b
SYS_GETPRIORITY            equ 0x8c
SYS_SETPRIORITY            equ 0x8d
SYS_SCHED_SETPARAM         equ 0x8e
SYS_SCHED_GETPARAM         equ 0x8f
SYS_SCHED_SETSCHEDULER     equ 0x90
SYS_SCHED_GETSCHEDULER     equ 0x91
SYS_SCHED_GET_PRIORITY_MAX equ 0x92
SYS_SCHED_GET_PRIORITY_MIN equ 0x93
SYS_SCHED_RR_GET_INTERVAL  equ 0x94
SYS_MLOCK                  equ 0x95
SYS_MUNLOCK                equ 0x96
SYS_MLOCKALL               equ 0x97
SYS_MUNLOCKALL             equ 0x98
SYS_VHANGUP                equ 0x99
SYS_MODIFY_LDT             equ 0x9a
SYS_PIVOT_ROOT             equ 0x9b
SYS__SYSCTL                equ 0x9c
SYS_PRCTL                  equ 0x9d
SYS_ARCH_PRCTL             equ 0x9e
SYS_ADJTIMEX               equ 0x9f
SYS_SETRLIMIT              equ 0xa0
SYS_CHROOT                 equ 0xa1
SYS_SYNC                   equ 0xa2
SYS_ACCT                   equ 0xa3
SYS_SETTIMEOFDAY           equ 0xa4
SYS_MOUNT                  equ 0xa5
SYS_UMOUNT2                equ 0xa6
SYS_SWAPON                 equ 0xa7
SYS_SWAPOFF                equ 0xa8
SYS_REBOOT                 equ 0xa9
SYS_SETHOSTNAME            equ 0xaa
SYS_SETDOMAINNAME          equ 0xab
SYS_IOPL                   equ 0xac
SYS_IOPERM                 equ 0xad
SYS_CREATE_MODULE          equ 0xae
SYS_INIT_MODULE            equ 0xaf
SYS_DELETE_MODULE          equ 0xb0
SYS_GET_KERNEL_SYMS        equ 0xb1
SYS_QUERY_MODULE           equ 0xb2
SYS_QUOTACTL               equ 0xb3
SYS_NFSSERVCTL             equ 0xb4
SYS_GETPMSG                equ 0xb5
SYS_PUTPMSG                equ 0xb6
SYS_AFS_SYSCALL            equ 0xb7
SYS_TUXCALL                equ 0xb8
SYS_SECURITY               equ 0xb9
SYS_GETTID                 equ 0xba
SYS_READAHEAD              equ 0xbb
SYS_SETXATTR               equ 0xbc
SYS_LSETXATTR              equ 0xbd
SYS_FSETXATTR              equ 0xbe
SYS_GETXATTR               equ 0xbf
SYS_LGETXATTR              equ 0xc0
SYS_FGETXATTR              equ 0xc1
SYS_LISTXATTR              equ 0xc2
SYS_LLISTXATTR             equ 0xc3
SYS_FLISTXATTR             equ 0xc4
SYS_REMOVEXATTR            equ 0xc5
SYS_LREMOVEXATTR           equ 0xc6
SYS_FREMOVEXATTR           equ 0xc7
SYS_TKILL                  equ 0xc8
SYS_TIME                   equ 0xc9
SYS_FUTEX                  equ 0xca
SYS_SCHED_SETAFFINITY      equ 0xcb
SYS_SCHED_GETAFFINITY      equ 0xcc
SYS_SET_THREAD_AREA        equ 0xcd
SYS_IO_SETUP               equ 0xce
SYS_IO_DESTROY             equ 0xcf
SYS_IO_GETEVENTS           equ 0xd0
SYS_IO_SUBMIT              equ 0xd1
SYS_IO_CANCEL              equ 0xd2
SYS_GET_THREAD_AREA        equ 0xd3
SYS_LOOKUP_DCOOKIE         equ 0xd4
SYS_EPOLL_CREATE           equ 0xd5
SYS_EPOLL_CTL_OLD          equ 0xd6
SYS_EPOLL_WAIT_OLD         equ 0xd7
SYS_REMAP_FILE_PAGES       equ 0xd8
SYS_GETDENTS64             equ 0xd9
SYS_SET_TID_ADDRESS        equ 0xda
SYS_RESTART_SYSCALL        equ 0xdb
SYS_SEMTIMEDOP             equ 0xdc
SYS_FADVISE64              equ 0xdd
SYS_TIMER_CREATE           equ 0xde
SYS_TIMER_SETTIME          equ 0xdf
SYS_TIMER_GETTIME          equ 0xe0
SYS_TIMER_GETOVERRUN       equ 0xe1
SYS_TIMER_DELETE           equ 0xe2
SYS_CLOCK_SETTIME          equ 0xe3
SYS_CLOCK_GETTIME          equ 0xe4
SYS_CLOCK_GETRES           equ 0xe5
SYS_CLOCK_NANOSLEEP        equ 0xe6
SYS_EXIT_GROUP             equ 0xe7
SYS_EPOLL_WAIT             equ 0xe8
SYS_EPOLL_CTL              equ 0xe9
SYS_TGKILL                 equ 0xea
SYS_UTIMES                 equ 0xeb
SYS_VSERVER                equ 0xec
SYS_MBIND                  equ 0xed
SYS_SET_MEMPOLICY          equ 0xee
SYS_GET_MEMPOLICY          equ 0xef
SYS_MQ_OPEN                equ 0xf0
SYS_MQ_UNLINK              equ 0xf1
SYS_MQ_TIMEDSEND           equ 0xf2
SYS_MQ_TIMEDRECEIVE        equ 0xf3
SYS_MQ_NOTIFY              equ 0xf4
SYS_MQ_GETSETATTR          equ 0xf5
SYS_KEXEC_LOAD             equ 0xf6
SYS_WAITID                 equ 0xf7
SYS_ADD_KEY                equ 0xf8
SYS_REQUEST_KEY            equ 0xf9
SYS_KEYCTL                 equ 0xfa
SYS_IOPRIO_SET             equ 0xfb
SYS_IOPRIO_GET             equ 0xfc
SYS_INOTIFY_INIT           equ 0xfd
SYS_INOTIFY_ADD_WATCH      equ 0xfe
SYS_INOTIFY_RM_WATCH       equ 0xff
SYS_MIGRATE_PAGES          equ 0x100
SYS_OPENAT                 equ 0x101
SYS_MKDIRAT                equ 0x102
SYS_MKNODAT                equ 0x103
SYS_FCHOWNAT               equ 0x104
SYS_FUTIMESAT              equ 0x105
SYS_NEWFSTATAT             equ 0x106
SYS_UNLINKAT               equ 0x107
SYS_RENAMEAT               equ 0x108
SYS_LINKAT                 equ 0x109
SYS_SYMLINKAT              equ 0x10a
SYS_READLINKAT             equ 0x10b
SYS_FCHMODAT               equ 0x10c
SYS_FACCESSAT              equ 0x10d
SYS_PSELECT6               equ 0x10e
SYS_PPOLL                  equ 0x10f
SYS_UNSHARE                equ 0x110
SYS_SET_ROBUST_LIST        equ 0x111
SYS_GET_ROBUST_LIST        equ 0x112
SYS_SPLICE                 equ 0x113
SYS_TEE                    equ 0x114
SYS_SYNC_FILE_RANGE        equ 0x115
SYS_VMSPLICE               equ 0x116
SYS_MOVE_PAGES             equ 0x117
SYS_UTIMENSAT              equ 0x118
SYS_EPOLL_PWAIT            equ 0x119
SYS_SIGNALFD               equ 0x11a
SYS_TIMERFD_CREATE         equ 0x11b
SYS_EVENTFD                equ 0x11c
SYS_FALLOCATE              equ 0x11d
SYS_TIMERFD_SETTIME        equ 0x11e
SYS_TIMERFD_GETTIME        equ 0x11f
SYS_ACCEPT4                equ 0x120
SYS_SIGNALFD4              equ 0x121
SYS_EVENTFD2               equ 0x122
SYS_EPOLL_CREATE1          equ 0x123
SYS_DUP3                   equ 0x124
SYS_PIPE2                  equ 0x125
SYS_INOTIFY_INIT1          equ 0x126
SYS_PREADV                 equ 0x127
SYS_PWRITEV                equ 0x128
SYS_RT_TGSIGQUEUEINFO      equ 0x129
SYS_PERF_EVENT_OPEN        equ 0x12a
SYS_RECVMMSG               equ 0x12b
SYS_FANOTIFY_INIT          equ 0x12c
SYS_FANOTIFY_MARK          equ 0x12d
SYS_PRLIMIT64              equ 0x12e
SYS_NAME_TO_HANDLE_AT      equ 0x12f
SYS_OPEN_BY_HANDLE_AT      equ 0x130
SYS_CLOCK_ADJTIME          equ 0x131
SYS_SYNCFS                 equ 0x132
SYS_SENDMMSG               equ 0x133
SYS_SETNS                  equ 0x134
SYS_GETCPU                 equ 0x135
SYS_PROCESS_VM_READV       equ 0x136
SYS_PROCESS_VM_WRITEV      equ 0x137
SYS_KCMP                   equ 0x138
SYS_FINIT_MODULE           equ 0x139
;------------- SYSCALLS ------------; 
