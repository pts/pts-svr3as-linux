;
; sunos4as-1988-11-16.nasm: a Linux i386 port of the SunOS 4.01 (1988-11-16) i386 assembler as(1)
; by pts@fazekas.hu at Tue Nov  5 15:31:51 CET 2024
;
; Compile with: nasm -w+orphan-labels -f bin -O0 -o sunos4as-1988-11-16 sunos4as-1988-11-16.nasm && chmod +x sunos4as-1988-11-16
; Run on Linux (creating test.o of COFF format): ./sunos4as-1988-11-16: test.s && cmp -l test.o.good test.o
;
; This program runs natively on Linux i386 and Linux amd64 systems, even
; those which have `sysctl -w vm.mmap_min_addr=65536' (like many Linux
; distributions in 2018). (For that, the 2nd argument of define.xtext must
; be at least 0x10000).
;
; This program creates (and removes) up to 15 temporary files (in `$TMPDIR'
; or `/tmp') during normal operation.
;
; !! Why segmentation fault in full run (but not help) in qemu-i386?
; !! Check .xtext and .xdata padding (&x0xfff) in the final program, maybe we can save 0xfff bytes.
; !! Make unknown flags an error rather than a warning. Fix it in all 3 .nasm sources.
; !! "trouble writing; probably out of temp-file space" appears multiple times; deduplicate all strings.
; !! Add opt.xdata.first to match section order in sunos4as-1988-11-16.elf.
; !! Fix infinite loop when the input .s file doesn't end with a newline. Is it a libc bug or are the two others also buggy?
; !! Fix error line numbers. SVR3 assembler is also broken.
;

%include 'binpatch.inc.nasm'
%define p.rw.vsize.in.phdr1 ((s.xdata.fsize+0xfff)&~0xfff)  ; Override p.rw.vsize with p.rw.fsize, to pacify the Linux kernel. Only works with __OUTPUT_FORMAT__==bin.

; `objdump -x' output (Size mostly incorrect):
; Idx Name          Size      VMA       File off  Algn
;   0 .text         0x00ff30  0x0010d0  0x0000d0  2**2  CONTENTS, ALLOC, LOAD, READONLY, CODE, NOREAD
;   1 .data         0x009000  0x011000  0x010000  2**2  CONTENTS, ALLOC, LOAD, READONLY, DATA, NOREAD
;   2 .bss          0x01a000  0x01a000  0x000000  2**2  ALLOC, READONLY, NOREAD
;   3 .comment      0x000000  0x000000  0x000000  2**2  READONLY, DEBUGGING, NOREAD

define.xbin 'sunos4as-1988-11-16.svr3'
%ifdef USE_DEBUG
  define.xtext 0x00bab8+0x4d4, 0x0d1074, 0x000074
%else
  define.xtext 0x00b59a, 0x0d1074, 0x000074
%endif
define.xdata 0x00842e-0x1bb, 0x0111bb, 0x0101bb, 0xb2ca0-0x1bb  ; Size of .data: 0x842f Orirignal size of .data+.bss: 0xa1ca0
opt.o0  ; Make NASM compilation faster. For this file the output is the same

filenames_0 requ 0x19e34
cfile requ 0x189a8
__pathname_o_out requ 0x19e38
fdin requ 0x1aeb4
fdsect requ 0xaeb64
aLg_0 requ 0x1908d
outword requ 0xb2888  ; 1 byte.
yytext requ 0x19eb4
dword_B2884 requ 0xb2884
poscnt requ 0x19108
;mini_errno requ  ...  ; This program doesn't use errno (it was at 0x19e20 in original .xbss).
unused_w1 requ 0x17826  ; In .xdata. Gap.
unused_d2 requ 0x17820  ; In .xdata. Previously yynerrs. Gap.

%ifdef USE_SYMS
  ; Generate it from disassembly listing:
  ; <sunos4as-1988-11-16.svr3.lst perl -we 'use integer; use strict; my %skipsyms = map { $_ => 1 } qw(unused_w1 cfile dlflag filenames_0 __pathname_o_out fdin fdsect outword getargs main yylex yyparse aspass1 signal_handler errmsg deltemps doreals codgen fix outsyms unused___unused_helper10 _ctype_ ctype_ary coff_filehdr_f_timdat unused_inline unused_dotzero aspass2 passnbr lclatof picflag headers setfile lookup aLg_0 put_lg_break dword_B2884 yytext atob16f poscnt); while (<STDIN>) { die "fatal: syntax: $_" if !s@^[.](\w+):([0-9A-F]{8})\s+@@; next if $1 eq "header"; my $vaddr = hex($2); $vaddr += 0x0d0000 if $1 eq "xtext"; next if $vaddr < 0x0111fc or $vaddr > 0x0c4304 and $vaddr < 0x0d14d4 or $vaddr > 0x0dc344; s@\s*;.*@@s; chomp; next if !length; s@\s+@ @g; if (m@^([^\s:]+)(?: proc\b|:| d[bwdq]\b)@) { my $sym = $1; next if exists($skipsyms{$sym}); next if $sym =~ m@^loc(?:ret)?_@; $sym =~ s@^(?=pop)@\$@; printf "%s requ 0x%x\n", $sym, $vaddr } }' >sunos4as-1988-11-16.sym.inc.nasm
  %include 'sunos4as-1988-11-16.sym.inc.nasm'
%endif

%ifdef USE_DEBUG
  %macro xfill_until 1
    fill_until %1, hlt
  %endm
  %macro xfill_until 2
    fill_until %1, hlt
  %endm
%else
  %define xfill_until fill_until
%endif

; Linux >=1.0 i386 syscall numbers.
SYS_exit equ 1
SYS_read equ 3
SYS_write equ 4
SYS_open equ 5
SYS_close equ 6
SYS_waitpid equ 7
SYS_unlink equ 10
SYS_execve equ 11
SYS_time equ 13  ; Result should be checked differently.
SYS_lseek equ 19
SYS_getpid equ 20
SYS_access equ 33
SYS_brk equ 45
SYS_signal equ 48  ; The Linux syscall 48 matches the SYSV behavior (not the BSD behavior).
SYS_ioctl equ 54
SYS_sigaction equ 67
SYS_gettimeofday equ 78
SYS_mmap equ 90
SYS_stat equ 106
;SYS_mmap2 equ 192  ; Linux >=2.4.

; Linux i386 errno errnor numbers.
EEXIST equ 17

PROT:  ; Symbolic constants for Linux mmap(2).
.READ: equ 1
.WRITE: equ 2

MAP:  ; Symbolic constants for Linux mmap(2).
.PRIVATE: equ 2
.ANONYMOUS: equ 0x20

; Linux i386 open(2) flags constants.
O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2
O_TRUNC equ 1000q
O_CREAT equ 100q
O_APPEND equ 2000q
O_EXCL equ 200q
O_NOFOLLOW equ 400000q

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

_IOERR equ 040q  ; SunoOS 4.01 and 4.3BSD stdio.h.

%macro li3_syscall 0  ; Linux i386 syscall.
  int 0x80
%endm

%macro r 2  ; Relocates pointer-to-.text values %1..%2 (inclusive, countiny by 4).
  %assign __ra (%1)  ; First address.
  %assign __rb (%2)  ; Last address.
  incbin_until __ra  ; Check for offset errors.
  db 0x0d
  %assign __ra __ra+4
  %if __ra<=__rb
    %rep ((__rb-__ra)>>2)+1
      iu __ra
      db 0x0d
      %assign __ra __ra+4
    %endrep
  %endif
%endm

section .xtext
  xfill_until 0x0d1074
    ; sunos4as-1988-11-16.svr3 links dynamically against SunOS libc.so,
    ; which we don't have, so we provide an alternative libc (and libm)
    ; implementation, based on https://github.com/pts/minilibc686 .
    global _start
    _start:  ; Linux i386 program entry point. Also libc trampoline.
		; Allocate .bss manually, Linux 5.4.0 doesn't respect the memsz above. !! Add error to binpatch.inc.nasm.
		; void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);  /* libc interface, we don't use this, because we don't have a libc. */
		; void *sys_mmap(unsigned long *buffer);  /* We use this, for Linux 1.0 compatibility. */
		; void *sys_mmap2(void *addr, size_t length, int prot, int flags, int fd, unsigned long offset_shr_12);  /* We don't use this. */
		push strict byte 0  ; offset.
		push strict byte -1 ; fd.
		push strict byte MAP.PRIVATE|MAP.ANONYMOUS  ; flags.
		push strict byte PROT.READ|PROT.WRITE  ; prot.
		push strict dword ((s.xdata.vstart+s.xdata.vsize+0xfff)&~0xfff)-((s.xdata.vstart+s.xdata.fsize+0xfff)&~0xfff)  ; length.
		push strict ((s.xdata.vstart+s.xdata.fsize+0xfff)&~0xfff)  ; addr.
		mov ebx, esp  ; buffer, to be passed to sys_mmap(...).
		push strict byte SYS_mmap
		pop eax
		li3_syscall
		test eax, eax
		jnz .ok
		push strict byte -1
		call mini__exit  ; Doesn't return.
      .ok:	add esp, strict byte 6*4  ; Clean up `long buffer[6]' from the stack.
		pop eax  ; argc.
		mov edx, esp  ; argv.
		lea ecx, [edx+eax*4+4]  ; envp.
		mov [mini_environ], ecx
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
		;call mini___M_start_isatty_stdin  ; We don't use stdin.
		;call mini___M_start_isatty_stdout  ; We don't use stdout.
		call main
		;add esp, strict byte 3*4  ; Clean up arguments of main above. Not needed, we are just about to exit.
		push eax  ; Fake return address, for mini_exit.
		push eax  ; Exit code returned by main.
    mini_exit:  ; void mini_exit(int exit_code) __attribute__((__noreturn__));
		;call mini___M_start_flush_stdout ; We don't use stdout.
		call mini___M_start_flush_opened
		; Fall through.
    mini__exit:  ; void mini__exit(int exit_code) __attribute__((__noreturn__));
		push strict byte SYS_exit
		; Fall through to simple_syscall3.
    ; Implements a Linux i386 syscall the simplest way possible:
    ; * Input: dword [esp]: is the Linux syscall number. Any negative Linux result
    ;   indicates failure. This function will pop it.
    ; * Input: dword [esp+4]: The function return address.
    ; * Input: dword [esp+2*4]: First argument. Caller will pop it.
    ; * Input: dword [esp+3*4]: Second argument. Caller will pop it.
    ; * Input: dword [esp+4*4]: Third argument. Caller will pop it. At most
    ;   3 argumets are supported.
    ; * Output: EAX: result. -1 on failure.
    ; * Ruins: ECX and EDX.
    simple_syscall3:
		pop eax  ; Linux i386 syscall number.
      .in_eax:	push ebx  ; Save.
		mov ebx, [esp+2*4]
		mov ecx, [esp+3*4]
      .edx_do:	mov edx, [esp+4*4]
      .do:	li3_syscall
		pop ebx  ; Restore.
		test eax, eax
		jns strict short .ret
		;neg eax
		;mov [errno], eax  ; Not needed, this program doesn't use it.
		or eax, strict byte -1  ; EAX := -1.
      .ret:	ret

    mini_read:  ; ssize_t mini_read(int fd, void *buf, size_t count);
		push strict byte SYS_read
		jmp strict near simple_syscall3
    mini_write:  ; ssize_t mini_write(int fd, const void *buf, size_t count);
		push strict byte SYS_write
		jmp strict near simple_syscall3
    mini_lseek:  ; off_t mini_lseek(int fd, off_t offset, int whence);
		push strict byte SYS_lseek
		jmp strict near simple_syscall3
    mini_open:  ; int mini_open(const char *pathname, int flags, mode_t mode);
		push strict byte SYS_open
		jmp strict near simple_syscall3
    mini_close:  ; int mini_close(int fd);
		push strict byte SYS_close
		jmp strict near simple_syscall3
    mini_unlink:  ; int mini_unlink(const char *pathname);
		push strict byte SYS_unlink
		jmp strict near simple_syscall3
    mini_sys_brk:  ; void *mini_sys_brk(void *addr);
		push strict byte SYS_brk
		jmp strict near simple_syscall3

    ; Called from mini_exit(...). It flushes all files opened by mini_fopen(...).
    mini___M_start_flush_opened:  ; void mini___M_start_flush_opened(void);
		push ebx
		mov ebx, mini___M_global_files
      .next_file:
		cmp ebx, mini___M_global_files.end
		je .after_files
		push ebx
		call mini_fflush
		pop eax  ; Clean up argument of mini_fflush.
		add ebx, byte 0x24  ; sizeof(struct _SMS_FILE).
		jmp short .next_file
      .after_files:
		pop ebx
		ret

    mini_fprintf:  ; int fprintf(FILE *stream, const char *format, ...);
		push esp  ; 1 byte.
		add dword [esp], strict byte 3*4  ; 4 bytes.
		push dword [esp+3*4]  ; 4 bytes.
		push dword [esp+3*4]  ; 4 bytes.
		call mini_vfprintf  ; 5 bytes.
		add esp, strict byte 3*4  ; 3 bytes, same as `times 3 pop edx'.
		ret  ; 1 byte.

    mini_sprintf:  ; int mini_sprintf(char *str, const char *format, ...);
		lea edx, [esp+0xc]  ; Argument `...'.
		mov eax, edx  ; Smart linking could eliminate this (and use EDX instead) if mini_vsprintf(...) wasn't in use.
      mini_sprintf.do:  ; mini_vsprintf(...) jumps here.
		; It matches struct _SMS_FILE defined in c_stdio_medium.c. sizeof(struct _SMS_FILE).
		push byte 0  ; .buf_off.
		push byte -1  ; .buf_capacity_end.
		push dword [edx-8]  ; .buf_start == str argument.
		push byte 7  ; .dire == FD_WRITE_SATURATE. Also push the 3 .padding bytes.
		push byte -1  ; .fd.
		push byte 0  ; .buf_last.
		push byte 0  ; .buf_read_ptr.
		push byte -1  ; .buf_end: practically unlimited buffer.
		push dword [edx-8]  ; .buf_write_ptr == str argument.
		; int mini_vfprintf(FILE *filep, const char *format, va_list ap);
		mov ecx, esp  ; Address of newly created struct _SMS_FILE on stack.
		push eax  ; Argument ap of mini_vfprintf(...).
		push dword [edx-4]  ; Argument format of mini_vfprintf(...).
		push ecx  ; Argument filep of mini_vfprintf(...). Address of newly created struct _SMS_FILE on stack.
		call mini_vfprintf
		mov edx, [esp+3*4]  ; .buf_write_ptr.
		mov byte [edx], 0  ; Add '\0'. It's OK to omit the `EDX == NULL' check here, uClibc and EGLIBC also omit it.
		add esp, byte (3+9)*4  ; Clean up arguments of mini_vfprintf(...) and the struct _SMS_FILE from the stack.
		ret

    ; Limitation: It supports only format specifiers %s, %c, %u.
    ; Limitation: It doesn't work as a backend of snprintf(...) and vsnprintf(...) because it doesn't support FD_WRITE_SATURATE.
    ; Limitation: It doesn't return the number of bytes printed, it doesn't indicate error.
    mini_vfprintf:  ; void mini_vfprintf_simple(FILE *filep, const char *format, va_list ap);
		push ebx  ; Save.
		push esi  ; Save.
		push edi  ; Save.
		sub esp, strict byte 12  ; Scratch buffer for %u.
		push strict byte 10  ; Divisor `div' below.
		mov eax, [esp+8*4]  ; filep.
		call mini___M_writebuf_relax_RP1  ; mini___M_writebuf_relax_RP1(filep); Subsequent bytes written will be buffered until mini___M_writebuf_relax_RP1 below.
		mov esi, [esp+9*4]  ; format.
		mov edi, [esp+10*4]  ; ap.
      .next_fmt_char:
		lodsb
		cmp al, '%'
		je strict short .specifier
		cmp al, 0
		je strict short .done
      .write_char:
		call .call_mini_putc
		jmp strict .next_fmt_char
      .done:	mov eax, [esp+8*4]  ; filep.
		call mini___M_writebuf_unrelax_RP1  ; mini___M_writebuf_unrelax_RP1(filep);
		add esp, strict byte 16
		pop edi  ; Restore.
		pop esi  ; Restore.
		pop ebx  ; Restore.
		ret
      .specifier:
		lodsb
		cmp al, 's'
		je strict short .specifier_s
		cmp al, 'u'
		je strict short .specifier_u
		cmp al, 'c'
		jne strict short .write_char
		; Fall through.
      .specifier_c:
		mov al, [edi]
		add edi, strict byte 4
		jmp strict short .write_char
      .specifier_s:
		mov ebx, [edi]  ; EDI := start of NUL-terminated string.
		;test ebx, ebx
		;jz strict short .done_str  ; Don't crash on printing NULL. Not needed.
      .next_str_char:
		mov al, [ebx]
		inc ebx
		cmp al, 0
		je strict short .done_str
		call .call_mini_putc
		jmp strict short .next_str_char
      .done_str:
		add edi, strict byte 4
		jmp strict short .next_fmt_char
      .specifier_u:
		lea ebx, [esp+4+12-1]  ; Last byte of the scratch buffer for %u.
		mov byte [ebx], 0  ; Trailing NUL.
		mov eax, [edi]
      .next_digit:
		xor edx, edx  ; Set high dword of the dividend. Low dword is in EAX.
		div dword [esp]  ; Divide by 10.
		add dl, '0'
		dec ebx
		mov [ebx], dl
		test eax, eax  ; Put next digit to the scratch buffer.
		jnz strict short .next_digit
		jmp strict short .next_str_char
      .call_mini_putc:  ; Input: AL contains the byte to be printed. Can use EAX, EDX and ECX as scratch. Output: byte is written to the buffer.
		mov edx, [esp+8*4+4]  ; filep. (`4+' because of the return pointer of .call_mini_putc.)  AL contains the byte to be printed, the high 24 bits of EAX is garbage here.
		; Now we do inlined putc(c, filep). Memory layout must match <stdio.h> and c_stdio_medium.c.
		; int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini_fputc_RP3(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
		mov ecx, [edx]  ; ECX := buf_write_ptr.
		cmp ecx, [edx+4]  ; buf_end.
		je short .call_mini_fputc
		cmp al, 10  ; '\n'.
		je short .call_mini_fputc  ; In case filep == stdout and it's line buffered (_IOLBF).
		mov [ecx], al  ; *buf_write_ptr := AL.
		inc dword [edx]  ; buf_write_ptr += 1.
		ret
      .call_mini_fputc:
		; movsx eax, al : Not needed, mini_fputc ignores the high 24 bits anyway.
		;jmp strict near mini_fputc_RP3  ; With extra smart linking, we could hardcore an EOF (-1) return if only mini_snprintf(...) etc., bur no mini_fprintf(...) etc. is used.
		; Fall through to mini_fputc_RP3.
    mini_fputc_RP3:  ; int mini_fputc_RP3(int c, FILE *filep) __attribute__((__regparm__(3)));
		push ebx  ; Save EBX.
		mov ebx, edx
		movzx eax, al  ; Local variable uc will become argument c.
		push eax  ; Make room for local variable uc on the stack and set the lower 8 bits to c and the higher bits to junk.
		mov eax, [edx+0x4]  ; `dword [edx]' is `buf_write_ptr', `dword [edx+4]' is .buf_end.
		cmp [edx], eax
		jne .16
		push edx
		call mini_fflush
		pop edx
		test eax, eax
		jnz .err
		mov eax, [ebx+0x4]
		cmp [ebx], eax
		jne .16
		mov eax, esp  ; Address of local variable uc.
		push byte 1
		push eax
		push dword [ebx+0x10]
		call mini_write
		add esp, byte 0xc
		dec eax
		jnz .err
		jmp short .done
      .16:	mov edx, [ebx]
		inc edx
		mov [ebx], edx  ; ++filep->buf_write_ptr++;
		dec edx
		pop eax  ; Local variable uc.
		push eax
		mov [edx], al
		cmp al, 0xa  ; Local variable uc.
		jne .done
		cmp byte [ebx+0x14], 0x6  ; FD_WRITE_LINEBUF.
		jne .done
		push ebx
		call mini_fflush
		pop edx  ; Clean up the argument of mini_fflush from the stack. The pop register can be any of: EBX, ECX, EDX, ESI, EDI, EBP.
		test eax,  eax
		jz .done
      .err:	pop eax
		push byte -1  ; Return value := -1.
      .done:	pop eax  ; Remove zero-extended local variable uc from the stack, and use it as return value.
		pop ebx  ; Restore EBX.
		ret

    mini___M_writebuf_relax_RP1:
		cmp byte [eax+0x14], 4  ; FD_WRITE.
		jne .ret
		mov edx, [eax+0x1c]
		mov ecx, [eax+0x4]
		cmp edx, ecx
		jbe .ret
		inc byte [eax+0x14]  ; FD_WRITE_RELAXED.
		mov [eax+0x1c], ecx
		mov [eax+0x4], edx
      .ret:	ret

    mini___M_writebuf_unrelax_RP1:
		cmp byte [eax+0x14], 5  ; FD_WRITE_RELAXED.
		jne .done
		push ebx
		mov ebx, eax
		push eax
		call mini_fflush
		mov edx, [ebx+0x1c]
		mov ecx, [ebx+0x4]
		dec byte [ebx+0x14]  ; FD_WRITE.
		mov [ebx+0x4], edx
		mov [ebx+0x1c], ecx
		pop edx
		pop ebx
		ret
      .done:	xor eax, eax
		ret

    mini_fflush:  ; int mini_fflush(FILE *filep);
		push esi
		or ecx, byte -0x1
		push ebx
		mov ebx, [esp+0xc]
		cmp byte [ebx+0x14], 0x3
		jbe .4
		mov esi, [ebx+0x18]
      .6:	mov eax, [ebx]
		cmp eax, esi
		je .13
		sub eax, esi
		push eax
		push esi
		push dword [ebx+0x10]
		call mini_write
		add esp, byte 0xc
		lea edx, [eax+0x1]
		cmp edx, byte 0x1
		jbe .10
		add esi, eax
		jmp short .6
      .13:	xor ecx, ecx
		jmp short .7
      .10:	or ecx, byte -0x1
      .7:	sub esi, [ebx+0x18]
		add [ebx+0x20], esi
		push ebx  ; filep.
		call mini___M_discard_buf
		pop eax  ; Clean up argument filep of mini___M_discard_buf(...) from the stack.
      .4:	pop ebx
		mov eax, ecx
		pop esi
		ret

    mini___M_discard_buf:  ; void mini___M_discard_buf(FILE *filep);
		mov eax, [esp+0x4]
		mov edx, [eax+0x18]
		mov [eax+0xc], edx
		mov [eax], edx
		mov [eax+0x8], edx
		mov dl, [eax+0x14]
		dec edx  ; DL -= 1; higher bits of EDX := junk.
		cmp dl, 0x2
		ja .ret
		mov edx, [eax+0x4]
		mov [eax], edx
      .ret:	ret

    mini_bsd_signal:  ; sighandler_t mini_bsd_signal(int signum, sighandler_t handler);
		; SYS_signal doesn't work in qemu-i386 on Linux (it doesn't support
		; SYS_signal), and SYSV signals also has race conditions: if the signal
		; quickly hits again while handler is running and it hasn't
		; reestablished itself, then the signal can kill the process.
		;
		; We solve both of these problems by using sigaction(2) with BSD signal
		; semantics.
		;
		;push strict byte SYS_signal
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
      .done:	leave
		ret

    mini_isatty:  ; int mini_isatty(int fd);
		push ebx
		sub esp, strict byte 0x24
		push strict byte SYS_ioctl
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

    mini_strtod:  ; double mini_strtod(const char *str, char **endptr);
      %define STRTOD_VAR_TMP_DIGIT 0  ; 4 bytes.
      %define STRTOD_VAR_F32_10 4  ; 4 bytes f32.
      ;%define STRTOD_VARS_SIZE 8
      ; esp+9 is pushed EBP.
      ; esp+0xc is pushed EDI.
      ; esp+0x10 is pushed ESI.
      ; esp+0x14 is pushed EBX.
      ; esp+0x18 is the return address.
      %define STRTOD_ARG_STR 0x1c  ; 4 bytes char*.
      %define STRTOD_ARG_ENDPTR 0x20  ; 4 bytes char**.
      STRTOD_F32_10 equ 0x41200000  ; (f32)10.0.
      STRTOD_DECIMAL_DIG equ 21
      STRTOD_MAX_ALLOWED_EXP equ 4973
		push ebx
		push esi
		push edi
		push ebp
		push dword STRTOD_F32_10
		push ebp  ; Just a shorter `sub esp, byte 4'.
		mov ebx, [esp+STRTOD_ARG_STR]
      .1:	mov al, [ebx]
		cmp al, ' '
		je .2
		mov ah, al
		sub ah, 9  ; "\t".
		cmp ah, 4  ; ord("\r")-ord("\t").
		ja .3
      .2:	inc ebx
		jmp short .1
      .3:	xor ebp, ebp
		cmp al, '-'
		je .4
		cmp al, '+'
		je .5
		jmp short .6
      .4:	inc ebp  ; ++pos;
      .5:	inc ebx
      .6:	or eax, byte -1  ; num_digits = -1;
		xor edi, edi
		xor esi, esi
		fldz  ; number = 0;  `number' will be kept in ST0 for most of this function.
		xor edx, edx  ; Clear high 24 bits, for the `mov [esp+STRTOD_VAR_TMP_DIGIT], edx' below.
      .loop7:	mov dl, [ebx]
		sub dl, '0'
		cmp dl, 9
		ja .after_loop7
		test eax, eax
		jge .8
		inc eax
      .8:	test eax, eax
		jnz .9
		test dl, dl
		jz .10
      .9:	inc eax
		cmp eax, byte STRTOD_DECIMAL_DIG
		jg .10
		mov [esp+STRTOD_VAR_TMP_DIGIT], edx
		fmul dword [esp+STRTOD_VAR_F32_10]
		fiadd dword [esp+STRTOD_VAR_TMP_DIGIT]
      .10:	inc ebx
		jmp short .loop7
      .after_loop7:
		cmp dl, '.'-'0'
		jne .done_loop7
		test esi, esi
		jne .done_loop7
		inc ebx
		mov esi, ebx  ; pos0 = pos;
		jmp short .loop7
      .done_loop7:
		test eax, eax
		jge .18
		test esi, esi
		jne .17
		; Now we use ESI for something else (i), with initial value already 0.
		xor ecx, ecx  ; Keep high 24 bits 0, for ch and ecx below.
		mov [esp+STRTOD_VAR_TMP_DIGIT], esi  ; 0.
		mov esi, nan_inf_str
      .loop13:	mov edx, ebx
		mov eax, esi
		lea eax, [esi+1]  ; Same size as `mov' + `inc'.
      .14:	mov cl, [edx]
		or cl, 0x20
		cmp cl, [eax]
		jne .16
		inc edx
		inc eax
		cmp [eax], ch  ; Same as: cmp byte [eax], 0
		jne .14
		fstp st0  ; Pop `number' (originally in ST0) from the stack.
		fild dword [esp+STRTOD_VAR_TMP_DIGIT]
		fldz
		fdivp st1, st0
		test ebp, ebp
		je .15
		fchs  ; number = -number.
      .15:	mov cl, [esi]
		add ebx, ecx
		dec ebx
		dec ebx
		jmp short .store_done
      .16:	mov cl, [esi]
		add esi, ecx
		inc byte [esp+STRTOD_VAR_TMP_DIGIT]  ; Set it to anything positive.
		cmp cl, ch
		jne .loop13
      .17:	mov ebx, [esp+STRTOD_ARG_STR]  ; pos = str;
		jmp short .store_done
      .18:	cmp eax, byte STRTOD_DECIMAL_DIG
		jle .19
		sub eax, byte STRTOD_DECIMAL_DIG
		add edi, eax
      .19:	test esi, esi
		je .20
		mov eax, esi
		sub eax, ebx
		add edi, eax
      .20:	test ebp, ebp  ; if (negative);
		je .21
		fchs  ; number = -number;
      .21:	mov al, [ebx]
		or al, 0x20
		cmp al, 'e'
		jne .29
		mov [esp+STRTOD_VAR_TMP_DIGIT], ebx  ; pos1 = pos;  ! Maybe push ebx/pop ebx? Only if we don't use other variables in the meantime.
		xor esi, esi
		inc esi  ; negative = 1;
		inc ebx  ; Skip past the 'e'.
		mov al, [ebx]
		cmp al, '-'
		je .22
		cmp al, '+'
		je .23
		jmp short .24
      .store_done:  ; ; We put this to the middle so that we don't need `jmp near'.  STRTOD_VAR_NUMBER is already populated.
		mov eax, [esp+STRTOD_ARG_ENDPTR]  ; Argument endptr.
		test eax, eax
		je .36
		mov [eax], ebx
      .36:	fstp qword [esp]
		fld qword [esp]  ; By doing this fstp+fld combo, we round the result to f64.
		times 2 pop ebp  ; Just `add esp, byte STRTOD_VARS_SIZE'.
		pop ebp
		pop edi
		pop esi
		pop ebx
		ret
      .22:	neg esi  ; negative = -1;
      .23:	inc ebx
      .24:	mov ebp, ebx
		xor eax, eax
		xor edx, edx  ; Clear high 24 bits, for the `add eax, edx' below.
      .loop25:	mov dl, [ebx]
		sub dl, '0'
		cmp dl, 9
		ja .27
		cmp eax, STRTOD_MAX_ALLOWED_EXP  ; if (exponent_temp < STRTOD_MAX_ALLOWED_EXP);
		jge .26
		imul eax, byte 10
		add eax, edx
      .26:	inc ebx
		jmp short .loop25
      .27:	cmp ebx, ebp
		jne .28
		mov ebx, [esp+STRTOD_VAR_TMP_DIGIT]  ; pos = pos1;
      .28:	imul eax, esi
		add edi, eax
      .29:	fldz
		fucomp st1  ; if (number == 0.);  True for +0.0 and -0.0.
		fnstsw ax
		sahf
		je .store_done  ; if (number == 0.) goto DONE;
		mov eax, edi
		test eax, eax
		jz .store_done
		jge .skip_neg
		neg eax  ; Exponent_temp = -exponent_temp;
      .skip_neg:
		fld dword [esp+STRTOD_VAR_F32_10]  ; p_base = 10.0, but with higher (f80) precision.
      .loop31:	; Now: ST0 is p_base, ST1 is number.
		test al, 1
		jz .34
		test edi, edi
		jge .32
		fdiv st1, st0  ; number /= p_base;
		jmp short .34
      .32:	fmul st1, st0  ; number *= p_base;
      .34:	fmul st0, st0  ; p_base *= p_base;
		shr eax, 1
		jnz .loop31
		; Now: ST0 is p_base, ST1 is number.
		fstp st0  ; Pop p_base. `number' remains on the stack.
		jmp short .store_done

    better_getargs:
		call getargs
		cmp [filenames_0], strict byte 0
		jne strict near after_better_getargs
		jmp strict near fatal_usage

    ;ferror_rp3zz:  ; Input: FILE *stream in EAX. Output: ZF=!ferror(stream). Ruins: some flags other than ZF, but no other registers.
    ;		cmp eax, eax  ; ZF := 1 (no error). !! Add real implementation, do check errors.
    ;		ret
    ; Checks for ferror(stream).
    ; Input: FILE *stream in EAX. Output: ZF=!ferror(stream). Ruins: some flags other than ZF, but no other registers.
    ; We need to override the original code, because it has `#define ferror(...)' and our `struct _FILE' layout is different.
    %macro ferror_rp3zz_between 2
      incbin_until %1
      cmp eax, eax  ; ZF := 1 (no error). !! Add real implementation, do check errors.
      jmp strict short %%after
      xfill_until %2, nop
      %%after:
      assert_addr (%1)+9
    %endm

    %macro fgetc_rp3_between 2  ; Replaces some inline work + a call to _filbuf(...) with a call to mini_getc_RP3(...).
      incbin_until %1  ; Just after the `mov eax, [fdin]'.
      call mini_fgetc_RP3
      jmp strict short %%after
      xfill_until %2, nop
      %%after:
      assert_addr (%1)+0x1b
    %endm
    %macro fgetc_rp3_between 4  ; Replaces some inline work + a call to _filbuf(...) with a call to mini_getc_RP3(...).
      incbin_until %1  ; Just after the `mov eax, [fdin]'.
      call mini_fgetc_RP3
      jmp strict short %%after
      xfill_until %2, nop
      assert_addr (%1)+0x1b-12
      incbin_until %3
      xfill_until %4, nop
      %%after:
    %endm

    %macro isdigit_bl 2  ; Input: char in BL. Output: CF=isdigit(BL), ZF=!isdigit(BL). Ruins: AL (AX, EAX) and rest of flags.
      incbin_until %1
      ; This doesn't use the _ctype_ array.
      mov al, bl
      sub al, '0'
      cmp al, 10  ; CF := isdigit(BL).
      sbb al, al  ; ZF := !isdigit(BL). CF := isidigit(BL).
      jmp strict short %%after
      xfill_until %2, nop  ; 2+5 bytes of gap.
      %%after:
      assert_addr (%1)+15
    %endm

  xfill_until 0x0d14d4  ; There is a gap of 9 bytes in front of this. Original code (first incbin_until) starts here.
    getargs:
    incbin_until 0x0d154b
    call mini_strcmp
    incbin_until 0x0d15a7
    ; This is original functionality: checks for 'l', sets dlflag to 1, then jumps to flagcont (0x3f02e6).
    getargs__dflag:
    jmp_to_flagcont equ $+0x0d158f-0x0d15a7
    cmp al, 't'  ; New functionality: New flag -dt: Set timestamp in coff_filehdr_f_timdat to 0, for reproducible builds.
    jne strict short .not_t
    and dword [coff_filehdr_f_timdat], strict byte 0
    jmp strict short jmp_to_flagcont
    .not_t:
    call do_dflag_not_t
    jmp strict short jmp_to_flagcont
    xfill_until 0x0d15c0, nop  ; Gap of 5 bytes.
  incbin_until 0x0d15f3
    call mini_strlen
  incbin_until 0x0d15fb
    call mini_malloc
  incbin_until 0x0d160e
    call mini_strcpy
  incbin_until 0x0d164e
    push _iob_stderr
  incbin_until 0x0d1653
    call mini_fprintf
  incbin_until 0x0d16ab
    main:
    incbin_until 0x0d16b6
    fatal_usage:
    incbin_until 0x0d16c0
    push _iob_stderr
    incbin_until 0x0d16c5
    call mini_fprintf
    incbin_until 0x0d16cf
    call mini_exit
    incbin_until 0x0d16df
    jmp strict near better_getargs  ; Overrides getargs.
    after_better_getargs:
    incbin_until 0x0d16f2
      call mini_fopen
    incbin_until 0x0d1704
      call mini_fclose
    incbin_until 0x0d1710
      push _iob_stderr
    incbin_until 0x0d1715
      call mini_fprintf
    incbin_until 0x0d171f
      call mini_exit
    incbin_until 0x0d1775
      call mini_strlen
    incbin_until 0x0d177d
      call mini_malloc
    incbin_until 0x0d179f
      call mini_strcpy
    incbin_until 0x0d17ff
      call mini_strcpy
    incbin_until 0x0d181d
    push strict dword 0  ; Push NULL instead of "/tmp", for tempnam(3).
  incbin_until 0x0d1822
    call mini_tempnam_noremove  ; Originally this was a `call tempnap', but it's safer to do the cleanup later, because it avoids filesystem race conditions.
  incbin_until 0x0d1846
    call mini_exit
  incbin_until 0x0d1854
    yylex:
    fgetc_rp3_between 0x0d1869, 0x0d1884
    fgetc_rp3_between 0x0d1989, 0x0d19a4
    incbin_until 0x0d1a03
    call mini_ungetc
    fgetc_rp3_between 0x0d1a5e, 0x0d1a79
    incbin_until 0x0d1acb
    call mini_ungetc
    fgetc_rp3_between 0x0d1ae6, 0x0d1b01
    incbin_until 0x0d1bee
    call mini_ungetc
    fgetc_rp3_between 0x0d1c18, 0x0d1c33
    incbin_until 0x0d1c86
    call mini_ungetc
    fgetc_rp3_between 0x0d1cf4, 0x0d1d0f
    fgetc_rp3_between 0x0d1d57, 0x0d1d66, 0x0d1d7b, 0x0d1d87
    fgetc_rp3_between 0x0d1dcf, 0x0d1dea
    fgetc_rp3_between 0x0d1e1e, 0x0d1e39
    fgetc_rp3_between 0x0d1e94, 0x0d1eaf
    fgetc_rp3_between 0x0d1ef5, 0x0d1f10
    incbin_until 0x0d1f30
    call mini_ungetc
    fgetc_rp3_between 0x0d2055, 0x0d2070
    incbin_until 0x0d20c2
    call mini_ungetc
    fgetc_rp3_between 0x0d213a, 0x0d2155
    fgetc_rp3_between 0x0d2174, 0x0d218f
    fgetc_rp3_between 0x0d21fb, 0x0d2216
    incbin_until 0x0d224e
    call mini_ungetc
    assert_addr 0x0d2253
    times 2 pop ecx  ; Clean up arguments of the previous mini_ungetc call from the stack.
    ; Instead of calling atob16f(...), call mini_strtod(...).
    push eax  ; end value, will be overwritten by mini_strtod(...).
    push esp  ; endptr argument of mini_strtold(...).
    push strict dword yytext  ; nptr argument of mini_strtold(...).
    call mini_strtod
    fstp dword [ebp-0x10]  ; Result as a 32-bit float.
    pop eax  ; Argument nptr.
    pop ecx  ; Argument endptr, ignored.
    pop ecx  ; end value.
    cmp eax, ecx
    jne strict short .ok
    jmp strict short .error
    xfill_until 0x0d226f, nop  ; Gap of 2 bytes.
    .error:
    incbin_until 0x0d2286
    .ok:
    incbin_until 0x0d22af
  incbin_until 0x0d232c
    yyparse:
    incbin_until 0x0d2345
    jmp strict short .after_yynerrs1
    xfill_until 0x0d234f, nop  ; Gap of 2+8 bytes. Previously it was: mov dword [yynerrs], 0
    .after_yynerrs1:
    incbin_until 0x0d236a
    jmp strict short .after_nodebug1  ; Previously it was code using yydebug.
    xfill_until 0x0d238a, nop  ; Gap of 0x1e bytes.
    .after_nodebug1:
    incbin_until 0x0d254e
    jmp strict short .after_yynerrs2
    xfill_until 0x0d2554, nop  ; Gap of 2+4 bytes. Previously it was: inc dword [yynerrs]
    .after_yynerrs2:
    incbin_until 0x0d25d1
    jmp strict short .after_nodebug2  ; Previously it was code using yydebug.
    xfill_until 0x0d25f0, nop  ; Gap of 0x1d bytes.
    .after_nodebug2:
    incbin_until 0x0d260a
    jmp strict short .after_nodebug3  ; Previously it was code using yydebug.
    xfill_until 0x0d2626, nop  ; Gap of 0x1a bytes.
    .after_nodebug3:
    incbin_until 0x0d270d
    call mini_strlen
    incbin_until 0x0d272e
    call mini_strcpy
    incbin_until 0x0d312d
    call mini_strcmp
    incbin_until 0x0d3141
    call mini_strcmp
    incbin_until 0x0d3155
    call mini_strcmp
    incbin_until 0x0d3169
    call mini_strcmp
    incbin_until 0x0d317d
    call mini_strcmp
    incbin_until 0x0d3191
    call mini_strcmp
    incbin_until 0x0d3311
    call mini_strcmp
    incbin_until 0x0d3325
    call mini_strcmp
    incbin_until 0x0d3339
    call mini_strcmp
    incbin_until 0x0d589c
    call mini_strcpy
    incbin_until 0x0d5956
    .case_call_comment:
    incbin_until 0x0d595e
    .case_do_not_call_comment:
    incbin_until 0x0d5b5e
    push _iob_stderr
    incbin_until 0x0d5b63
    call mini_fprintf
    incbin_until 0x0d5b8d
    push _iob_stderr
    incbin_until 0x0d5b92
    call mini_fprintf
    incbin_until 0x0d5f71
    jmp strict short .after_nodebug4  ; Previously it was code using yydebug.
    xfill_until 0x0d5f8f, nop  ; Gap of 0x1c bytes.
    .after_nodebug4:
  incbin_until 0x0d6e47
    call mini_sprintf
  incbin_until 0x0d7034
    aspass1:
    incbin_until 0x0d703a
    jmp strict short .after_passnbr  ; Previously it was `mov word [passnbr], 1', but the zero is fine for us.
    xfill_until 0x0d7043, nop  ; Gap.
    .after_passnbr:
    incbin_until 0x0d7047
    call mini_bsd_signal
    incbin_until 0x0d7053
    push strict dword signal_handler  ; Function pointer, relocated within .xtext.
    incbin_until 0x0d705a
    call mini_bsd_signal
    incbin_until 0x0d7066
    call mini_bsd_signal
    incbin_until 0x0d7072
    push strict dword signal_handler  ; Function pointer, relocated within .xtext.
    incbin_until 0x0d7079
    call mini_bsd_signal
    incbin_until 0x0d7085
    call mini_bsd_signal
    incbin_until 0x0d7091
    push strict dword signal_handler  ; Function pointer, relocated within .xtext.
    incbin_until 0x0d7098
    call mini_bsd_signal
    incbin_until 0x0d70a6
    dd _iob_stderr
    incbin_until 0x0d70b5
    call mini_fopen
    incbin_until 0x0d7119
    call mini_fclose
  incbin_until 0x0d71b2
    call mini_strlen
  incbin_until 0x0d71ff
    lookup:
    incbin_until 0x0d72a5
    call mini_strcmp
    incbin_until 0x0d72b1
    cmp byte [passnbr_minus_1], 0
    jmp strict short .after_passnbr1  ; Previously it was `mov word [passnbr], 2'.
    xfill_until 0x0d72bd, nop  ; Gap.
    .after_passnbr1:
    incbin_until 0x0d7312
    cmp byte [passnbr_minus_1], 1
    jmp strict short .after_passnbr2  ; Previously it was `mov word [passnbr], 2'.
    xfill_until 0x0d731e, nop  ; Gap.
    .after_passnbr2:
  incbin_until 0x0d73e7
    call mini_strlen
  incbin_until 0x0d7414
    call mini_realloc
  incbin_until 0x0d743d
    call mini_strcpy
  incbin_until 0x0d7464
    call mini_malloc
  incbin_until 0x0d7593
    call mini_fwrite
  incbin_until 0x0d762f
    call mini_fwrite
  incbin_until 0x0d76b4
    call mini_fwrite
  incbin_until 0x0d7736
    call mini_fwrite
  incbin_until 0x0d774a
    call mini_fflush
  ferror_rp3zz_between 0x0d7752, 0x0d775b
  incbin_until 0x0d776a
    call mini_fclose
  incbin_until 0x0d788d
    call mini_strlen
  incbin_until 0x0d78c4
    call mini_fopen
  incbin_until 0x0d795a
    call mini_strncpy
  incbin_until 0x0d8268
    signal_handler:
    push dword [__pathname_o_out]
    call mini_unlink
    call deltemps
    push strict byte EXIT_FATAL  ; exit_code
    call mini__exit  ; Don't flush stdio streams, there is a data race.
    xfill_until 0x0d8290  ; Gap of 17 bytes.
  incbin_until 0x0d82df
    push _iob_stderr
  incbin_until 0x0d82e4
    call mini_fprintf
  incbin_until 0x0d8308
    errmsg:
    incbin_until 0x0d8317
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
    xfill_until 0x0d8334, nop  ; About 10 bytes of gap, until the push aAssemblerS.
    .push:
  incbin_until 0x0d8339
    push _iob_stderr
  incbin_until 0x0d833e
    call mini_fprintf
  incbin_until 0x0d835c
    push _iob_stderr
  incbin_until 0x0d8361
    call mini_fprintf
  incbin_until 0x0d8381
    push _iob_stderr
  incbin_until 0x0d8386
    call mini_fprintf
  incbin_until 0x0d8399
    push _iob_stderr
  incbin_until 0x0d839e
    call mini_fprintf
  incbin_until 0x0d83ad
    push _iob_stderr
  incbin_until 0x0d83b2
    call mini_fprintf
  incbin_until 0x0d83c5
    call mini_unlink
  incbin_until 0x0d83d2
    call mini_exit
  incbin_until 0x0d83da
    deltemps:  ; !! Test call and successful temporary file deletion from signal_handler.
  incbin_until 0x0d83ee
    call mini_unlink
  incbin_until 0x0d848e
    call mini_fwrite
  incbin_until 0x0d84e9
    call mini_fwrite
  incbin_until 0x0d8918
    call mini_strcmp
  incbin_until 0x0d8c9e
    call mini_fwrite
  incbin_until 0x0d8d5c
    ;atob16f:  ; Not used anymore.
    ;xfill_until 0x0d8ed9
    ;incbin_until 0x0d8ed9
    ;lclatof:  ; Not used anymore, it was used by atob16f(...).
    ;xfill_until 0x0d9103

    mini_time:  ; time_t mini_time(time_t *tloc);
		push ebx  ; Save.
		push strict byte SYS_time
		pop eax
		mov ebx, [esp+2*4]  ; tloc.
		li3_syscall
		pop ebx  ; Restore.
		ret  ; Don't check the result (EAX < 0), assume that it always succeeds.

    mini_strcpy:  ; char *mini_strcpy(char *dest, const char *src);
		push edi
		push esi
		mov edi, [esp+0xc]
		mov esi, [esp+0x10]
		push edi
      .next3:	lodsb
		stosb
		test al, al
		jnz strict short .next3
		pop eax  ; Result: pointer to dest.
		pop esi
		pop edi
		ret

    mini_memset:  ; void *mini_memset(void *s, int c, size_t n);
		push edi
		mov edi, [esp+8]  ; Argument s.
		mov al, [esp+0xc]  ; Argument c.
		mov ecx, [esp+0x10]  ; Argument n.
		push edi
		rep stosb
		pop eax  ; Result is argument s.
		pop edi
		ret

    mini_calloc:  ; void *mini_calloc(size_t nmemb, size_t size);
		mov eax, [esp+4]
		mul dword [esp+8]
		test edx, edx
		jz .size_done
		xor eax, eax  ; TODO(pts): Set errno := ENOMEM.
		ret
    .size_done:	push eax  ; Argument size of mini_realloc.
		push byte 0  ; Argument ptr of mini_realloc.
		call mini_realloc
		pop edx  ; Clean up argument ptr of mini_realloc from the stack.
		; memset(result_ptr, '\0', nmemb * size).
		pop ecx  ; Argument size of mini_realloc.
		push edi
		push eax
		xor edi, edi
		xchg edi, eax
		rep stosb
		pop eax
		pop edi
		ret

    mini_getenv:  ; char *mini_getenv(const char *name);
		push esi
		push edi
		mov ecx, [mini_environ]
      .next_var:
		mov edi, [ecx]
		add ecx, byte 4
		test edi, edi
		jz .done
		mov esi, [esp+3*4]  ; Argument name.
      .next_byte:
		lodsb
		cmp al, 0
		je .end_name
		scasb
		je .next_byte
		jmp short .next_var
      .end_name:
		mov al, '='
		scasb
		jne .next_var
      .done:	xchg eax, edi  ; EAX := EDI (pointer to var value); EDI := junk.
		pop edi
		pop esi
		ret

    mini_malloc:  ; void *mini_malloc(size_t size);
		push dword [esp+4]
		push byte 0
		call mini_realloc
		times 2 pop edx  ; Clean up arguments of mini_realloc from the stack.
		ret

    mini_realloc:  ; void *mini_realloc(void *ptr, size_t size);
      ; This is a short and fast (O(1) per operation) allocator, but it wastes
      ; memory (less than 50%).
      ;
      ; It returns pointer aligned to a multiple of 4 bytes (or size_t,
      ; whichever is larger). Each malloc(...), free(...) and realloc(...)
      ; call takes O(1) time. Less than 50% of the allocated memory is
      ; wasted because of occasional rounding up to the next power of 2. If
      ; there is no free(...) or reallocating realloc(...) call, then the
      ; overhead per block is just 4 bytes + alignment (0..3 bytes).
      ;
      ; New memory blocks are requested from the system using
      ; mini_malloc_simple_unaligned(...), which eventually calls
      ; mini_sys_brk(...). There are 30 buckets (corresponding to block sizes
      ; 1<<2 .. 1<<31), each containing a signly linked list of free()d
      ; blocks. When a new block is allocated, the corresponding bucket size
      ; is tried. Blocks remain in their respective buckets, they are never
      ; joined or split. The rounding up to the next power of 2 happens in
      ; realloc(...) only, thus free()d blocks in the buckets don't have a
      ; power-of-2 size. To combat fragmentation (in a limited way), a best
      ; fit match of up to BEST_FIT_LIMIT (16) free()d blocks is tried in
      ; the previous (1 smaller) bucket, so a malloc(n) after a recent
      ; free(n) would assign the same block, without fragmentation.
      REALLOC_BEST_FIT_LIMIT equ 16
		push ebp
		push edi
		push esi
		push ebx
		push ecx
		mov edi, [esp+0x18]
		mov ebx, [esp+0x1c]
		xor eax, eax  ; For .done.
		test ebx, ebx
		js short .done  ; TODO(pts): Set errno := ENOMEM.
		test edi, edi
		jne near .3
		test ebx, ebx
		jne .4
		mov ebx, 1
      .4:	add ebx, byte 3
		and ebx, byte -4
		mov edx, mini_realloc_free_bucket_heads
		xor eax, eax
		mov al, 4
      .5:	cmp ebx, eax
		jbe .39
		add eax, eax
		add edx, byte 4
		jmp short .5
      .39:	lea eax, [ebx-1]
		test eax, ebx
		je .7
		lea edi, [edx-4]
		mov eax, [edx-4]
		mov byte [esp+3], REALLOC_BEST_FIT_LIMIT  ; best_fit_limit.
		xor esi, esi
		or ebp, byte -1
      .8:	test eax, eax
		je .10
		mov ecx, [eax-4]
		cmp ebx, ecx
		ja .9
		sub ecx, ebx
		cmp ecx, ebp
		jnb .9
		mov esi, edi
		mov ebp, ecx
      .9:	mov ecx, [eax]
		mov edi, eax
		dec byte [esp+3]  ; best_fit_limit.
		je .10
		mov eax, ecx
		jmp short .8
      .10:	test esi, esi
		je .7
		mov edi, [esi]
		mov eax, [edi]
		mov [esi], eax
      .return_edi:
		mov eax, edi
      .done:	pop edx
		pop ebx
		pop esi
		pop edi
		pop ebp
		ret
      .7:		mov edi, [edx]
		test edi, edi
		je .13
		mov eax, [edi]
		mov [edx], eax
		jmp short .return_edi
      .13:	lea eax, [ebx+4]
		push eax
		call mini_malloc_simple_unaligned
		pop edx
		test eax, eax
		jz .done  ; TODO(pts): Set errno := ENOMEM.
		mov [eax], ebx
		lea edi, [eax+4]
		jmp short .return_edi
      .3:	test ebx, ebx
		jne .14
      .do_free:	mov ecx, [edi-4]
		mov eax, mini_realloc_free_bucket_heads
		xor edx, edx
		mov dl, 4
      .16:	cmp edx, ecx
		ja .40
		add edx, edx
		add eax, byte 4
		jmp short .16
      .40:	mov edx, [eax-4]
		mov [edi], edx
		mov [eax-4], edi
		mov edi, ebx
		jmp short .return_edi
      .14:	mov esi, [edi-4]
		xor eax, eax
		mov al, 4
		cmp ebx, esi
		jbe .return_edi
      .18:	cmp eax, ebx
		jnb .41
		add eax, eax
		jmp short .18
      .41:	push eax
		push byte 0
		call mini_realloc
		mov ebx, eax
		pop ecx
		pop ebp
		test eax, eax
		jz .done  ; TODO(pts): Set errno := ENOMEM.
		; memcpy ESI bytes from EDI to EAX, may ruin EAX, ECX and ESI.
		push edi
		xchg eax, edi
		xchg eax, esi
		xchg eax, ecx  ; ECX := byte count; EAX := junk.
		rep movsb
		pop edi
		jmp short .do_free

    mini_malloc_simple_unaligned:  ; void *mini_malloc_simple_unaligned(size_t size);
      ; Implemented using mini_sys_brk(2). Equivalent to the following C code,
      ; but was size-optimized.
      ;
      ; A simplistic allocator which creates a heap of 64 KiB first, and
      ; then doubles it when necessary. It is implemented using Linux system
      ; call brk(2), exported by the libc as mini_sys_brk(...). free(...)ing is
      ; not supported. Returns an unaligned address (which is OK on x86).
		push ebx
		mov eax, [esp+8]  ; Argument named size.
		test eax, eax
		jle .18
		mov ebx, eax
		cmp dword [_malloc_simple_base], byte 0
		jne .7
		xor eax, eax
		push eax ; Argument of mini_sys_brk(2).
		call mini_sys_brk  ; It destroys ECX and EDX.
		pop ecx  ; Clean up argument of mini_sys_brk2(0).
		mov [_malloc_simple_free], eax
		mov [_malloc_simple_base], eax
		test eax, eax
		jz short .18
		mov eax, 0x10000  ; 64 KiB minimum allocation.
      .9:	add eax, [_malloc_simple_base]
		jc .18
		push eax
		push eax ; Argument of mini_sys_brk(2).
		call mini_sys_brk  ; It destroys ECX and EDX.
		pop ecx  ; Clean up argument of mini_sys_brk(2).
		pop edx  ; This (and the next line) could be ECX instead.
		cmp eax, edx
		jne .18
		mov [_malloc_simple_end], eax
      .7:	mov edx, [_malloc_simple_end]
		mov eax, [_malloc_simple_free]
		mov ecx, edx
		sub ecx, eax
		cmp ecx, ebx
		jb .21
		add ebx, eax
		mov [_malloc_simple_free], ebx
		jmp short .17
      .21:	sub edx, [_malloc_simple_base]
		mov eax, 1<<20  ; 1 MiB.
		cmp edx, eax
		jnbe .22
		mov eax, edx
      .22:	add eax, edx
		test eax, eax  ; ZF=..., SF=..., OF=0.
		jg .9  ; Jump iff ZF=0 and SF=OF=0. Why is this correct?
      .18:	xor eax, eax
      .17:	pop ebx
		ret

    mini_tempnam_noremove:  ; char *mini_tempnam_noremove(const char *dir, const char *pfx);
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x10]  ; dir.
		mov esi, [esp+0x14]  ; pfx.
		push dword str_tmpdir
		call mini_getenv
		pop edx  ; Clean up argument of mini_getenv.
		mov edi, eax
		call direxists_RP1
		test eax, eax
		jnz short .2
		mov eax, ebx  ; dir.
		mov edi, eax
		call direxists_RP1
		test eax, eax
		jnz short .2
		mov eax, str_tmp
		mov edi, eax
		call direxists_RP1
		test eax, eax
		jz short .24
      .2:	;test esi, esi
		;jnz short .4
		;mov esi, str_temp  ; "temp_". Not needed in this program, pfx is never NULL.
      .4:	mov eax, 8
      .5:	cmp byte [esi+eax-8], 0
		je short .26
		inc eax
		jmp short .5
      .26:	mov edx, edi
		sub edx, eax
      .7:	cmp byte [edx+eax], 0
		je short .27
		inc eax
		jmp short .7
      .27:	push eax
		call mini_malloc
		pop edx
		test eax, eax
		jz short .1
		xchg ebx, eax  ; EBX := EAX; EAX := junk. Save EBX for the argument of mini_mkstemp(...).
		mov edx, ebx
		xchg edx, edi
      .10:	mov al, [edx]
		test al, al
		je short .28
		inc edx
		stosb
		jmp short .10
      .28:	mov al, '/'
		stosb
      .12:	lodsb
		test al, al
		je short .29
		stosb
		jmp short .12
      .29:	push byte 6
		pop ecx
		mov al, 'X'
		rep stosb
		mov byte [edi], 0  ; We don't need EDI after this.
		push ebx
		call mini_mkstemp
		pop edi
		test eax, eax
		jns short .15
		push byte 0
		push ebx
		call mini_realloc  ; mini_free(EBX);
		times 2 pop edx  ; Clean up arguments of mini_relloc(...) above.
      .24:	xor eax, eax
		jmp short .1
      .15:	push eax
		call mini_close
		pop edx
		xchg eax, ebx  ; EAX := EBX; EBX := junk.
      .1:	pop ebx
		pop esi
		pop edi
		ret

    direxists_RP1:  ; int direxists_RP1(const char *dir) __attribute__((__regparm__(1)));
      ; struct stat buf;
      ; return stat(dir, &buf) == 0 && S_ISDIR(buf.st_mode);
		push ebx  ; Save.
		xchg ebx, eax  ; EBX := EAX (dir); EBX := junk.
		test ebx, ebx
		jnz short .not_null
      .ret_0:	pop ebx  ; Restore.
		xor eax, eax
		ret
      .not_null:
		cmp byte [ebx], 0
		je short .ret_0
		sub esp, byte 64
		mov ecx, esp
		push byte SYS_stat
		pop eax
		int 0x80  ; Linux i386 syacall.
		mov cl, [ecx+9]  ; High byte of st_mode.
		add esp, byte 64
		test eax, eax
		jnz short .ret_0
		xor eax, eax
		and cl, 0xf0
		cmp cl, 0x40
		sete al
		pop ebx  ; Restore.
		ret

    mini_mkstemp:  ; int mini_mkstemp(char *template);
		push edi
		push esi
		push ebx
		mov esi, [esp+0x10]  ; Argument template.
		mov eax, esi
      .2:	cmp byte [eax], 0x0
		je short .15
		inc eax
		jmp short .2
      .15:	lea ebx, [eax-0x6]
		cmp esi, ebx
		ja short .4
		mov edi, ebx
      .7:	cmp byte [edi], 'X'
		je short .5
      .4:	;mov dword [mini_errno], EINVAL  ; TODO(pts): Set errno if used by the program.
		jmp near .err  ; Doesn't fit to a short jump.
      .5:	inc edi
		cmp edi, eax
		jne short .7
		; We put a reasonably random number in EAX by mixing the return address, our address, ESP, gettimeofday() sec, gettimeofday() msec and getpid().
		mov eax, [esp+0xc]  ; Function return address.
		call mini_prng_mix3_RP3
		add eax, mini_mkstemp
		call mini_prng_mix3_RP3
		add eax, esp
		call mini_prng_mix3_RP3
		push ebx  ; Save address of first 'X', to be replaced.
		push eax  ; Save.
		push byte SYS_getpid
		pop eax
		int 0x80  ; Linux i386 syscall. EAX := getpid().
		pop edx  ; Restore saved EAX.
		add eax, edx
      .retry:	call mini_prng_mix3_RP3
		push eax  ; Save.
		push eax  ; Make room for tv_usec output.
		push eax  ; Make room for tv_sec output.
		mov ebx, esp  ; Argument tv of gettimeofday.
		xor ecx, ecx  ; Argument tz of gettimeofday (NULL).
		push byte SYS_gettimeofday
		pop eax
		int 0x80  ; Linux i386 syscall.
		pop ecx  ; tv_sec.
		pop ebx  ; tv_usec.
		pop eax  ; Restore.
		add eax, ecx
		call mini_prng_mix3_RP3
		add eax, ebx
		call mini_prng_mix3_RP3
		pop ebx  ; Restore address of the first 'X', to be replaced.
		; Now we have our reasonably random number in EAX.
		push eax  ; Save, will be restored to EDX.
		mov edx, ebx  ; Address of the first 'X', to be replaced.
      .8:	mov ecx, eax  ; ECX := random (EAX).
		and eax, byte 0x1f  ; 5 bits.
		cmp al, 9
		jna short .10
		add al, 'a'-10-'0'
      .10	add al, '0'
		mov [edx], eax
		xchg ecx, eax  ; EAX := old random; ECX := junk.
		shr eax, 5
		inc edx
		cmp edx, edi
		jne short .8
		push ebx  ; Save.
		mov edx, 600q
		mov ecx, O_CREAT|O_RDWR|O_EXCL|O_NOFOLLOW
		mov ebx, esi  ; Template with 'X's replaced by random characters.
		push byte SYS_open
		pop eax
		int 0x80  ; Linux i386 syscall.
		pop ebx  ; Restore.
		pop edx  ; Restore random number.
		test eax, eax
		jns short .1
		cmp eax, byte -EEXIST
		jne short .err
		xchg eax, edx  ; EAX := EDX (random number); EDX := junk.
		push ebx
		jmp short .retry
      .err:	or eax, byte -1
      .1:	pop ebx
		pop esi
		pop edi
		ret

    xfill_until 0x0d9103  ; Gap of 9 bytes.
  incbin_until 0x0d929b
    doreals:
    incbin_until 0x0d92a4
    ; Instead of calling sscanf(3) call mini_strtod(...).
    push strict byte 0  ; endptr argument of mini_strtod(...).
    push strict dword [ebp+3*4]  ; nptr argument of mini_strtod(...).
    call mini_strtod
    pop eax  ; Clean up argument nptr from the stack.
    pop eax  ; Clean up argument endptr from the stack.
    fstp qword [ebp-8]  ; Store the parsed double to a local variable.
    jmp strict short .after
    xfill_until 0x0d92b5, nop  ; Gap of 2+2 bytes.
    .after:
  incbin_until 0x0d94b4
    aspass2:
    incbin_until 0x0d94c2
    inc byte [passnbr_minus_1]  ; Change from 0 to 1.
    jmp strict short .after_passnbr  ; Previously it was `mov word [passnbr], 2'.
    xfill_until 0x0d94cb, nop  ; Gap.
    .after_passnbr:
    incbin_until 0x0d955c
    call mini_fopen
    incbin_until 0x0d9573
    call mini_unlink
    incbin_until 0x0d958b
    call mini_fopen
    incbin_until 0x0d95b5
    call mini_exit
    incbin_until 0x0d95cb
    call mini_ftell
    incbin_until 0x0d95f9
    call mini_fseek
    incbin_until 0x0d960c
    call mini_fopen
    incbin_until 0x0d9633
    call mini_fopen
    incbin_until 0x0d965a
    call mini_fopen
    incbin_until 0x0d9681
    call mini_fopen
    incbin_until 0x0d9755
    call mini_fflush
    ferror_rp3zz_between 0x0d9760, 0x0d9769
    incbin_until 0x0d977c
    call mini_fclose
    incbin_until 0x0d9788
    call mini_fflush
    ferror_rp3zz_between 0x0d9793, 0x0d979c
    incbin_until 0x0d97af
    call mini_fclose
    incbin_until 0x0d97bb
    call mini_fflush
    ferror_rp3zz_between 0x0d97c6, 0x0d97cf
    incbin_until 0x0d97e2
    call mini_fclose
    incbin_until 0x0d97f3
    call mini_fopen
    incbin_until 0x0d981a
    call mini_fclose
    incbin_until 0x0d9826
    call mini_fflush
    ferror_rp3zz_between 0x0d9831, 0x0d983a
    incbin_until 0x0d984d
    call mini_fclose
    incbin_until 0x0d9859
    call mini_ftell
    incbin_until 0x0d986c
    call mini_fseek
    incbin_until 0x0d98b2
    call mini_fseek
    incbin_until 0x0d98c5
    call mini_fopen
    incbin_until 0x0d98f0
    call mini_fclose
    incbin_until 0x0d9922
    call mini_fflush
    incbin_until 0x0d99ad
    call mini_fseek
    incbin_until 0x0d99c4
    call mini_fwrite
    incbin_until 0x0d99e8
    call mini_fwrite
    incbin_until 0x0d99f6
    call mini_fflush
    ferror_rp3zz_between 0x0d9a01, 0x0d9a0a
    incbin_until 0x0d9a1d
    call mini_fclose
  incbin_until 0x0d9a94
    call mini_fopen
  incbin_until 0x0d9ad3
    call mini_fwrite
  incbin_until 0x0d9b0d
    call mini_fread
  incbin_until 0x0d9b29
    call mini_fwrite
  incbin_until 0x0d9b3c
    call mini_fread
  incbin_until 0x0d9b52
    call mini_fclose
  incbin_until 0x0d9b7f
    setfile:
    incbin_until 0x0d9c3c
    times 2 pop ecx  ; Clean up the arguments of the previous call to endef(...). Shorter than the original.
    cmp byte [dgflag], 0
    jne strict short .after_lg_break  ; Omit the `-lg' symbol.
    ; This is a shortened version of the original code so that the comparison above fits.
    push strict byte 0
    push strict byte 1
    push strict dword aLg_0
    call lookup
    add esp, strict byte 3*4
    call put_lg_break
    mov byte [dword_B2884], 1  ; Shorter than the original `mov'.
    assert_addr 0x0d9c64
    .after_lg_break:  ; End of shortened version of the original code.
    incbin_until 0x0d9c69
  incbin_until 0x0d9cc4
    call mini_fwrite
  incbin_until 0x0d9d30
    call mini_fwrite
  incbin_until 0x0d9fc0
    unused_inline:
    xfill_until 0x0d9fce
  incbin_until 0xda05a
    put_lg_break:
  incbin_until 0x0da067
    call mini_strcpy
  incbin_until 0x0da0a8
    call mini_fwrite
  incbin_until 0x0da41f
    call mini_fwrite
  incbin_until 0x0da510
    call mini_memset
  incbin_until 0x0da55a
    call mini_fwrite
  incbin_until 0x0da582
    call mini_fwrite
  incbin_until 0x0da5ac
    call mini_fwrite
  incbin_until 0x0da688
    call mini_fwrite
  incbin_until 0x0da844
    call mini_fwrite
  incbin_until 0x0da863
    call mini_fwrite
  incbin_until 0x0da872
    unused_dotzero:
    xfill_until 0x0da8b0
  incbin_until 0x0da8b0
    codgen:
    incbin_until 0x0da971
    ; mini_fputc_RP3(outword, fdsect);
    movzx eax, byte [outword]  ; Why not movsx? Was char unsigned in the compiler?
    mov edx, [fdsect]
    call mini_fputc_RP3
    jmp strict near codegen.after_fputc

    mini_fread:  ; size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
		push ebp
		mov ebp, esp
		push ebx
		push edi
		push esi
		mov ebx, [ebp+0x10]
		imul ebx, [ebp+0xc]
		xor eax, eax
		test ebx, ebx
		je .6
		mov edi, [ebp+0x14]
		mov cl, [edi+0x14]
		dec cl
		cmp cl, 0x2
		ja .6
		mov esi, [ebp+0x8]
      .3:	mov eax, [edi+0x8]
		mov ecx, [edi+0xc]
		cmp eax, ecx
		jne .4
		sub ecx, [edi+0x18]
		add [edi+0x20], ecx
		push edi
		call dword mini___M_discard_buf
		add esp, byte 4
		mov eax, [edi+0x4]
		mov ecx, [edi+0x18]
		sub eax, ecx
		push eax
		push ecx
		push dword [edi+0x10]
		call dword mini_read
		add esp, byte 0xc
		lea ecx, [eax+0x1]
		cmp ecx, byte 2
		jb .5
		add [edi+0xc], eax
		jmp short .3
      .4:	lea ecx, [eax+0x1]
		mov [edi+0x8], ecx
		mov al, [eax]
		mov [esi], al
		inc esi
		dec ebx
		jne .3
      .5:	sub esi, [ebp+0x8]
		xor edx, edx
		mov eax, esi
		div dword [ebp+0xc]
      .6:	pop esi
		pop edi
		pop ebx
		pop ebp
		ret

    codegen.after_fputc:
    assert_addr 0x0daa03
    and word [poscnt], byte 0  ; Shorter than the original becase `and' is shorter than `mov'.
    assert_addr 0x0daa0b  ; No gap, just a few bytes.
    incbin_until 0x0daa2b
  incbin_until 0x0daa77
    call mini_fopen
  incbin_until 0x0daaa1
    call mini_fread
  incbin_until 0x0dab00
    call mini_fclose
  incbin_until 0x0dab47
    call mini_fread
  incbin_until 0x0dabe2
    call mini_fread
  incbin_until 0x0dac73
    call mini_fread
  incbin_until 0x0dac98
    fix:
  incbin_until 0x0dace3
    push strict dword fix  ; Function pointer, relocated within .xtext.
  incbin_until 0x0dacf0
    headers:
    incbin_until 0x0dacfe
    call mini_ftell
    incbin_until 0x0dad15
    call mini_fseek
    incbin_until 0x0dadca
    push dword [coff_filehdr_f_timdat]  ; The original was without `['.
    call mini_time
    pop ecx
    and dword [coff_filehdr_f_opthdr_and_f_flags], strict byte 0  ; Shorter than the original.
    nop
    assert_addr 0x0dadde
    ;jmp strict short .after_timdat
    ;xfill_until 0x0dadde, nop  ; Gap of 2+0 bytes.
    ;.after_timdat:
    incbin_until 0x0dae22
    call mini_fwrite
    incbin_until 0x0daf43
    call mini_fwrite
    incbin_until 0x0daf66
    call mini_fseek
    incbin_until 0x0daf76
  incbin_until 0x0daf83
    call mini_fopen
  incbin_until 0x0dafa9
    call mini_fread
  incbin_until 0x0dafc5
    call mini_fwrite
  incbin_until 0x0dafd8
    call mini_fclose
  incbin_until 0x0db004
    call mini_fread
  incbin_until 0x0db0a6
    call mini_fwrite
  incbin_until 0x0db1a8
    call mini_fwrite
  incbin_until 0x0db215
    call mini_fwrite
  incbin_until 0x0db22b
    outsyms:
  incbin_until 0x0db3f5
    call mini_fread
  incbin_until 0x0db40b
    call mini_fwrite
  incbin_until 0x0db488
    call mini_fread
  incbin_until 0x0db49e
    call mini_fwrite
  incbin_until 0x0db4bf
    push strict dword outsyms  ; Function pointer, relocated within .xtext.
  incbin_until 0x0db584
    call mini_calloc
  incbin_until 0x0db5ba
    call mini_ftell
  incbin_until 0x0db5e5
    call mini_fseek
  incbin_until 0x0db5f6
    call mini_fwrite
  incbin_until 0x0db618
    call mini_fseek
  incbin_until 0x0db629
    call mini_fwrite
  incbin_until 0x0db63e
    call mini_fseek
  incbin_until 0x0db6b3
    call mini_malloc
  incbin_until 0x0db7ae
    call mini_strcmp
  incbin_until 0x0db825
    call mini_fopen
  incbin_until 0x0db851
    call mini_fread
  incbin_until 0x0dba25
    call mini_fread
  incbin_until 0x0dba45
    call mini_fread
  ferror_rp3zz_between 0x0dba5b, 0x0dba64
  incbin_until 0x0dba80
    call mini_fclose
  incbin_until 0x0dbaa8
    call mini_fopen
  incbin_until 0x0dbac3
    call mini_fopen
  incbin_until 0x0dbb2f
    call mini_fread
  incbin_until 0x0dbb48
    call mini_fwrite
  incbin_until 0x0dbb8a
    call mini_ftell
  incbin_until 0x0dbb9e
    call mini_fread
  incbin_until 0x0dbd1d
    call mini_fseek
  incbin_until 0x0dbd3f
    call mini_fwrite
  incbin_until 0x0dbd6a
    call mini_strncmp
  incbin_until 0x0dbd92
    call mini_fseek
  incbin_until 0x0dbdad
    call mini_fwrite
  incbin_until 0x0dbdd9
    call mini_fwrite
  incbin_until 0x0dbdf4
    call mini_fread
  incbin_until 0x0dbe0a
    call mini_fwrite
  incbin_until 0x0dbe27
    call mini_fread
  ferror_rp3zz_between 0x0dbe3d, 0x0dbe46
  ferror_rp3zz_between 0x0dbe58, 0x0dbe61
  incbin_until 0x0dbe73
    call mini_fclose
  incbin_until 0x0dbe7c
    call mini_fclose
  incbin_until 0x0dbeb8
    call mini_fseek
  incbin_until 0x0dbed6
    call mini_fread
  incbin_until 0x0dbef9
    call mini_fseek
  incbin_until 0x0dbf17
    call mini_fwrite
  incbin_until 0x0dbf29
    call mini_fseek
  incbin_until 0x0dbf4c
    call mini_fread
  incbin_until 0x0dbf8e
    call mini_fseek
  incbin_until 0x0dbfa8
    call mini_fread
  incbin_until 0x0dbfdc
    call mini_fseek
  incbin_until 0x0dc006
    call mini_fwrite
  incbin_until 0x0dc0a6
    call mini_calloc
  incbin_until 0x0dc22f
    call mini_calloc
  incbin_until 0x0dc280
    ;unused___unused_helper10:  ; Gap replaced with minilibc686 code.

    do_dflag_not_t:
		cmp al, 'l'
		jne .not_l
		mov byte [dlflag], al  ; Any nonzero value works.
		ret
		.not_l:
		cmp al, 'v'  ; New functionality: New flag -dv: Ignore the .version directive, do not add a string to the .comment section.
		jne .not_v
		;mov byte [handle_directive_version], yyparse.case_do_not_call_comment  ; Modifying just the last byte makes this `mov' shorter. Unfortunately it doesn't work in `nasm -f elf' because NASM doesn't support 1-byte relocations.
		mov dword [handle_directive_version], yyparse.case_do_not_call_comment
		ret
		.not_v:
		cmp al, 'g'  ; New functionality: New flag -dg: Omit the "-lg" symbol, for compatibility with SVR3 assembler.
		jne .not_g
		mov byte [dgflag], al  ; Any nonzero value works.
		.not_g:
		ret
    mini_strlen:  ; size_t mini_strlen(const char *s);
		push edi
		mov edi, [esp+8]  ; Argument s.
		xor eax, eax
		or ecx, byte -1  ; ECX := -1.
		repne scasb
		sub eax, ecx
		dec eax
		dec eax
		pop edi
		ret

    mini_strncmp:  ; int mini_strncmp(const void *s1, const void *s2, size_t n);
		mov ecx, [esp+0xc]  ; n.
      .in_ecx:  ; This is the entry point to mini_strncmp from mini_strcmp, with ECX already set to -1U (maximum).
		push esi
		push edi
		mov esi, [esp+0xc]  ; s1.
		mov edi, [esp+0x10]  ; s2.
		; TODO(pts): Make the code below shorter.
		jecxz .equal
      .next:	lodsb
		scasb
		je .same_char
		sbb eax, eax
		sbb eax, byte -1  ; With the previous instruction: EAX := (CF ? -1 : 1).
		jmp short .done
      .same_char:
		test al, al
		jz .equal
		loop .next
      .equal:	xor eax, eax
      .done:	pop edi
		pop esi
		ret

    mini_strcmp:  ; int mini_strcmp(const char *s1, const char *s2);
		or ecx, strict byte -1
		jmp strict short mini_strncmp.in_ecx

    mini_prng_mix3_RP3:  ; uint32_t mini_prng_mix3_RP3(uint32_t key) __attribute__((__regparm__(3)));
      ; mini_prng_mix3 is a period 2**32-1 PNRG ([13,17,5]), to fill the seeds.
      ;
      ; https://stackoverflow.com/a/54708697 , https://stackoverflow.com/a/70960914
      ;
      ; if (!key) ++key;
      ; key ^= (key << 13);
      ; key ^= (key >> 17);
      ; key ^= (key << 5);
      ; return key;
		test eax, eax
		jnz .nz
		inc eax
      .nz:	mov edx, eax
		shl edx, 13
		xor eax, edx
		mov edx, eax
		shr edx, 17
		xor eax, edx
		mov edx, eax
		shl edx, 5
		xor eax, edx
		ret

    assert_addr 0x0dc2fb  ; No gap, it fits tightly.
  incbin_until 0x0dc31e
    call mini_strncmp
  incbin_until 0x0dc344  ; Original useful code in sunos4as-1988-11-16.svr3 until this.

    mini_strncpy:  ; char *mini_strncpy(char *dest, const char *src, size_t n);
		mov ecx, [esp+0xc]  ; Argument n.
      .in_ecx:  ; This is the entry point to mini_strncpy from mini_strcpy, with ECX already set to -1U (maximum).
		push edi  ; Save.
		mov edi, [esp+8]  ; Argument dest.
		mov edx, [esp+0xc]  ; Argument src.
		push edi
      .1:	test ecx, ecx
		jz short .2
		dec ecx
		mov al, [edx]
		stosb
		inc edx
		test al, al
		jnz short .1
		rep stosb  ; Fill the rest of dest with \0.
      .2:	pop eax  ; Result: pointer to dest.
		pop edi  ; Restore.
		ret

    mini_fclose:  ; int mini_fclose(FILE *stream);
		push esi
		push ebx
		mov ebx, [esp+0xc]
		mov al, [ebx+0x14]
		or esi, byte -0x1
		test al, al
		je .1
		dec eax
		xor esi, esi
		cmp al, 0x2
		jbe .3
		push ebx
		call mini_fflush
		xchg esi, eax  ; ESI := EAX; EAX := junk.
		pop edx
      .3:	push dword [ebx+0x10]
		call mini_close
		pop eax  ; Clean up argument of mini_close(...) from the stack.
		xor eax, eax  ; EAX := 0.
		mov [ebx+0x14], al  ; filep->dire = FD_CLOSED;
		dec eax
		mov [ebx+0x10], eax  ; filep->fd = EOF;
		mov eax, [ebx+4]
		mov [ebx], eax  ; filep->buf_write_ptr = filep->buf_end;  /* Sentinel for future calls to mini_fputc(..., filep). */
		mov eax, [ebx+0xc]
		mov [ebx+8], eax  ; filep->buf_read_ptr = filep->buf_last;  /* Sentinel for future calls to mini_fgetc(filep). */
      .1:	xchg eax, esi  ; EAX := ESI; ESI := junk.
		pop ebx
		pop esi
		ret

    mini_fwrite:  ; size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
		push ebp
		push edi
		push esi
		push ebx
		push ebx
		mov ebp, [esp+0x18]
		mov esi, [esp+0x24]
		mov edi, [esp+0x1c]
		imul edi, [esp+0x20]
		mov al, [esi+0x14]
		test edi, edi
		je near .20
		cmp al, 0x3
		jbe near .20
		mov edx, [esi+0x4]
		mov ecx, [esi+0x18]
		cmp edx, ecx
		je near .21
		cmp al, 0x6
		jne .4
		lea eax, [ebp+edi+0x0]
		mov [esp], eax
		mov edi, eax
      .5:	cmp edi, ebp
		je .6
		cmp byte [edi-0x1], 0xa
		je .6
		dec edi
		jmp short .5
      .6:	mov ebx, ebp
      .13:	mov eax, [esi+0x4]
		cmp [esi], eax
		je .8
      .12:	inc ebx
		mov ecx, [esi]
		lea eax, [ecx+0x1]
		mov [esi], eax
		mov al, [ebx-0x1]
		mov [ecx], al
		cmp ebx, edi
		jne .10
		jmp short .38
      .8:	push esi
		call mini_fflush
		pop ecx
		test eax, eax
		je .12
		jmp short .11
      .38:	push esi
		call mini_fflush
		pop edx
		test eax, eax
		jne .11
      .10:	cmp [esp], ebx
		jne .13
		jmp short .11
      .4:	mov ebx, ebp
		cmp ecx, [esi]
		jne .16
		sub edx, ecx
		cmp edx, edi
		jbe .15
		jmp short .16
      .17:	inc ebx
		lea eax, [edx+0x1]
		mov [esi], eax
		mov al, [ebx-0x1]
		mov [edx], al
		dec edi
		je .11
      .16:	mov edx, [esi]
		cmp edx, [esi+0x4]
		jne .17
      .15:	push esi
		call mini_fflush
		pop ecx
		test eax, eax
		je .18
		jmp short .11
      .21:	mov ebx, ebp
      .18:	push edi
		push ebx
		push dword [esi+0x10]
		call mini_write
		lea edx, [eax+0x1]
		add esp, byte 0xc
		cmp edx, byte 1
		jbe .11
		add ebx, eax
		add [esi+0x20], eax
		sub edi, eax
		jne .18
      .11:	mov eax, ebx
		sub eax, ebp
		xor edx, edx
		div dword [esp+0x1c]
		jmp short .1
      .20:	xor eax, eax
      .1:	pop edx
		pop ebx
		pop esi
		pop edi
		pop ebp
		ret

    mini_fseek:  ; int mini_fseek(FILE *stream, long offset, int whence);
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x10]
		mov esi, [esp+0x14]
		mov edi, [esp+0x18]
		mov al, [ebx+0x14]
		lea edx, [eax-0x1]
		cmp dl, 0x2
		ja .2
		cmp edi, byte 1
		jne .3
		mov eax, [ebx+0x8]
		sub eax, [ebx+0x18]
		add eax, [ebx+0x20]
		mov [ebx+0x20], eax
		add esi, eax
		xor edi, edi
      .3:	push ebx
		call mini___M_discard_buf
		pop ecx
		jmp short .4
      .2:	cmp al, 0x3
		ja .5
      .7:	or eax, byte -1
		jmp short .1
      .5:	push ebx
		call mini_fflush
		pop edx
		test eax, eax
		jne .7
      .4:	push edi
		push esi
		push dword [ebx+0x10]
		call mini_lseek
		add esp, byte 0xc
		cmp eax, byte -1
		je .7
		mov [ebx+0x20], eax
		xor eax, eax
      .1:	pop ebx
		pop esi
		pop edi
		ret

    mini_ftell:  ; long mini_ftell(FILE *stream);
		mov edx, [esp+0x4]
		mov cl, [edx+0x14]
		lea eax, [ecx-0x1]
		cmp al, 0x2
		ja .2
		mov eax, [edx+0x8]
		jmp short .3
      .2:	or eax, byte -1
		cmp cl, 0x3
		jbe .1
		mov eax, [edx]
      .3:	sub eax, [edx+0x18]
		add eax, [edx+0x20]
      .1:	ret

    mini_fgetc_RP3:  ; int mini_fgetc_RP3(FILE *stream) __attribute__((__regparm__(3)));
		mov edx, [eax+0x8]
		cmp edx, [eax+0xc]
		je .1
		inc dword [eax+0x8]
		movzx eax, byte [edx]
		ret
      .1:	push byte 0  ; Return string, zero-initialized.
		mov edx, esp
		push eax  ; stream.
		push byte 1
		push byte 1
		push edx  ; Address of return string.
		call mini_fread
		add esp, byte 0x10
		test eax, eax
		jz .err
		pop eax
		ret
      .err:	pop eax  ; Clean up return string.
		or eax, byte -1
		ret

    mini_ungetc:  ; int mini_ungetc(int c, FILE *stream);
                mov eax, [esp+4]  ; Argument c.
                mov edx, [esp+8]  ; Argument stream.
                ; Fall through to mini_ungetc_RP3.
    mini_ungetc_RP3:  ; int mini_ungetc_RP3(int c, FILE *stream) __attribute__((__regparm__(3)));
		test eax, eax
		js .err
		mov cl, [edx+0x14]  ; .dire.
		dec ecx  ; Shorter than `dec cl'.
		cmp cl, 2
		ja .err
		mov ecx, [edx+8]  ; .buf_read_ptr.
		cmp [edx+0x18], ecx  ; .buf_start.
		je .err
		dec ecx
		mov [edx+0x8], ecx  ; .buf_read_ptr.
		mov [ecx], al
		jmp short .ret
      .err:	or eax, byte -1  ; Indicate error.
      .ret:	ret

    mini_fopen:  ; FILE *mini_fopen(const char *pathname, const char *mode);
		push edi
		push esi
		push ebx
		mov edi, mini___M_global_file_bufs
		mov esi, mini___M_global_files
      .next:	cmp esi, mini___M_global_files.end
		je strict near mini___M_jmp_freopen_low.error  ; TODO(pts): With smart linking, make this a short jump.
		cmp byte [esi+0x14], 0x0  ; FD_CLOSED.
		je .found
		add esi, byte 0x24  ; sizeof(struct _SMS_FILE).
		add edi, strict dword BUF_SIZE
		jmp short .next
      .found:	mov [esi+0x18], edi  ; .buf_start := EDI.
		add edi, strict dword BUF_SIZE  ; EDI := .buf_start + BUF_SIZE.
		mov [esi+0x4], edi  ; .buf_end := .buf_start + BUF_SIZE;
		mov [esi+0x1c], edi  ; .buf_capacity_end := .buf_start + BUF_SIZE;
		; Fall through to mini___M_jmp_freopen_low.
    mini___M_jmp_freopen_low:
      ; Input: EAX == junk, EBX == junk, ECX == junk, EDX == junk, ESI == FILE* pointer (.start, .end, .capacity_end already initialized), EDI == junk, EBP == anything.
      ; Input stack: [esp] == saved EBX, [esp+1*4]: saved ESI, [esp+2*4]: saved EDI, [esp+3*4]: return address, [esp+4*4]: argument pathname, [esp+5*5]: argument mode.
      ; Output: EAX == result FILE* pointer (or NULL), EBX == restored, ECX == junk, EDX == junk, ESI == restored, EDI == restored, EBP == unchanged.
      ; Output stack: poped up to and including the return address.
		mov edx, [esp+5*4]  ; Argument mode.
		mov dl, [edx]
		cmp dl, 'w'
		sete bl  ; is_write?
		xor eax, eax  ; EAX := O_RDONLY.
		cmp dl, 'a'
		sete cl
		or bl, cl
		je .have_flags
		cmp dl, 'a'
		; We may add O_LARGEFILE for opening files >= 2 GiB, but in a different stdio implementation. Without O_LARGEFILE, open(2) fails with EOVERFLOW.
		mov eax, 3101o  ; EAX := O_TRUNC | O_CREAT | O_WRONLY | O_APPEND.
		je .have_flags
		and ah, ~4  ; ~(O_APPEND>>8). EAX := O_TRUNC | O_CREAT | O_WRONLY.
      .have_flags:  ; File open flags is now in EAX.
		push dword 666o
		push eax  ; File open flags.
		push dword [esp+6*4]  ; Argument pathname.
		call mini_open
		add esp, byte 0xc  ; Clean up arguments of mini_open(...) from the stack.
		test eax, eax
		jns .open_ok
      .error:	xor eax, eax  ; EAX := NULL (return value, indicating error).
		jmp short .done
      .open_ok:	cmp bl, 0x1
		sbb edx, edx
		and dl, -0x3
		add dl, 0x4
		mov [esi+0x10], eax
		mov [esi+0x14], dl
		xor eax, eax
		mov dword [esi+0x20], eax  ; .buf_off := 0.
		push esi
		call mini___M_discard_buf
		pop eax  ; Clean up argument of mini___M_discard_buf from the stack.
		xchg eax, esi  ; EAX := ESI (return value); ESI := junk.
      .done:	pop ebx
		pop esi
		pop edi
		ret

    xfill_until s.xtext.vstart+s.xtext.fsize

section .xdata
  assert_addr 0x111bb  ; Gap between 0x11000 and 0x111b7.
  assert_addr 0x110ad+0x108+6
  str_tmp:	db '/tmp', 0  ; P_tmpdir, Linux-specific.
  str_tmpdir:	db 'TMPDIR', 0
  assert_addr 0x110bf+0x108
  nan_inf_str: db 5, 'nan', 0, 10, 'infinity', 0, 5, 'inf', 0, 0  ; For mini_strtod(...).
  assert_addr 0x110d4+0x108
  mini_stderr_struct:  ; Layout must match `struct _SMS_FILE' in stdio_medium_*.nasm and c_stdio_medium.c.
  _iob_stderr:
	.buf_write_ptr	dd stderr_buf
	.buf_end	dd stderr_buf  ; Since buf_end == buf_write_str, stderr is unbuffered (i.e. autoflushed).
	.buf_read_ptr	dd stderr_buf
	.buf_last	dd stderr_buf
	.fd		dd 2  ; STDERR_FILENO.
	.dire		db 4  ; FD_WRITE.
	.padding	db 0, 0, 0
	.buf_start	dd stderr_buf
	.buf_capacity_end dd stderr_buf.end
	.buf_off	dd 0
  assert_addr 0x11200  ; Original .xdata starts here.
  r 0x11210+2, 0x11210+2
  incbin_until 0x1128f  ; Gap of 5 bytes. Previously it was "/tmp".
    fill_until 0x11294
  incbin_until 0x15264  ; Gap of 8 bytes.
    unused_as_version:
    fill_until 0x1526c
  incbin_until 0x177f8  ; Gap of 0x24 bytes. Previously it was "(#)" and yydebug.
    fill_until 0x1781c
  r 0x17828+2, 0x17dcc+2
  incbin_until 0x17dd0
    handle_directive_ident: dd yyparse.case_call_comment  ; Original.
    handle_directive_version: dd yyparse.case_call_comment  ; Original. Specifying -dw will change it to yyparse.do_not_call_comment.
  r 0x17dd8+2, 0x17e58+2
  incbin_until 0x17f2c  ; Gap of 0x14 bytes. Previously it was an yydebug message.
    fill_until 0x17f40
  incbin_until 0x17F61  ; Gap of 0x57 bytes. Previously it was 3 yydebug messages.
    fill_until 0x17fb8
  r 0x18a1c+2, 0x18a2c+2
  r 0x18a34+2, 0x18acc+2
  r 0x18cf8+2, 0x18d0c+2
  incbin_until 0x18d18
    fill_until 0x18d1c  ; Gap of 4 bytes. Previously it was the "%le" sscanf(3) format string.
  incbin_until 0x1902f
    fill_until 0x19033  ; Gap of 4 bytes. Previously it was "-lg", but we have another copy at aLg_0.
  r 0x1920c+2, 0x19214+2
  incbin_until 0x1921c
    coff_filehdr_f_timdat: dd coff_filehdr_f_timdat  ; NULL here means write 0 as the timestamp, for reproducible builds.
    coff_filehdr_f_opthdr_and_f_flags equ coff_filehdr_f_timdat+3*4
  r 0x193d0+2, 0x19404+2
  incbin_until 0x1942e  ; Truncated end of .xdata in sunos4as-1988-11-16.svr3.

section .xbss
  STRUCT_FILE_COUNT equ 17  ; 17 files opened by fopen(...) are enough, including the temporary files.
  assert_addr 0x1942e  ; First half of libc .xbss.
    resb 1  ; Terminating NUL for the '.ef' string at the end of original .xdata.
    passnbr_minus_1: resb 1  ; Gap of 1 byte. sAlign to multiple of 4.
    mini___M_global_files: resb STRUCT_FILE_COUNT*0x24  ; 0x24 is sizeof(struct SMS_FILE).
    .end:
    stderr_buf: resb 0x400  ; Match glibc 2.19 stderr buffer size on a TTY.
    .end:
    _malloc_simple_base: resd 1  ; char *base;
    _malloc_simple_free: resd 1  ; char *free;
    _malloc_simple_end: resd 1  ; char *end;
    mini_realloc_free_bucket_heads: resd 0x20-2
    resb 0x570-0x264  ; Gap. There is room for more zero-initialized variables here.
  fill_until 0x19e24  ; Start of original .bss in sunos4as-1988-11-16.svr3, used by the program.
    mini_environ: resd 1
    assert_addr 0x19e28
    picflag: resd 1
    assert_addr 0x19e2c
  fill_until 0xaeb5a
    dgflag: resb 1  ; In the original, this is unused_byte1.
    dlflag: resb 1  ; In the original, this is unused_byte2.
    assert_addr 0xaeb5c
  fill_until 0xb2ca0  ; End of original .bss in sunos4as-1988-11-16.svr3, used by the program.
  assert_addr 0xb2ca0  ; Rest of libc .xbss.
    BUF_SIZE equ 0x1000  ; Buffer size of each FILE* opened by mini_fopen(...).
    mini___M_global_file_bufs: resb STRUCT_FILE_COUNT*BUF_SIZE
    assert_addr 0xc3ca0

end
