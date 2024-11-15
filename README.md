# pts-svr3as-linux: binary port of SVR3 (SysV Release 3) and SunOS 4 assembler and linker to Linux

pts-svr3as-linux contains binary ports of multiple versions of the SVR3
(SysV Release 3, AT&T Unix System V Release 3) and SunOS (4.0.1 and 4.0.2)
assemblers and linkers to Linux. The resulting ELF-32 program files run on
Linux i386 and Linux amd64 without emulation, and generate SVR3 COFF i386
object and executable files. The pts-svr3as-linux repository doesn't contain
any (copyrighted) code from AT&T: you have to provide the SVR3 i386
executable program files, and pts-svr3as-linux converts them to Linux i386
executables.

Patches are provided for the following versions:

* SVR3 1987-10-28: assembler ported, linker not ported
* SVR3 1988-05-27: assembler ported, linker not ported
* SVR3 1989-10-03: assembler ported, linker not ported
* SunOS 4.0.1 1988-11-16: assembler ported, linker not ported
* SunOS 4.0.2 1989-07-17: assembler same as in SunOS 4.0.1, linker not ported

## Building it

Step-by-step instructions:

0. You need a Linux i386 or Linux amd64 system for building the programs.
   (Docker containers on macOS, WSL1 and WSL2 on Windows are also fine.) The
   Linux distribution and the libc don't matter, everything is
   self-contained (and statically linked) in pts-svr3as-linux.

1. Check out the [pts-svr3as-linux](https://github.com/pts/pts-svr3as-linux)
   Git repository.

2. Obtain some of the the original assembler and linker binaries, and save
   them under the following names within the pts-svr3as-linux working tree
   directory (e.g. same directory as the `compile.sh` and
   `binpatch.inc.nasm` files):

   * `svr3as-1987-10-28.svr3`, `svr3ld-1987-10-28.svr3`
   * `svr3as-1988-05-27.svr3`, `svr3ld-1988-05-27.svr3`
   * `svr3as-1989-10-03.svr3`, `svr3ld-1989-10-03.svr3`
   * `sunos4as-1988-11-16.svr3`, `sunos4ld-1988-11-16.svr3`
   * `sunos4ld-1989-07-17.svr3`

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
   * `sunos4as-1988-11-16`

## Using it

You can run the original `svr3*.svr3` (but not `sunos4*.svr3`) program files
in emulation with [ibcs-us](https://ibcs-us.sourceforge.io/) (many Linux
distributions have it available as a package). For example, here is how to
compile and run the hello-world test program *test.s* (part of
pts-svr3as-linux):

```
$ chmod +x ./svr3as-1988-05-27.svr3 ./svr3ld-1988-05-27.svr3
$ ibcs-us ./svr3as-1988-05-27.svr3 test.s
$ ibcs-us ./svr3ld-1988-05-27.svr3 -s -e entry -o test test.o
$ ibcs-us ./test
Hello, world!
```

Alternatively, you can run the assembler natively (no ibcs-us emulation
needed) after building pts-svr3as-linux:

```
$ chmod +x ./svr3as-1988-05-27.svr3 ./svr3ld-1988-05-27.svr3
$ ./svr3as-1988-05-27 test.s
$ ibcs-us ./svr3ld-1988-05-27.svr3 -s -e entry -o test test.o
$ ibcs-us ./test
Hello, world!
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

The SVR3 assemblers (`svr3as-*`) have the following features:

* [COFF i386](https://wiki.osdev.org/COFF) object file output format. These are more similar to the DJGPP variant rather than the Win32 variant, so modern tools such as GNU ld(1) and OpenWatcom wlink(1) don't work with them until the object file is converted. (pts-svr3as-linux doesn't provide such a converter.)
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
* Conditional assembly (e.g. .if, .ifdef, .else, .endif) is not supported.

The *instab* table values are the same in all 3 assemblers, execept that
`svr3as-1989-10-03` has different opcode values for `nop`. (This may be just
an implementation detail.)

Additions by the Linux i386 ports:

* The `-dt` command-line flag to force the timestamp in the COFF output file
  to 0, for reproducible builds.
* The `-dg` command-line flag to omit the `-lg` symbol from the COFF output
  file. This makes the output of the SunOS assembler more similar to the
  SVR3 assemblers.
* The `-dv` command-line flag make the `.version` directive not append the
  string to the .comment section. This makes the output of the SunOS
  assembler more similar to the SVR3 assemblers.

The SunOS 4.0.1 i386 assembler (`sunos4as-*`) seems to be based on SVR3
1987-10-28 or later (up to 1987-12-15), and it has the following changes:

* No additions or removals in instructions or registers.
* New assembler directives:  .noopt, .optim, .stabd, .stabn, .stabs.
* `.version "X"` adds `X` to the `.comment` section, like `.ident "X"`, and
  doesn't compare `X` to the minimum assembler version `02.01`.
* Support for preprocessing with m4 (enable it with the `-m` command-line
  flag, configure it with `-Y`) has been removed.
* Adds an absolute symbol named `-lg` unconditionally.
* Added the `-i386` command-line flag, ignored.
* Added the `-k` flag for generation of position-independent code.
* Changed the meaning of the `-R` flag: in SVR3 it causes the input .s file
  to be deleted (removed) on success, in SunOS it makes the .data section
  read-only and merges it into .text.
* Adds the *localopt* variable (used in *loopgen()* in addition to the *opt*
  variable). This affects code generation somehow.
* Uses a fixed symbol table (of 21011 elements), it isn't able to grow.
  (This is a stepback.)
* The program is dynamically linked against SunOS libc.so (rather than
  statically linked). It's still statically linked against SuonOS libm.a.
* SunOS libm.a is different from SVR4 libm.a implementation, probably
  because SunOS 4 is based on 4.3BSD.
* Implementation detail: the 2nd boll argument of *lookup()* is inverted.
* There is no *hash(...)* function, it's inlined to *lookup()*.
* The entire tables (*symtab* and *hashtab*) are preallocated, it's not many
  smaller dynamic allocations anymore.
* It has version info *SunOS 4.0/RoadRunner BETA1 -- 12/15/87*.
* The original build process: the source code of the SVR3 assembler has been
  used as a base, changed (see some of the changes above), compiled with a
  different C compiler, linked statically against SunOS 4.0 libm (based on
  4.3BSD, not SVR3), linked dynamically against SunOS 4.0 libc (based on
  4.3BSD, not SVR3).
* Oddly enough, SunOS 4.0.1 (and 4.3BSD) libc *stdio.h* defines *P_tmpdir* to
  `"/usr/tmp"`, but the assembler uses `"/tmp"`.
* Some more changes.

## Linux compatibility notes

* The Linux distribution and the libc don't matter, everything is
  self-contained (and statically linked) in pts-svr3as-linux.
* Linux i386 and Linux amd64 systems are able to run Linux i386 ELF-32
  executables. Linux 1.0 already has ELF-32 support.
* The 4 assemblers in pts-svr3as-linux have been tested and working on:
  Linux 5.4.0 amd64, Linux 1.0.4 i386 (Linux distribution
  [MCC-1.0](https://www.ibiblio.org/pub/historic-linux/distributions/MCC-1.0/1.0/)
  released on 1994-05-11, kernel released on 1994-03-22) and qemu-i386
  2.11.1 running on Linux amd64.
* For each run, the assemblers create 13 temporary files (in `$TMPDR`, which
  is `/tmp/` by default). They clean up when they finish (even at failure
  and at SIGINT).
* The 3 SVR3 assemblers were already statically linked. As part of porting,
  the SVR3 system calls (syscalls) were replaced with an emulation based on
  Linux i386 system calls.
* The SunOS 4.0.1 assembler was dynamically linked against SunOS libc.so. As
  part of porting, replacement functions were provided from libc functions
  (including printf(3) etc.), from
  [minilibc686](https://github.com/pts/minilibc686). These are the functions
  in sunos4as-1988-11-16.nasm whose name starts with `mini_`.

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
* thue SunOS 4.0.1 assembler (earliest remaining file date 1988-11-16),
  based on the SVR3 assembler from 1987
* GNU Assembler (released for i386 in about 1990), now part of GNU Binutils,
  still in active development in 2024
* the assembler in Sun Solaris is based on the SVR4 assembler, later
  versions used the GNU Assembler
* the Mark Williams 80386 assembler (earliest remaining file date
  1992-09-11, part of Coherent 4.x)
* [vasm](http://sun.hasenbraten.de/vasm/) by Volker Barthelmann,
  still in active development in 2024
