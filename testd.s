/
/ testd.s: DJGPP (GNU Binutils) assembler test program corresponding to test.s
/ by pts@fazekas.hu at Fri Nov 15 04:00:30 CET 2024
/
/ Based on SVR3 hello-world program assembly source code on
/ https://forum.vcfed.org/index.php?threads/history-behind-the-disk-images-of-at-t-unix-system-v-release-4-version-2-1-for-386.68796/
/
/ Here is how to compile (with the DJGPP assembler) and run (using ibcs-us)
/ an a modern Linux i386 or amd64 system:
/
/   $ ./i586-pc-msdosdjgpp-as-2.24 --32 -march=i386+387 -o testd.o testd.s
/   $ ibcs-us ./svr3ld-1988-05-27.svr3 -s -o testd testd.o
/   $ ibcs-us ./testd
/   Hello, World!
/
/ TODO(pts): Why does `ibcs-us ./svr3as-1987-10-28.svr3 test.s' segfault on
/ Linux i386, while the Linux port works? Is the filename of the assembler
/ too long? How did old versions work?
/

.file "test.s"
.version "02.01"  / At most "02.01" works with SVR3 assemblers.
.set WRITE, 4
.set EXIT, 1
.text
.align 4

.globl _start
_start:	pushl %ebp
	movl %esp, %ebp
	subl $8, %esp

	call print_msg
	call exit
	/ Not reached.

print_msg:
	pushl $14  # length.  (Mid-line comments must start with `#' in the DJGPP assembler.)
	pushl $hello  # This is different from SVR3 assemblers: before relocation, the number 4 (offset-within-.data) is stored for DJGPP, and .data+4 is stored for SVR3.
	pushl $1  # STDOUT
	pushl $0
	movl $WRITE, %eax
	lcall $0x07, $0  # i386 SYSV ABI syscall.
	addl $16, %esp
	ret

exit:	pushl $0
	movl $EXIT, %eax
	lcall $0x07, $0  # i386 SYSV ABI syscall.
	ret

	call hello  # Doesn't make sense. Not reached.

	.data
	.align 4
	.long 42
hello:
	.string "Hello, World!\n"  # Automatically NUL-terminated.
hello_end:

	.align 4
	.byte 0x40, 0x40, 0x40, 0x40
	/ `.bcd ...' zero-extends `...' on the left to 20 decimal digits `.bcd ABCDEFGHIJKLMNOPQRST', then it emits 10 bytes like `.byte 0xRQ, 0xTS, 0xNM, 0xPO, 0xJI, 0xLK, 0xFE, 0xHG, 0xBA, 0xDC'.
	/.bcd 12345678906543210987   ## .bcd not supported by the DJGPP assembler. ## .byte 0x90, 0x78, 0x34, 0x12, 0x09, 0x56, 0x65, 0x87, 0x21, 0x43
	.byte 0x90, 0x78, 0x34, 0x12, 0x09, 0x56, 0x65, 0x87, 0x21, 0x43
	.value 0xabcd  ## 2 bytes, little-endian, GNU as(1) also supports .short as a synonym of .value: .short 0xabcd
	/.llong 0xdcba9876  # .llong adds 8 bytes of uninitialized data and displays a warning. It's pretty useless. Other assemblers emit an 8-byte integer (qword) here.
	/.temp -1234.75  # .temp adds 10 bytes of uninintialized data (instead of long double) and displays a warning.
	.long 0x56789abc  ## .long 0x56789bc
	.float -1234.75  ## .long 0xc49a5800
	.double -1234.75  ## .long 0, 0xc0934b00
	/.value <l>-1234.75  ## <l> not supported by the DJGPP assembler.  ## .short 0x5800  ## Low word.
	.value 0x5800
	/.value <h>-1234.75  ## <h> not supported by the DJGPP assembler.  ## .short 0xc49a  ## High word.
	.value 0xc49a
	.byte 0x41, 0x41, 0x41, 0x41
	.float -0.0  ## .long 0x80000000
	.byte 0x42, 0x42, 0x42, 0x42
	/.float +0.0  ## Syntax error.
	.float 0.0  ## .long 0
	.byte 0x43, 0x43, 0x43, 0x43
	.double -0.0  ## .long 0, 0x80000000
	.byte 0x44, 0x44, 0x44, 0x44  # Character literals like 'D in GNU as(1) aren't supported.
	/.double +0.0  # Syntax error.
	.double 0.0  ## .long 0, 0
	.byte 0x45, 0x45, 0x45, 0x45
	.long  hello_end - hello  # .long 0xf
	.value hello_end - hello  # .value 0xf
	.byte  hello_end - hello  # .byte 0xf

/ Workaround to avoid the `<3>mm->brk does not lie within mmap' warning in
/ ibcs-us 4.1.6. If we add 4 nops to .text, then 0xf11 is enough. If we add
/ 8 nops in total, then 0xf0d is enough.
.bss
. = . + 0xf17
