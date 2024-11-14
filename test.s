/ https://forum.vcfed.org/index.php?threads/history-behind-the-disk-images-of-at-t-unix-system-v-release-4-version-2-1-for-386.68796/
/
/ Since there is "as" and "ld", it is possible to build "helloworld" in pure AT&T i386 assembler using direct call to kerlel in "i386 SYSV ABI" style.
/
/ $ as test.s
/ $ ld -s -e entry -o test test.o
/ $ ./test
/ Hello, world!

	.file	"test.s"
	.version	"02.01"  / At most "02.01".
	.set	WRITE,4
	.set	EXIT,1
	.text
	.align	4
	.globl	entry
entry:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$8,%esp

	pushl	$14		/length
	pushl	$hello
	pushl	$1		/STDOUT
	pushl	$0
	movl	$WRITE,%eax
	lcall	$0x07,$0
	addl	$16,%esp

	pushl	$0
	movl	$EXIT,%eax
	lcall	$0x07,$0

	.data
	.align	4
hello:
	.byte	0x48,0x65,0x6c,0x6c,0x6f,0x2c, 0x20,0x77,0x6f,0x72
	.byte	0x6c,0x64,0x21,0x0a,0x00
hello_end:
	.align 4
	.byte 0x40, 0x40, 0x40, 0x40
	/.bcd 1
	/.bcd 12
	/.bcd 123
	/.bcd 1234
	/.bcd 12345
	/.bcd 123456
	/.bcd 1234567
	/ `.bcd ...' zero-extends `...' on the left to 20 decimal digits `.bcd ABCDEFGHIJKLMNOPQRST', then it emits 10 bytes like `.byte 0xRQ, 0xTS, 0xNM, 0xPO, 0xJI, 0xLK, 0xFE, 0xHG, 0xBA, 0xDC'.
	.bcd 12345678906543210987  // .byte 0x90, 0x78, 0x34, 0x12, 0x09, 0x56, 0x65, 0x87, 0x21, 0x43
	.value 0xabcd  // 2 bytes, little-endian, GNU as(1) also supports .short as a synonym of .value: .short 0xabcd
	/.llong 0xdcba9876  / .llong adds 8 bytes of uninitialized data and displays a warning. It's pretty useless. Other assemblers emit an 8-byte integer (qword) here.
	/.temp -1234.75  / .temp adds 10 bytes of uninintialized data (instead of long double) and displays a warning.
	.long 0x56789abc  // .long 0x56789bc
	.float -1234.75  // .long 0xc49a5800
	.double -1234.75  // .long 0, 0xc0934b00
	.value <l>-1234.75  // .short 0x5800  // Low word.
	.value <h>-1234.75  // .short 0xc49a  // High word.
	.byte 0x41, 0x41, 0x41, 0x41
	.float -0.0  // .long 0x80000000
	.byte 0x42, 0x42, 0x42, 0x42
	/.float +0.0  // Syntax error.
	.float 0.0  // .long 0
	.byte 0x43, 0x43, 0x43, 0x43
	.double -0.0  // .long 0, 0x80000000
	.byte 0x44, 0x44, 0x44, 0x44  / Character literals like 'D in GNU as(1) aren't supported.
	/.double +0.0  / Syntax error.
	.double 0.0  // .long 0, 0
	.byte 0x45, 0x45, 0x45, 0x45
	.long  hello_end - hello  / .long 0xf
	.value hello_end - hello  / .value 0xf
	.byte  hello_end - hello  / .byte 0xf

/ Workaround to avoid the `<3>mm->brk does not lie within mmap' warning in
/ ibcs-us 4.1.6. If we add 4 nops to .text, then 0xf11 is enough. If we add
/ 8 nops in total, then 0xf0d is enough.
.bss
. = . + 0xf17
