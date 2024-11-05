/ https://forum.vcfed.org/index.php?threads/history-behind-the-disk-images-of-at-t-unix-system-v-release-4-version-2-1-for-386.68796/
/
/ Since there is "as" and "ld", it is possible to build "helloworld" in pure AT&T i386 assembler using direct call to kerlel in "i386 SYSV ABI" style.
/
/ $ as test.s
/ $ ld -s -e entry -o test test.o
/ $ ./test
/ Hello, world!

	.file	"test.s"
	.version	"02.01"
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

/ Workaround to avoid the `<3>mm->brk does not lie within mmap' warning in
/ ibcs-us 4.1.6. If we add 4 nops to .text, then 0xf11 is enough. If we add
/ 8 nops in total, then 0xf0d is enough.
.bss
. = . + 0xf17
