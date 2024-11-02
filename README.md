# pts-svr3as-linux: binary port of SVR3 (SysV Release 3) assembler and linker to Linux

pts-svr3as-linux contains binary ports of multiple versions of the SVR3
(SysV Release 3, AT&T Unix System V Release 3) assembler and linker to
Linux. The resulting ELF-32 program files run on Linux i386 and Linux amd64
without emulation, and generate SVR3 COFF i386 object and executable files.
The pts-svr3as-linux repository doesn't contain any (copyrighted) code from
AT&T: you have to provide the SVR3 i386 executable program files, and
pts-svr3as-linux converts them to Linux i386 executables.

Patches are provided for the following versions:

* 1987-10-28: assembler ported, linker not
* 1988-05-27: assembler ported, linker not
* 1989-10-03: assembler ported, linker not

## Building it

Step-by-step instructions:

0. You need a Linux i386 or Linux amd64 system for building the programs.
   (Docker containers on macOS, WSL1 and WSL2 on Windows are also fine.) The
   Linux distribution and the libc don't matter, everything is
   self-contained (and statically linked) in pts-svr3as-linux.

1. Check out the pts-svr3as-linux Git repository.

2. Obtain some of the the original assembler and linker binaries, and save
   them under the following names within the pts-svr3as-linux working tree
   directory (e.g. same directory as the `compile.sh` and
   `binpatch.inc.nasm` files):

   * `svr3as-1987-10-28.svr3`, `svr3ld-1987-10-28.svr3`
   * `svr3as-1988-05-27.svr3`, `svr3ld-1988-05-27.svr3`
   * `svr3as-1989-10-03.svr3`, `svr3ld-1989-10-03.svr3`

   The *import.sh* script can help extracting these files from archives,
   disk images etc. For example, you can create the files
   `svr3as-1988-05-27.svr3` and `svr3ld-1988-05-27.svr3` like this:

   ```
   $ git clone https://github.com/pts/pts-svr3as-linux
   $ cd pts-svr3as-linux
   $ wget -O SYSV_386_3.2_SDS_4.1.5.zip http://.../SYSV_386_3.2_SDS_4.1.5.zip
   $ ./import.sh SYSV_386_3.2_SDS_4.1.5.zip
   ```

3. Run `./compile.sh`. This builds the following files, provided that the
   `*.svr3` input files above have been obtained:

   * `svr3as-1987-10-28`
   * `svr3as-1988-05-27`
   * `svr3as-1989-10-03`

## Using it

You can run the original `*.svr3` program files in emulation with
[ibcs-us](https://ibcs-us.sourceforge.io/) (many Linux distributions have it
available as a package). For example, here is how to compile and run the
hello-world test program *test.s* (part of pts-svr3as-linux):

```
$ ibcs-us ./svr3as-1988-05-27.svr3 test.s
$ ibcs-us ./svr3ld-1988-05-27.svr3 -s -e entry -o test test.o
$ ibcs-us ./test
<3>mm->brk does not lie within mmapHello, world!
```

TODO(pts): Fix the *<3>mm->brk does not lie within mmap* error.

Alternatively, you can run the assembler natively (no ibcs-us emulation
needed) after building pts-svr3as-linux:

```
$ ./svr3as-1988-05-27 test.s
$ ibcs-us ./svr3ld-1988-05-27.svr3 -s -e entry -o test test.o
$ ibcs-us ./test
<3>mm->brk does not lie within mmapHello, world!
```

Please note that the assembler creates and then removes up to 15 temporary
files in `/tmp` (or wherever your `$TMPDIR` points to).

Please note that in the Linux i386 port the `as -m` command-line flag
(enabling source preprocessing with
[m4](https://en.wikipedia.org/wiki/M4_\(computer_language\))) is disabled,
because the necessary *cm4defs* and *cm4tvdefs* files are not available on
Linux in the directories the assembler is looking at, and not all Linux
systems have *m4* installed.

## Features

All 3 assembler versions have the following features:

* COFF i386 object file output format.
* No 486, Pentium etc. instructions or features, only 386.
* Instructions: aaa, aad, aam, aas, adc, adcb, adcl, adcw, add, addb, addl, addr16, addw, and, andb, andl, andw, bound, boundl, boundw, bsfl, bsfw, bsrl, bsrw, btcl, btcw, btl, btrl, btrw, btsl, btsw, btw, call, cbtw, clc, cld, cli, clr, clrb, clrl, clrw, cltd, cmc, cmp, cmpb, cmpl, cmps, cmpsb, cmpsl, cmpsw, cmpw, cwtd, cwtl, daa, das, data16, dec, decb, decl, decw, div, divb, divl, divw, enter, esc, hlt, idiv, idivb, idivl, idivw, imul, imulb, imull, imulw, in, inb, inc, incb, incl, incw, inl, ins, insb, insl, insw, int, into, inw, iret, ja, jae, jb, jbe, jc, jcxz, je, jg, jge, jl, jle, jmp, jna, jnae, jnb, jnbe, jnc, jne, jng, jnge, jnl, jnle, jno, jnp, jns, jnz, jo, jp, jpe, jpo, js, jz, lahf, lcall, lds, ldsl, ldsw, lea, leal, leave, leaw, les, lesl, lesw, lfs, lfsl, lfsw, lgs, lgsl, lgsw, ljmp, lock, lods, lodsb, lodsl, lodsw, loop, loope, loopne, loopnz, loopz, lret, lss, lssl, lssw, mov, movb, movl, movs, movsb, movsbl, movsbw, movsl, movsw, movswl, movw, movzbl, movzbw, movzwl, mul, mulb, mull, mulw, neg, negb, negl, negw, nop, not, notb, notl, notw, or, orb, orl, orw, out, outb, outl, outs, outsb, outsl, outsw, outw, pop, popa, popal, popaw, popf, popfl, popfw, popl, popw, push, pusha, pushal, pushaw, pushf, pushfl, pushfw, pushl, pushw, rcl, rclb, rcll, rclw, rcr, rcrb, rcrl, rcrw, rep, repnz, repz, ret, rol, rolb, roll, rolw, ror, rorb, rorl, rorw, sahf, sal, salb, sall, salw, sar, sarb, sarl, sarw, sbb, sbbb, sbbl, sbbw, scab, scal, scas, scasb, scasl, scasw, scaw, scmp, scmpb, scmpl, scmpw, seta, setae, setb, setbe, setc, sete, setg, setge, setl, setle, setna, setnae, setnb, setnbe, setnc, setne, setng, setnge, setnl, setnle, setno, setnp, setns, setnz, seto, setp, setpe, setpo, sets, setz, shl, shlb, shldl, shldw, shll, shlw, shr, shrb, shrdl, shrdw, shrl, shrw, slod, slodb, slodl, slodw, smov, smovb, smovl, smovw, ssca, sscab, sscal, sscaw, ssto, sstob, sstol, sstow, stc, std, sti, stos, stosb, stosl, stosw, sub, subb, subl, subw, test, testb, testl, testw, wait, xchg, xchgb, xchgl, xchgw, xlat, xor, xorb, xorl, xorw.
* Protected mode instructions: arpl, clts, lar, lgdt, lidt, lldt, lmsw, lsl, ltr, sgdt, sidt, sldt, smsw, str, verr, verw.
* Floating-point (FPU, floating point, x87, 8087, 80387) instructions: f2xm1, fabs, fadd, faddl, faddp, fadds, fbld, fbstp, fchs, fclex, fcom, fcoml, fcomp, fcompl, fcompp, fcomps, fcoms, fcos, fdecstp, fdiv, fdivl, fdivp, fdivr, fdivrl, fdivrp, fdivrs, fdivs, ffree, fiadd, fiaddl, ficom, ficoml, ficomp, ficompl, fidiv, fidivl, fidivr, fidivrl, fild, fildl, fildll, fimul, fimull, fincstp, finit, fist, fistl, fistp, fistpl, fistpll, fisub, fisubl, fisubr, fisubrl, fld, fld1, fldcw, fldenv, fldl, fldl2e, fldl2t, fldlg2, fldln2, fldpi, flds, fldt, fldz, fmul, fmull, fmulp, fmuls, fnclex, fninit, fnop, fnsave, fnstcw, fnstenv, fnstsw, fpatan, fprem, fprem1, fptan, frndint, frstor, fsave, fscale, fsetpm, fsin, fsincos, fsqrt, fst, fstcw, fstenv, fstl, fstp, fstpl, fstps, fstpt, fsts, fstsw, fsub, fsubl, fsubp, fsubr, fsubrl, fsubrp, fsubrs, fsubs, ftst, fucom, fucomp, fucompp, fwait, fxam, fxch, fxtract, fyl2x, fyl2xp1.
* Control registers: %cr0, %cr2, %cr3.
* Debug registers: %db0, %db1, %db2, %db3, %db6, %db7, %dr0, %dr1, %dr2, %dr3, %dr6, %dr7, %tr6, %tr7.
* General-purpose registers, 32-bit: %eax, %ecx, %edx, %ebx, %esp, %ebp, %esi, %edi.
* General-purpose registers, 16-bit: %ax, %cx, %dx, %bx, %sp, %bp, %si, %di.
* General-purpose registers, 8-bit: %al, %cl, %dl, %bl, %ah, %ch, %dh, %bh.
* Segment registers: %es, %cs, %ss, %ds, %fs, %gs.
* Floating-point (FPU, floating point, x87, 8087, 80387) registers: %st, %st(0), %st(1), %st(2), %st(3), %st(4), %st(5), %st(6), %st(7).
* Assembler directives: .align, .bcd, .bss, .byte, .comm, .data, .def, .dim, .double, .endef, .even, .file, .float, .globl, .ident, .jmpbeg, .jmpend, .lcomm, .line, .llong, .ln, .long, .scl, .section, .set, .size, .string, .tag, .temp, .text, .tv, .type, .val, .value, .version.

The *instab* table values are the same in all 3 assemblers, execept that
`svr3as-1989-10-03` has different opcode values for `nop`. (This may be just
an implementation detail.)

The SunOS 4.0.1 i386 assembler has many changes and some addition to the
*instab* table.

## Why is the SVR3 assembler significant?

AT&T Unix System V Release 3 (SVR3, released in 1987), was the first popular
Unix operating system for the 32-bit i386 architecture (starting with the
Intel 80386 CPU). (386/ix was earler port of Unix to i386, released [in
1985](https://de.wikipedia.org/wiki/Interactive_Unix).) The
infamous AT&T assembly syntax comes from the i386 assembler in SVR3: e.g.
`lea ecx, [eax+ebx*4+5]` is in Intel syntax, and `lea 5(%eax,%ebx,4), %ecx`
is the corresponding AT&T syntax. Actually, it comes from [PDP-11 assembly
syntax](https://en.wikipedia.org/wiki/PDP-11_architecture#Example_code):
`MOV 6(SP), R0` in PDP-11 syntax is similar to `mov 6(%esp), %eax` in AT&T
i386 syntax.

Also, the i386 assembler in SVR3, released in 1987 (e.g. program file
`svr3as-1987-10-28.svr3` in pts-svr3as-linux), is one of the earliest known
assemblers targeting i386. Microsoft Macro Assembler (MASM) 5.00 (released
on 1987-07-31) is the other one. Borland Turbo Assembler (TASM) followed
suit a few years later: 1.0 was released on 1988-08-29, 1.01 (with fixes of
show-stopper bugs in 1.0) was released on 1989-05-02.

Assemblers using the AT&T i386 syntax:

* the SVR3 assembler (earliest remaining file date 1987-10-28)
* the SVR4 assembler (earliest remaining file date 1990-04-19)
* GNU Assembler (released for i386 in about 1990), now part of GNU Binutils,
  still in active development in 2024
* the assembler in Sun Solaris is based on the SVR4 assembler, later
  versions used the GNU Assembler
* the Mark Williams 80386 assembler (earliest remaining file date
  1992-09-11, part of Coherent 4.x)
* [vasm](http://sun.hasenbraten.de/vasm/) by Volker Barthelmann,
  still in active development in 2024
