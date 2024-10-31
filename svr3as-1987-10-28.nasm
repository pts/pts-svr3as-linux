;
; svr3as-1987-10-28.nasm: a Linux i386 port of the SVR3 3.2 SDS 4.1 1987-10-28 (1987-10.1) i386 assembler as(1)
; by pts@fazekas.hu at Mon Oct 28 00:13:49 CET 2024
;
; Compile with: nasm -w+orphan-labels -f bin -O0 -o svr3as-1987-10-28 svr3as-1987-10-28.nasm && chmod +x svr3as-1987-10-28
; Run on Linux (creating test.o of COFF format): ./svr3as-1987-10-28.nasm: test.s && cmp -l test.o.good test.o
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
SYS_SIGNAL equ 48  ; The Linux syscall 48 matches the SYSV behavior (not the BSD behavior). Good. !! qemu-i386 doesn't support SYS_SIGNAL == 48, use sigaction(2) instead.
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

%macro ru 1  ; Relocate pointer-to-.text value 0x0000???? to 0x003f????.
  iu %1  ; Like `incbin_until %1', but faster, because it doesn't do any address checks.
  db 0x3f
%endm
%if 0




%else
  %macro r 1
    iu %1
    db 0x3f
  %endm
%endif

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
    fill_until 0x3f9e27, nop  ; Omit call to time(...), because the result is not used.
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
  r 0x409632
  r 0x409636
  r 0x40963a
  r 0x40963e
  r 0x409642
  r 0x409646
  r 0x40964a
  r 0x40964e
  r 0x409652
  r 0x409656
  r 0x40965a
  r 0x40965e
  r 0x409662
  r 0x409666
  r 0x40966a
  r 0x40966e
  r 0x409672
  r 0x409676
  r 0x40967a
  r 0x40967e
  r 0x409682
  r 0x409686
  r 0x40968a
  r 0x40968e
  r 0x409692
  r 0x409696
  r 0x40969a
  r 0x40969e
  r 0x4096a2
  r 0x4096a6
  r 0x4096aa
  r 0x4096ae
  r 0x4096b2
  r 0x4096b6
  r 0x4096ba
  r 0x4096be
  r 0x4096c2
  r 0x4096c6
  r 0x4096ca
  r 0x4096ce
  r 0x4096d2
  r 0x4096d6
  r 0x4096da
  r 0x4096de
  r 0x4096e2
  r 0x4096e6
  r 0x4096ea
  r 0x4096ee
  r 0x4096f2
  r 0x4096f6
  r 0x4096fa
  r 0x4096fe
  r 0x409702
  r 0x409706
  r 0x40970a
  r 0x40970e
  r 0x409712
  r 0x409716
  r 0x40971a
  r 0x40971e
  r 0x409722
  r 0x409726
  r 0x40972a
  r 0x40972e
  r 0x409732
  r 0x409736
  r 0x40973a
  r 0x40973e
  r 0x409742
  r 0x409746
  r 0x40974a
  r 0x40974e
  r 0x409752
  r 0x409756
  r 0x40975a
  r 0x40975e
  r 0x409762
  r 0x409766
  r 0x40976a
  r 0x40976e
  r 0x409772
  r 0x409776
  r 0x40977a
  r 0x40977e
  r 0x409782
  r 0x409786
  r 0x40978a
  r 0x40978e
  r 0x409792
  r 0x409796
  r 0x40979a
  r 0x40979e
  r 0x4097a2
  r 0x4097a6
  r 0x4097aa
  r 0x4097ae
  r 0x4097b2
  r 0x4097b6
  r 0x4097ba
  r 0x4097be
  r 0x4097c2
  r 0x4097c6
  r 0x4097ca
  r 0x4097ce
  r 0x4097d2
  r 0x4097d6
  r 0x4097da
  r 0x4097de
  r 0x4097e2
  r 0x4097e6
  r 0x4097ea
  r 0x4097ee
  r 0x4097f2
  r 0x4097f6
  r 0x4097fa
  r 0x4097fe
  r 0x409802
  r 0x409806
  r 0x40980a
  r 0x40980e
  r 0x409812
  r 0x409816
  r 0x40981a
  r 0x40981e
  r 0x409822
  r 0x409826
  r 0x40982a
  r 0x40982e
  r 0x409832
  r 0x409836
  r 0x40983a
  r 0x40983e
  r 0x409842
  r 0x409846
  r 0x40984a
  r 0x40984e
  r 0x409852
  r 0x409856
  r 0x40985a
  r 0x40985e
  r 0x409862
  r 0x409866
  r 0x40986a
  r 0x40986e
  r 0x409872
  r 0x409876
  r 0x40987a
  r 0x40987e
  r 0x409882
  r 0x409886
  r 0x40988a
  r 0x40988e
  r 0x409892
  r 0x409896
  r 0x40989a
  r 0x40989e
  r 0x4098a2
  r 0x4098a6
  r 0x4098aa
  r 0x4098ae
  r 0x4098b2
  r 0x4098b6
  r 0x4098ba
  r 0x4098be
  r 0x4098c2
  r 0x4098c6
  r 0x4098ca
  r 0x4098ce
  r 0x4098d2
  r 0x4098d6
  r 0x4098da
  r 0x4098de
  r 0x4098e2
  r 0x4098e6
  r 0x4098ea
  r 0x4098ee
  r 0x4098f2
  r 0x4098f6
  r 0x4098fa
  r 0x4098fe
  r 0x409902
  r 0x409906
  r 0x40990a
  r 0x40990e
  r 0x409912
  r 0x409916
  r 0x40991a
  r 0x40991e
  r 0x409922
  r 0x409926
  r 0x40992a
  r 0x40992e
  r 0x409932
  r 0x409936
  r 0x40993a
  r 0x40993e
  r 0x409942
  r 0x409946
  r 0x40994a
  r 0x40994e
  r 0x409952
  r 0x409956
  r 0x40995a
  r 0x40995e
  r 0x409962
  r 0x409966
  r 0x40996a
  r 0x40996e
  r 0x409972
  r 0x409976
  r 0x40997a
  r 0x40997e
  r 0x409982
  r 0x409986
  r 0x40998a
  r 0x40998e
  r 0x409992
  r 0x409996
  r 0x40999a
  r 0x40999e
  r 0x4099a2
  r 0x4099a6
  r 0x4099aa
  r 0x4099ae
  r 0x4099b2
  r 0x4099b6
  r 0x4099ba
  r 0x4099be
  r 0x4099c2
  r 0x4099c6
  r 0x4099ca
  r 0x4099ce
  r 0x4099d2
  r 0x4099d6
  r 0x4099da
  r 0x4099de
  r 0x4099e2
  r 0x4099e6
  r 0x4099ea
  r 0x4099ee
  r 0x4099f2
  r 0x4099f6
  r 0x4099fa
  r 0x4099fe
  r 0x409a02
  r 0x409a06
  r 0x409a0a
  r 0x409a0e
  r 0x409a12
  r 0x409a16
  r 0x409a1a
  r 0x409a1e
  r 0x409a22
  r 0x409a26
  r 0x409a2a
  r 0x409a2e
  r 0x409a32
  r 0x409a36
  r 0x409a3a
  r 0x409a3e
  r 0x409a42
  r 0x409a46
  r 0x409a4a
  r 0x409a4e
  r 0x409a52
  r 0x409a56
  r 0x409a5a
  r 0x409a5e
  r 0x409a62
  r 0x409a66
  r 0x409a6a
  r 0x409a6e
  r 0x409a72
  r 0x409a76
  r 0x409a7a
  r 0x409a7e
  r 0x409a82
  r 0x409a86
  r 0x409a8a
  r 0x409a8e
  r 0x409a92
  r 0x409a96
  r 0x409a9a
  r 0x409a9e
  r 0x409aa2
  r 0x409aa6
  r 0x409aaa
  r 0x409aae
  r 0x409ab2
  r 0x409ab6
  r 0x409aba
  r 0x409abe
  r 0x409ac2
  r 0x409ac6
  r 0x409aca
  r 0x409ace
  r 0x409ad2
  r 0x409ad6
  r 0x409ada
  r 0x409ade
  r 0x409ae2
  r 0x409ae6
  r 0x409aea
  r 0x409aee
  r 0x409af2
  r 0x409af6
  r 0x409afa
  r 0x409afe
  r 0x409b02
  r 0x409b06
  r 0x409b0a
  r 0x409b0e
  r 0x409b12
  r 0x409b16
  r 0x409b1a
  r 0x409b1e
  r 0x409b22
  r 0x409b26
  r 0x409b2a
  r 0x409b2e
  r 0x409b32
  r 0x409b36
  r 0x409b3a
  r 0x409b3e
  r 0x409b42
  r 0x409b46
  r 0x409b4a
  r 0x409b4e
  r 0x409b52
  r 0x409b56
  r 0x409b5a
  r 0x409b5e
  r 0x409b62
  r 0x409b66
  r 0x409b6a
  r 0x409b6e
  r 0x409b72
  r 0x409b76
  r 0x409b7a
  r 0x409b7e
  r 0x409b82
  r 0x409b86
  r 0x409b8a
  r 0x409b8e
  r 0x409b92
  r 0x409b96
  r 0x409b9a
  r 0x409b9e
  r 0x409ba2
  r 0x409ba6
  r 0x409baa
  r 0x409bae
  r 0x409bb2
  r 0x409bb6
  r 0x409bba
  r 0x409bbe
  r 0x409bc2
  r 0x409bc6
  r 0x409bca
  r 0x409bce
  r 0x409bd2
  r 0x409bd6
  r 0x409bda
  r 0x409bde
  r 0x409be2
  r 0x409be6
  r 0x409bea
  r 0x409bee
  r 0x409bf2
  r 0x409bf6
  r 0x409bfa
  r 0x409bfe
  r 0x409c02
  r 0x409c06
  r 0x409c0a
  r 0x409c0e
  r 0x409c12
  r 0x409c16
  r 0x409c1a
  r 0x409c1e
  r 0x409c22
  r 0x409c26
  r 0x409c2a
  r 0x409c2e
  r 0x409c32
  r 0x409c36
  r 0x40a916
  r 0x40a91a
  r 0x40a91e
  r 0x40a922
  r 0x40a926
  r 0x40a92e
  r 0x40a932
  r 0x40a936
  r 0x40a93a
  r 0x40a93e
  r 0x40a942
  r 0x40a946
  r 0x40a94a
  r 0x40a94e
  r 0x40a952
  r 0x40a956
  r 0x40a95a
  r 0x40a95e
  r 0x40a962
  r 0x40a966
  r 0x40a96a
  r 0x40a96e
  r 0x40a972
  r 0x40a976
  r 0x40a97a
  r 0x40a97e
  r 0x40a982
  r 0x40a986
  r 0x40a98a
  r 0x40a98e
  r 0x40a992
  r 0x40a996
  r 0x40a99a
  r 0x40a99e
  r 0x40a9a2
  r 0x40a9a6
  r 0x40a9aa
  r 0x40a9ae
  r 0x40ab9a
  r 0x40ab9e
  r 0x40aba2
  r 0x40aba6
  r 0x40abaa
  r 0x40abae
  r 0x40b662
  r 0x40b666
  r 0x40b66a
  r 0x40b66e
  r 0x40b672
  r 0x40b676
  r 0x40b67a
  r 0x40b67e
  r 0x40b682
  r 0x40b686
  r 0x40b68a
  r 0x40b68e
  r 0x40b692
  r 0x40b696
  r 0x40b8ae
  r 0x40b8b2
  r 0x40b8b6
  r 0x40b8ba
  r 0x40b8be
  r 0x40b8c2
  r 0x40b8c6
  r 0x40b8ca
  r 0x40b8ce
  r 0x40b8d2
  r 0x40b8d6
  r 0x40b8da
  r 0x40b8de
  r 0x40b8e2
  r 0x40b8e6
  r 0x40b8ea
  r 0x40b8ee
  r 0x40b8f2
  r 0x40b8f6
  r 0x40b8fa
  r 0x40b8fe
  incbin_until 0x40b988
    aUsrTmp: fill_until 0x40b994  ; Fill out unused "/usr/tmp" string.
  r 0x40ba2a
  r 0x40ba2e
  r 0x40ba32
  r 0x40ba36
  r 0x40ba3a
  r 0x40ba3e
  r 0x40ba42
  r 0x40ba46
  r 0x40ba4a
  r 0x40ba4e
  r 0x40ba52
  r 0x40ba56
  r 0x40ba5a
  r 0x40ba5e
  r 0x40ba62
  r 0x40ba66
  r 0x40ba6a
  r 0x40ba6e
  r 0x40ba72
  r 0x40ba76
  r 0x40ba7a
  r 0x40ba7e
  r 0x40ba82
  r 0x40ba86
  r 0x40ba8a
  r 0x40ba8e
  r 0x40ba92
  r 0x40ba96
  r 0x40ba9a
  r 0x40ba9e
  r 0x40baa2
  r 0x40baa6
  r 0x40baaa
  r 0x40baae
  r 0x40bab2
  r 0x40bab6
  r 0x40baba
  r 0x40babe
  r 0x40bac2
  r 0x40bac6
  r 0x40baca
  r 0x40bace
  r 0x40bad2
  r 0x40bad6
  r 0x40bada
  r 0x40bade
  r 0x40bae2
  r 0x40bae6
  r 0x40baea
  r 0x40baee
  r 0x40baf2
  r 0x40baf6
  r 0x40bafa
  r 0x40bafe
  r 0x40bb02
  r 0x40bb06
  r 0x40bb0a
  r 0x40bb0e
  r 0x40bb12
  r 0x40bb16
  r 0x40bb1a
  r 0x40bb1e
  r 0x40bb22
  r 0x40bb26
  r 0x40bb2a
  r 0x40bb2e
  r 0x40bb32
  r 0x40bb36
  r 0x40bb3a
  r 0x40bb3e
  r 0x40bb42
  r 0x40bb46
  r 0x40bb4a
  r 0x40bb4e
  r 0x40bb52
  r 0x40bb56
  r 0x40bb5a
  r 0x40bb5e
  r 0x40bb62
  r 0x40bb66
  r 0x40bb6a
  r 0x40bb6e
  r 0x40bb72
  r 0x40bb76
  r 0x40bb7a
  r 0x40bb7e
  r 0x40bb82
  r 0x40bb86
  r 0x40bb8a
  incbin_until 0x40bdb8
    unused_setchrclass_data:
    fill_until 0x40bdd8
  incbin_until 0x40c238
    ; Used by only brk(...) and sbrk(...). We reimplement these functions,
    ; so we can use this value freely.
    brk_end_ptr dd 0  ; First call to sbrk(...) will set it.

end
