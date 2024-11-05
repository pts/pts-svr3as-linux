;
; svr3as-1989-10-03.nasm: a Linux i386 port of the SVR3 3.2 SDS 4.1.5 1989-10-03 i386 assembler as(1)
; by pts@fazekas.hu at Mon Oct 21 18:19:03 CEST 2024
;
; Compile with: nasm -w+orphan-labels -f bin -O0 -o svr3as-1989-10-03 svr3as-1989-10-03.nasm && chmod +x svr3as-1989-10-03
; Run on Linux (creating test.o of COFF format): ./svr3as-1989-10-03 -dt test.s && cmp -l test.o.good test.o
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

%ifdef SRC_1988  ; See more define.* in aso4.nasm.
  %define SUB4 4
%else
  %define SUB4 0

  %include 'binpatch.inc.nasm'

  ; `objdump -x' output (Size mostly incorrect):
  ; Idx Name          Size      VMA       File off  Algn
  ;   0 .text         0x0100a4  0x0000d0  0x0000d0  2**2  CONTENTS, ALLOC, LOAD, READONLY, CODE, NOREAD
  ;   1 .data         0x00b5d4  0x400174  0x010174  2**2  CONTENTS, ALLOC, LOAD, READONLY, DATA, NOREAD
  ;   2 .bss          0x40b748  0x40b748  0x000000  2**2  ALLOC, READONLY, NOREAD
  ;   3 .comment      0x00004a  0x000000  0x01b748  2**2  CONTENTS, READONLY, DEBUGGING, NOREAD

  define.xbin 'svr3as-1989-10-03.svr3'
  define.xtext 0x010100, 0x3e0074, 0x000074
  define.xdata 0x00b5d4, 0x400174, 0x010174, 0x00b5d4+0x11080
  opt.o0  ; Make NASM compilation faster. For this file the output is the same.
%endif

; Holes in the input file:
;
; * TODO(pts): Fill these holes with NUL bytes for better compression.
; * 0x74, 0x8e: (occupied by the Linux _start) initial padding, init_nothing, _start, unused_nullsub2
; * 0x8e, 0x11c: initial padding, init_nothing, _start, unused_nullsub2
; * 0x949c, 0x94ac: unused_sub_949C
; * 0x97dc, 0x981c: unused_sub_97DC
; * 0xb0f4, 0xb124: unused_sub_B0F4
; * 0xb2f4, 0xb368: unused_sub_B2F4
; * 0xb60c, 0xb640: unused_op_log10
; * 0xb888, 0xb8c0: unused_sub_B888
; * 0xbb88, 0xbb98: unused_cfree
; * 0xbd34, 0xbd50: unused_scanf
; * 0xbd50, 0xbd6c: unused_fscanf
; * 0xeca4, 0xed6c: setchrclass
; * 0x100bc, 0x10124: unused_sigset, unused_sigignore, unused_sigpause, unused_sigrelse, unused_sighold, _sigreturn
; * 0x10166, 0x10174: Not used after exit(...).
; * 0x40af90, 0x40afb8: _setchrclass_needs_loading, aChrclass, aAscii, aLibChrclass
; * TODO(pts): Many syscall wrappers and all fill_until()s below.
; * TODO(pts): Many instances of `dd offset byte_40B26C', and also the value pointed to.
; * TODO(pts): Lots of unreachable code (including fork(...), execve(...) and wait(...)) because code from run_m4(...) has been removed.
; * TODO(pts): There are many big holes in .data. Move them to .bss. It's hard to move the subsequent data.
;

_cleanup requ 0x3ef630
environ requ 0x400174-SUB4
errno requ 0x40b728-SUB4
dlflag requ 0x409d6c-SUB4
filenames_0 requ 0x40b748-SUB4
cfile requ 0x409a44-SUB4

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

%macro ru 1  ; Relocates pointer-to-.text value 0x0000???? to 0x003e????.
  iu %1  ; Like `incbin_until %1', but faster, because it doesn't do any address checks.
  db 0x3e
%endm
%macro r 2  ; Relocates pointer-to-.text values %1-SUB4..%2-SUB4 (inclusive, countiny by 4).
  %assign __ra (%1)-SUB4  ; First address.
  %assign __rb (%2)-SUB4  ; Last address.
  %rep ((__rb-__ra)>>2)+1
    iu __ra
    db 0x3e
    %assign __ra __ra+4
  %endrep
%endm

section .xtext
  incbin_until 0x3e0074
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

    better_getargs:
    call getargs
    cmp [filenames_0], strict byte 0
    jne strict near after_better_getargs
    jmp strict near fatal_usage

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

  fill_until 0x3e011c
    getargs:
  incbin_until 0x3e01a4
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
    fill_until 0x3e01c0
  incbin_until 0x3e0450
    main:
    incbin_until 0x3e045b
    fatal_usage:
    incbin_until 0x3e0484
    jmp strict near better_getargs
    after_better_getargs:
  incbin_until 0x3e0614
    run_m4:  ; Called when the `-m' command-line flag is specified.
    ; We don't support running m4 on Linux, because the Linux system
    ; typically doesn't have the needed macro files `/lib/cm4defs' and
    ; `/lib/cm4tvdefs'.
    jmp strict short .die
    fill_until 0x3e068f
    .die:  ; Print error message msg_m4_error and die.
  ru 0x3e60f9
  ru 0x3e6118
  ru 0x3e6137
  incbin_until 0x3e6463
    ; fstat(...) call in init_cmd_and_symbol_hash(...).
    incbin_until 0x3e6463
    sub esp, strict byte 0x40  ; Linux `struct stat' is 0x40 bytes.
    assert_addr 0x3e6466
    incbin_until 0x3e649d
    lea eax, [ebp-0x40]  ; &st.
    assert_addr 0x3e64a0
    incbin_until 0x3e64b3
    mov eax, [ebp-0x40+5*4]  ; st.st_size.
    assert_addr 0x3e64b6
  incbin_until 0x3e7940
    signal_handler:
    ru 0x3e7946
    incbin_until 0x3e794a
    times 5 nop  ; Omit the `call signal'.
    ru 0x3e7955
    incbin_until 0x3e7959
    times 5 nop  ; Omit the `call signal'.
    incbin_until 0x3e7974
    .after_cleanups:
    pop ebx  ; EBX := EXIT_FATAL.
    xor eax, eax
    inc eax  ; EAX := SYS_EXIT.
    ; We use SYS_EXIT, which doesn't do fflush(stdout) etc., because that
    ; wouldn't have a data race in the signal handler.
    li3_syscall  ; Doesn't return.
    fill_until 0x3e797c
  incbin_until 0x3e7a20
    errmsg:
    incbin_until 0x3e7a2e
    mov eax, cfile
    mov ecx, [filenames_0]
    test ecx, ecx
    jz strict short .have_filename_in_eax
    cmp byte [eax], 0
    jne strict short .have_filename_in_eax
    xchg eax, ecx  ; EAX := ECX; ECX := junk.
    .have_filename_in_eax:
    push eax
    jmp strict short .push
    fill_until 0x3e7a4e, nop  ; About 10 bytes, until the push aAssemblerS.
    .push:
  ru 0x3e9e1c
  incbin_until 0x3e9ee4
    ; The original call to `time' was here, when populting the coff_filehdr.
    push ebx  ; Save.
    push strict byte SYS_TIME
    pop eax
    mov ebx, [coff_filehdr_f_timdat]
    li3_syscall
    pop ebx  ; Restore.
    and dword [coff_filehdr_f_opthr_and_f_flags], strict byte 0
    fill_until 0x3e9ef8
  ru 0x3ea55c
  incbin_until 0x3ed1c0
    ; We don't implement execve(...), because we've removed its only caller
    ; (m4 support).
    execve:
    hlt
    ;mov eax, SYS_EXECVE
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3ed1d4
  incbin_until 0x3ed1d4
    ; We don't implement fork(...), because we've removed its only caller
    ; (m4 support).
    fork:
    hlt
    ;mov eax, SYS_FORK
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3ed1f0
  incbin_until 0x3ed2bf
    loc_D2BF:
    jmp strict short .end
    fill_until 0x3ed2dc  ; Skill call to access("/usr/tmp", ...). It looks like it's not done anyway.
    .end:
  incbin_until 0x3ed3fc
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
    fill_until 0x3ed414
  incbin_until 0x3ed660
    access:
    push strict byte SYS_ACCESS
    jmp strict near simple_syscall3
    fill_until 0x3ed674
  incbin_until 0x3ed6c4
    fstat:
    push strict byte SYS_fstat  ; We've modified the caller so that it expects a Linux i386 struct stat.
    jmp strict near simple_syscall3
    fill_until 0x3ed6dc
  incbin_until 0x3ed6dc
    lseek:
    push strict byte SYS_LSEEK
    jmp strict near simple_syscall3
    fill_until 0x3ed6f0
  incbin_until 0x3ed77c
    unlink:
    push strict byte SYS_UNLINK
    jmp strict near simple_syscall3
    fill_until 0x3ed794
  incbin_until 0x3eeca4
    unused_setchrclass:
    fill_until 0x3eed6c
  incbin_until 0x3efa94-SUB4
    close:
    push strict byte SYS_CLOSE
    jmp strict near simple_syscall3
    fill_until 0x3efaac-SUB4
  incbin_until 0x3efb34-SUB4
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
    fill_until 0x3efb6c-SUB4
  incbin_until 0x3efb6c-SUB4
    ; We don't implement ioctl(...), because the only caller is isatty(2), which we have replaced.
    ioctl:
    hlt
    ;mov eax, SYS_IOCTL
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3efb80-SUB4
  incbin_until 0x3efd4c-SUB4
    times 5 nop  ; In malloc(...), prevent a `call brk' after sbrk(...) has failed.
    assert_addr 0x3efd51-SUB4
  incbin_until 0x3effc4-SUB4
    open:
    push strict byte SYS_OPEN
    pop eax
    push ebx  ; Save.
    mov ebx, [esp+2*4]  ; pathname.
    mov ecx, [esp+3*4]  ; flags.
    jmp strict near fix_sys_open_cont
    fill_until 0x3effd8-SUB4
  incbin_until 0x3effd8-SUB4
    read:
    push strict byte SYS_READ
    jmp strict near simple_syscall3
    fill_until 0x3effec-SUB4
  incbin_until 0x3effec-SUB4
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
    ;incbin_until 0x10011
    ;brk:
    ;mov eax, SYS_BRK
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3f0030-SUB4
  incbin_until 0x3f007c-SUB4
    ; We don't implement wait(...), because we've removed its only caller
    ; (m4 support).
    $wait:
    hlt
    ;mov eax, SYS_WAIT
    ;call emu_fatal_unsupported_syscall
    fill_until 0x3f009c-SUB4
  incbin_until 0x3f009c-SUB4
    write:
    push strict byte SYS_WRITE
    jmp strict near simple_syscall3
    fill_until 0x3f00b0-SUB4
  incbin_until 0x3f00b0-SUB4
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
    ;fill_until 0x100bc
    ;unused_sigset:  ; Also: unused_sigignore, unused_sigpause, unused_sigrelse, unused_sighold, _sigreturn.
    fill_until 0x3f0124-SUB4
  incbin_until 0x3f0124-SUB4
    kill:
    push strict byte SYS_KILL
    jmp strict near simple_syscall3
    fill_until 0x3f013c-SUB4
  incbin_until 0x3f013c-SUB4
    getpid:
    push strict byte SYS_GETPID
    jmp strict near simple_syscall3
    fill_until 0x3f014c-SUB4
  incbin_until 0x3f014c-SUB4
    _cerror:  ; Must not be reached.
    hlt
    fill_until 0x3f0158-SUB4
  incbin_until 0x3f0158-SUB4
    exit:
    call _cleanup  ; Calls fflush(stdout) etc.
    mov ebx, [esp+4]  ; exit_code argument.
    xor eax, eax
    inc eax  ; EAX := SYS_EXIT.
    li3_syscall
    assert_addr 0x3f0166-SUB4
    fill_until 0x3f0174-SUB4

section .xdata
  incbin_until 0x4002a5-SUB4
    msg_m4_error db 'm4 not supported', 10, 0  ; We replace the original message "Assembly inhibited\n".
    fill_until 0x4002b9-SUB4
  r 0x4087da, 0x408dde
  r 0x409abe, 0x409ace
  r 0x409ad6, 0x409b56
  r 0x409d46, 0x409d5a
  incbin_until 0x40a2c8-SUB4
    coff_filehdr_f_timdat: dd coff_filehdr_f_timdat  ; NULL here means write 0 as the timestamp, for reproducible builds.
    coff_filehdr_f_opthr_and_f_flags equ coff_filehdr_f_timdat+3*4
  r 0x40a80e, 0x40a842
  r 0x40aa76, 0x40aac6
  incbin_until 0x40ab60-SUB4
    aUsrTmp: fill_until 0x40ab6c-SUB4  ; Fill out unused "/usr/tmp" string.
  r 0x40ac02, 0x40ad62
  incbin_until 0x40af90-SUB4
    unused_setchrclass_data:
    fill_until 0x40afb8-SUB4
  incbin_until 0x40b744-SUB4
    ; Used by only brk(...) and sbrk(...). We reimplement these functions,
    ; so we can use this value freely.
    brk_end_ptr dd 0  ; First call to sbrk(...) will set it.

end
