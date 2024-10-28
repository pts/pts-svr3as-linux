;
; svr3as-1988-05-27.nasm: a Linux i386 port of the SVR3 3.2 SDS 4.1.5 1988-05-27 i386 assembler as(1)
; by pts@fazekas.hu at Tue Oct 22 21:02:06 CEST 2024
;
; Compile with: nasm -w+orphan-labels -f bin -O0 -o svr3as-1988-05-27 svr3as-1988-05-27.nasm && chmod +x svr3as-1988-05-27
; Run on Linux (creating test.o of COFF format): ./svr3as-1988-05-27.nasm: test.s && cmp -l test.o.good test.o
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

%include 'binpatch.inc.nasm'

; `objdump -x' output (Size mostly incorrect):
; Idx Name          Size      VMA       File off  Algn
;   0 .text         0x0100a0  0x0000d0  0x0000d0  2**2  CONTENTS, ALLOC, LOAD, READONLY, CODE, NOREAD
;   1 .data         0x00b5d4  0x400170  0x010170  2**2  CONTENTS, ALLOC, LOAD, READONLY, DATA, NOREAD
;   2 .bss          0x40b744  0x40b744  0x000000  2**2  ALLOC, READONLY, NOREAD
;   3 .comment      0x000030  0x000000  0x01b744  2**2  CONTENTS, READONLY, DEBUGGING, NOREAD

define.xbin 'svr3as-1988-05-27.svr3'
define.xtext 0x0100fc, 0x3e0074, 0x000074
define.xdata 0x00b5d4, 0x400170, 0x010170, 0x00b5d4+0x11080
opt.o0  ; Make NASM compilation faster. For this file the output is the same.

%define SRC_1988
%include 'svr3as-1989-10-03.nasm'
