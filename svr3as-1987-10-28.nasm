;
; svr3as-1987-10-28.nasm: a Linux i386 port of the SVR3 3.2 SDS 4.1 1987-10-28 (1987-10.1) i386 assembler as(1)
; by pts@fazekas.hu at Mon Oct 28 00:13:49 CET 2024
;
; Compile with: nasm -w+orphan-labels -f bin -O0 -o svr3as-1987-10-28 svr3as-1987-10-28.nasm && chmod +x svr3as-1987-10-28
; Run on Linux (creating test.o of COFF format): ./svr3as-1987-10-28 -dt test.s && cmp -l test.o.good test.o
;
; This program runs natively on Linux i386 and Linux amd64 systems, even
; those which have `sysctl -w vm.mmap_min_addr=65536' (like many Linux
; distributions in 2018). (For that, the 2nd argument of define.xtext must
; be at least 0x10000).
;
; This program creates (and removes) up to 15 temporary files (in `$TMPDIR'
; or `/tmp') during normal operation.
;
;

%if 0

%else


  %include 'binpatch.inc.nasm'

  ; `objdump -x' output (Size mostly incorrect):
  ; Idx Name          Size      VMA       File off  Algn
  ;   0 .text         0x00fed8  0x0000d0  0x0000d0  2**2  CONTENTS, ALLOC, LOAD, READONLY, CODE, NOREAD
  ;   1 .data         0x00b294  0x400fa8  0x00ffa8  2**2  CONTENTS, ALLOC, LOAD, READONLY, DATA, NOREAD
  ;   2 .bss          0x40c23c  0x40c23c  0x000000  2**2  ALLOC, READONLY, NOREAD
  ;   3 .comment      0x000030  0x000000  0x01b23c  2**2  CONTENTS, READONLY, DEBUGGING, NOREAD

  define.xbin 'svr3as-1987-10-28.svr3'
  define.xtext 0x00ff34, 0x3f0074, 0x000074
  define.xdata 0x00b294, 0x400fa8, 0x00ffa8, 0x00b294+0x10f40
  opt.o0  ; Make NASM compilation faster. For this file the output is the same
%endif

; Holes in the input file:
;
; TODO(pts): Write it.
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;

main requ 0x3f0450
_cleanup requ 0x3ff484
environ requ 0x400fa8
errno requ 0x40c21c
dlflag requ 0x40abc0

; SYSV SVR3 i386 syscall numbers.
;
; Linux i386 syscall numbers are the same, except when indicated.
SYS_EXIT equ 1
SYS_FORK equ 2
SYS_READ equ 3
SYS_WRITE equ 4
SYS_OPEN equ 5  ; Linux has different values for O_CREAT and O_APPEND.
SYS_CLOSE equ 6
SYS_WAIT equ 7  ; On Linux, SYS_waitpid is 7, there is no SYS_wait.
SYS_UNLINK equ 10
SYS_TIME equ 13  ; Result should be checked differently.
SYS_BRK equ 17  ; On Linux, SYS_break is 17, and is unimplemented. SYS_brk is 45, and has a bit different semantics.
SYS_LSEEK equ 19
SYS_GETPID equ 20
SYS_FSTAT equ 28  ; On Linux, SYS_oldfstat is 28. SYS_fstat is is 108.
SYS_ACCESS equ 33
SYS_KILL equ 37
SYS_SIGNAL equ 48  ; The Linux syscall 48 matches the SYSV behavior (not the BSD behavior). Good.
SYS_IOCTL equ 54  ; The ioctl(2) requests are incompatible with Linux.
SYS_EXECVE equ 59  ; On Linux, SYS_execve is 11.

; Linux i386 syscall numbers different from SYSV SVR3 i386 syscall numbers.
SYS_waitpid equ 7
SYS_execve equ 11
SYS_brk equ 45
SYS_sigaction equ 67
SYS_fstat equ 108

; SYSV SVR3 i386 open(2) flags constants.
O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2
O_TRUNC equ 1000q
O_CREAT equ 400q  ; Linux i386 has 100q.
O_APPEND equ 10q  ; Linux i386 has 2000q.

; Linux i386 open(2) flag constants different from SYSV SVR3 i386 values.
Linux_O_CREAT equ 100q
Linux_O_APPEND equ 2000q

; Error codes (errnum, errno numbers): the values listed here are the same in SYSV SVR i386 and Linux i386.
ENOENT equ 2
EDOM equ 33
ERANGE equ 34

; lseek(2) whence constants, for both SYSV SVR3 i386 and Linux.
SEEK_SET equ 0
SEEK_CUR equ 1
SEEK_END equ 2

; access(2) mode constants, for both SYSV SVR3 i386 and Linux.
F_OK equ 0
X_OK equ 1
W_OK equ 2
R_OK equ 4

; signal(2) signum constants, for both SYSV SVR3 i386 and Linux.
SIGHUP equ 1
SIGINT equ 2
SIGFPE equ 8
SIGTERM equ 15

; signal(2) handler constants, for both SYSV SVR3 i386 and Linux.
SIG_DFL equ 0
SIG_IGN equ 1

; sigaction(2) constants for Linux i386.
Linux_SA_RESTART equ 0x10000000

STDIN_FILENO equ 0
STDOUT_FILENO equ 1
STDERR_FILENO equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1
EXIT_FAILURE_100 equ 100
EXIT_EMU_FATAL equ 125
EXIT_FATAL equ 127

; Linux i386 ioctl(2) request constants.
Linux_TCGETS equ 0x5401  ; 'T'<<8|1.

%macro li3_syscall 0  ; Linux i386 syscall.
  int 0x80
%endm

%macro ru 1  ; Relocates pointer-to-.text value 0x0000???? to 0x003f????.
  iu %1  ; Like `incbin_until %1', but faster, because it doesn't do any address checks.
  db 0x3f
%endm
%macro r 2  ; Relocates pointer-to-.text values %1..%2 (inclusive, countiny by 4).
  %assign __ra (%1)  ; First address.
  %assign __rb (%2)  ; Last address.
  %rep ((__rb-__ra)>>2)+1
    iu __ra
    db 0x3f
    %assign __ra __ra+4
  %endrep
%endm

section .xtext
  incbin_until 0x3f0074
    global _start
    _start:
    ; We skip the initialization of the ctype table (setchrclass).
    pop eax  ; argc.
    mov edx, esp  ; argv.
    lea ecx, [edx+eax*4+4]  ; envp.
    mov [environ], ecx
    push edx  ; Argument argv for main.
    push eax  ; Argument argc for main.
    call main
    ;add esp, strict byte 3*4  ; Clean up arguments of main above. Not needed, we are just about to exit.
    push eax  ; Exit code returned by main.
    call exit  ; Flushes stdout etc., then exits. Doesn't return.
    assert_at _start+0x1a

    simple_syscall3:
    ; Implements a SYSV SVR3 syscall using a Linux i386 syscall the simplest
    ; way possible:
    ; * Input: dword [esp]: is the Linux syscall number. Any negative Linux result
    ;   indicates failure. This function will pop it.
    ; * Input: dword [esp+4]: The function return address.
    ; * Input: dword [esp+2*4]: First argument. Caller will pop it.
    ; * Input: dword [esp+3*4]: Second argument. Caller will pop it.
    ; * Input: dword [esp+4*4]: Third argument. Caller will pop it. At most
    ;   3 argumets are supported.
    ; * Output: EAX: result. -1 on failure.
    ; * Ruins: ECX and EDX.
    pop eax  ; Linux i386 syscall number.
    .in_eax:
    push ebx  ; Save.
    mov ebx, [esp+2*4]
    mov ecx, [esp+3*4]
    .edx_do:
    mov edx, [esp+4*4]
    .do:
    li3_syscall
    pop ebx  ; Restore.
    test eax, eax
    jns strict short .ret
    ;neg eax
    ;mov [errno], eax  ; Not needed, this program doesn't use it.
    or eax, strict byte -1  ; EAX := -1.
    .ret: ret

    fix_sys_open_cont:
    ;mov edx, [esp+4*4]  ; mode. .edx_do will do it.
    ; Now we need to change flag bitmasks in ECX: O_CREAT (400q) to 100q and O_APPEND (10q) to 2000q.
    test ch, O_CREAT>>8  ; O_CREAT.
    jz strict short .d1
    and ch, ~(O_CREAT>>8)
    or cl, Linux_O_CREAT
    .d1:
    test cl, O_APPEND
    jz strict short .d2
    and cl, ~O_APPEND
    or ch, Linux_O_APPEND>>8
    .d2:
    jmp strict short simple_syscall3.edx_do

    %if 0  ; These functions are only needed for debugging.
    emu_fatal_unsupported_syscall:
    ; Input: syscall number in AL.
    ;push eax  ; Not needed, we'll be exiting anyway.
    mov ah, 0
    shl eax, 16
    add eax, 'U' | 'S'<<8 | ' '<<16 | 10<<24  ; For example, "US!\n" means syscall 33 - 32 == 1 (SYS_EXIT).
    call write_eax_to_stderr
    ;pop eax  ; Not needed, we are exiting anyway.
    ; Fall through to emu_fatal.

    emu_fatal:
    xor eax, eax
    inc eax  ; EAX := SYS_EXIT.
    push strict byte EXIT_EMU_FATAL
    pop ebx
    li3_syscall  ; Doesn't return.

    write_eax_to_stderr:
    pusha
    lea ecx, [esp+7*4]  ; Points to the value of EAX.
    ;push eax  ; Push 4-byte message to the stack.
    ;mov ecx, esp
    push strict byte SYS_WRITE
    pop eax
    push STDERR_FILENO
    pop ebx
    push strict byte 4
    pop edx
    li3_syscall
    ;pop eax  ; Remove 4-byte message from the stack.
    popa
    ret
    %endif  ; Not needed.

    fill_until 0x3f011c
  incbin_until 0x3f01a4
    ; This is original functionality: checks for 'l', sets dlflag to 1, then jumps to flagcont (0x3f02e6).
    getargs__dflag:
    jmp_to_flagcont equ $+0x196-0x1a4
    cmp al, 'l'
    jne strict short .not_l
    mov byte [dlflag], 1
    jmp strict short jmp_to_flagcont
    .not_l:
    cmp al, 't'  ; New functionality: Set timestamp in coff_filehdr_f_timdat to 0, for reproducible builds.
    jne strict short jmp_to_flagcont
    and dword [coff_filehdr_f_timdat], strict byte 0
    jmp strict short jmp_to_flagcont
    fill_until 0x3f01c0
  incbin_until 0x3f060c
    run_m4:  ; Called when the `-m' command-line flag is specified.
    ; We don't support running m4 on Linux, because the Linux system
    ; typically doesn't have the needed macro files `/lib/cm4defs' and
    ; `/lib/cm4tvdefs'.
    jmp strict short .die
    fill_until 0x3f0687
    .die:  ; Print error message msg_m4_error and die.
  ru 0x3f6085
  ru 0x3f60a4
  ru 0x3f60c3
  incbin_until 0x3f63eb
    ; fstat(...) call in init_cmd_and_symbol_hash(...).
    incbin_until 0x3f63eb
    sub esp, strict byte 0x40  ; Linux `struct stat' is 0x40 bytes.
    assert_addr 0x3f63ee
    incbin_until 0x3f6425
    lea eax, [ebp-0x40]  ; &st.
    assert_addr 0x3f6428
    incbin_until 0x3f643b
    mov eax, [ebp-0x40+5*4]  ; st.st_size.
    assert_addr 0x3f643e
  incbin_until 0x3f78b0
    signal_handler:
    ru 0x3f78b6
    incbin_until 0x3f78ba
    times 5 nop  ; Omit the `call signal'.
    ru 0x3f78c5
    incbin_until 0x3f78c9
    times 5 nop  ; Omit the `call signal'.
    incbin_until 0x3f78e2
    .after_cleanups:
    pop ebx  ; EBX := EXIT_FATAL.
    xor eax, eax
    inc eax  ; EAX := SYS_EXIT.
    ; We use SYS_EXIT, which doesn't do fflush(stdout) etc., because that
    ; wouldn't have a data race in the signal handler.
    li3_syscall  ; Doesn't return.
    fill_until 0x3f78ec
  ru 0x3f9d54
  incbin_until 0x3f9e1c
    ; The original call to `time' was here, when populting the coff_filehdr.
    push ebx  ; Save.
    push strict byte SYS_TIME
    pop eax
    mov ebx, [coff_filehdr_f_timdat]
    li3_syscall
    pop ebx  ; Restore.
    and dword [coff_filehdr_f_opthr_and_f_flags], strict byte 0
    fill_until 0x3f9e30
  ru 0x3fa482
  incbin_until 0x3fd040
    ; We don't implement execve(...), because we've removed its only caller.
    ; (m4 support).
    execve:
    hlt
    ;mov eax, SYS_EXECVE
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3fd054
  incbin_until 0x3fd054
    ; We don't implement fork(...), because we've removed its only caller.
    ; (m4 support).
    fork:
    hlt
    ;mov eax, SYS_FORK
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3fd070
  incbin_until 0x3fd13f
    loc_D2BF:
    jmp strict short .end
    fill_until 0x3fd15c  ; Skill call to access("/usr/tmp", ...). It looks like it's not done anyway.
    .end:
  incbin_until 0x3fd27c
    ; We don't implement time(...), because we've removed the only caller.
    time:
    hlt
    ;push ebx  ; Save.
    ;push strict byte SYS_TIME
    ;pop eax
    ;mov ebx, [esp+2*4]
    ;li3_syscall
    ;pop ebx  ; Restore.
    ;ret  ; Assume that it always succeds (and returns the timestamp, even if negative).
    fill_until 0x3fd294
  incbin_until 0x3fd4e0
    access:
    push strict byte SYS_ACCESS
    jmp strict near simple_syscall3
    fill_until 0x3fd4f4
  incbin_until 0x3fd544
    fstat:
    push strict byte SYS_fstat  ; We've modified the caller so that it expects a Linux i386 struct stat.
    jmp strict near simple_syscall3
    fill_until 0x3fd55c
  incbin_until 0x3fd55c
    lseek:
    push strict byte SYS_LSEEK
    jmp strict near simple_syscall3
    fill_until 0x3fd570
  incbin_until 0x3fd5fc
    unlink:
    push strict byte SYS_UNLINK
    jmp strict near simple_syscall3
    fill_until 0x3fd614
  incbin_until 0x3feb24
    unused_setchrclass:
    fill_until 0x3febec
  incbin_until 0x3ff8e0
    close:
    push strict byte SYS_CLOSE
    jmp strict near simple_syscall3
    fill_until 0x3ff8f8
  incbin_until 0x3ff980
    isatty:
    push ebx
    sub esp, strict byte 0x24
    push strict byte SYS_IOCTL
    pop eax
    mov ebx, [esp+0x24+4+4]  ; fd argument of ioctl.
    mov ecx, Linux_TCGETS
    mov edx, esp  ; 3rd argument of ioctl Linux_TCGETS.
    li3_syscall
    add esp, strict byte 0x24  ; Clean up everything pushed.
    pop ebx
    ; Now convert result EAX: 0 to 1, everything else to 0.
    cmp eax, strict byte 1
    sbb eax, eax
    neg eax
    ret
    fill_until 0x3ff9b8
  incbin_until 0x3ff9b8
    ; We don't implement ioctl(...), because the only caller is isatty(2), which we have replaced.
    ioctl:
    hlt
    ;mov eax, SYS_IOCTL
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3ff9cc
  incbin_until 0x3ffb99
    times 5 nop  ; In malloc(...), prevent a `call brk' after sbrk(...) has failed.
    assert_addr 0x3ffb9e
  incbin_until 0x3ffe10
    open:
    push strict byte SYS_OPEN
    pop eax
    push ebx  ; Save.
    mov ebx, [esp+2*4]  ; pathname.
    mov ecx, [esp+3*4]  ; flags.
    jmp strict near fix_sys_open_cont
    fill_until 0x3ffe24
  incbin_until 0x3ffe24
    read:
    push strict byte SYS_READ
    jmp strict near simple_syscall3
    fill_until 0x3ffe38
  incbin_until 0x3ffe38
    sbrk:
    push ebx
    push ecx
    mov ecx, brk_end_ptr  ; Will remain so during the function.
    push strict byte SYS_brk
    pop eax
    mov ebx, [ecx]
    test ebx, ebx
    jne strict short .no1st
    push eax
    xor ebx, ebx
    li3_syscall
    ; Becaue of address randomization (ASLR), the memory region directly
    ; after .bss may not be accessible. We call sys_brk(0) to get the lowest accessible address.
    ; For more about ASLR, see
    ; https://security.stackexchange.com/questions/229443/importance-of-aslr-mode-2
    mov [ecx], eax
    xchg eax, ebx  ; EBX := EAX; EAX := junk.
    pop eax  ; SYS_brk.
    .no1st:
    add ebx, [esp+2*4+4]  ; Argument increment.
    li3_syscall
    cmp ebx, eax
    jna strict short .good
    or eax, strict byte -1  ; Indicate error. No need to set errno for our use case.
    pop ebx
    ret
    .good:
    xchg [ecx], ebx  ; Return the previous brk pointer. We set the new brk pointer to just what was asked, for for ASLR-consistency.
    xchg eax, ebx  ; EAX := EBX (result); EBX := junk.
    pop ecx
    pop ebx
    ret
    ; No need to implement brk(...): there are no callers except for
    ; malloc(...) (call removed) and sbrk(...) (entire implementation
    ; replaced).
    ;incbin_until 0x400011?
    ;brk:
    ;mov eax, SYS_BRK
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3ffe7c
  incbin_until 0x3ffec8
    ; We don't implement wait(...), because we've removed its only caller
    ; (m4 support).
    $wait:
    hlt
    ;mov eax, SYS_WAIT
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3ffee8
  incbin_until 0x3ffee8
    write:
    push strict byte SYS_WRITE
    jmp strict near simple_syscall3
    fill_until 0x3ffefc
  incbin_until 0x3ffefc
    signal:
    ; This doesn't work in qemu-i386 on Linux (it doesn't support
    ; SYS_SIGNAL), and SYSV signals also has race conditions: if the signal
    ; quickly hits again while handler is running and it hasn't
    ; reestablished itself, then the signal can kill the process.
    ;
    ; We solve both of these problems by using sigaction(2) with BSD signal
    ; semantics.
    ;
    ;push strict byte SYS_SIGNAL
    ;jmp strict near simple_syscall3
    enter 0x20, 0  ; 0x20 == 2 * 0x10: first act at &[ebp-0x20], then oldact at &[ebp-0x10].
    mov eax, [ebp+0xc]
    mov [ebp-0x20+0*4], eax  ; handler.
    mov dword [ebp-0x20+2*4], Linux_SA_RESTART  ; sa_flags.
    xor eax, eax
    mov [ebp-0x20+1*4], eax  ; act.sa_mask.sig[0] := 0. sizeof(sa_mask) is always 4 for Linux i386 SYS_sigaction.
    lea eax, [ebp-0x10]  ; Argument oldact of SYS_sigaction.
    push eax
    lea eax, [ebp-0x20]
    push eax  ; Argument act of SYS_sigaction.
    push dword [ebp+0x8]  ; Argument sig of SYS_sigaction.
    push strict byte SYS_sigaction
    pop eax
    call simple_syscall3.in_eax
    ; We don't bother popping arguments from the stack, `leave' below will
    ; do it for us.
    test eax, eax
    jnz .done  ; EAX == SIG_ERR == -1.
    mov eax, [ebp-0x10]  ; Old handler.
    .done:
    leave
    ret
    ;fill_until 0x4000bc?
    ;unused_sigset:  ; Also: unused_sigignore, unused_sigpause, unused_sigrelse, unused_sighold, _sigreturn.
    fill_until 0x3fff70
  ; `kill' is missing.  ;incbin_until ?
    ;kill:
    ;push strict byte SYS_KILL
    ;jmp strict near simple_syscall3
    ;fill_until ?
  incbin_until 0x3fff70
    getpid:
    push strict byte SYS_GETPID
    jmp strict near simple_syscall3
    fill_until 0x3fff80
  incbin_until 0x3fff80
    _cerror:  ; Must not be reached.
    hlt
    fill_until 0x3fff8c
  incbin_until 0x3fff8c
    exit:
    call _cleanup  ; Calls fflush(stdout) etc.
    mov ebx, [esp+4]  ; exit_code argument.
    xor eax, eax
    inc eax  ; EAX := SYS_EXIT.
    li3_syscall
    assert_addr 0x3fff9a
    fill_until 0x3fffa8

section .xdata
  incbin_until 0x4010fe
    msg_m4_error db 'm4 not supported', 10, 0  ; We replace the original message "Assembly inhibited\n".
    fill_until 0x401112
  r 0x409632, 0x409c36
  r 0x40a916, 0x40a926
  r 0x40a92e, 0x40a9ae
  r 0x40ab9a, 0x40abae
  incbin_until 0x40b11c
    coff_filehdr_f_timdat: dd coff_filehdr_f_timdat  ; NULL here means write 0 as the timestamp, for reproducible builds.
    coff_filehdr_f_opthr_and_f_flags equ coff_filehdr_f_timdat+3*4
  r 0x40b662, 0x40b696
  r 0x40b8ae, 0x40b8fe
  incbin_until 0x40b988
    aUsrTmp: fill_until 0x40b994  ; Fill out unused "/usr/tmp" string.
  r 0x40ba2a, 0x40bb8a
  incbin_until 0x40bdb8
    unused_setchrclass_data:
    fill_until 0x40bdd8
  incbin_until 0x40c238
    ; Used by only brk(...) and sbrk(...). We reimplement these functions,
    ; so we can use this value freely.
    brk_end_ptr dd 0  ; First call to sbrk(...) will set it.

end
