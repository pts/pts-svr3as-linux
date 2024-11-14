; by pts@fazekas.hu at Tue Mar 19 15:14:14 CET 2024
; v2 at Thu Mar 28 05:05:00 CET 2024
; v3 at Thu Oct 24 02:14:30 CEST 2024
;
; To be used as `%include 'binpatch.inc.nasm'
; in: nasm-0.98.39 -O0 -w+orphan-labels -f bin -o prog prog.nasm && chmod +x prog

bits 32
cpu 386

; NASM `-f elf' defaults:
;section .text          progbits      alloc   exec    nowrite  align=16
;section .rodata        progbits      alloc   noexec  nowrite  align=4
;section .lrodata       progbits      alloc   noexec  nowrite  align=4
;section .data          progbits      alloc   noexec  write    align=4
;section .ldata         progbits      alloc   noexec  write    align=4
;section .bss           nobits        alloc   noexec  write    align=4
;section .lbss          nobits        alloc   noexec  write    align=4
;section .tdata         progbits      alloc   noexec  write    align=4   tls
;section .tbss          nobits        alloc   noexec  write    align=4   tls
;section .comment       progbits      noalloc noexec  nowrite  align=1
;section .preinit_array preinit_array alloc   noexec  nowrite  pointer
;section .init_array    init_array    alloc   noexec  nowrite  pointer
;section .fini_array    fini_array    alloc   noexec  nowrite  pointer
;section .note          note          noalloc noexec  nowrite  align=4
;section other          progbits      alloc   noexec  nowrite  align=1

%macro __ensure_section_ncomment 0
  %undef section
  %ifndef __ensure_section_ncomment
    %define __ensure_section_ncomment __ensure_section_ncomment
    %ifidn __OUTPUT_FORMAT__, bin
      section .ncomment start=0 vstart=s.ncomment.vstart align=1
    %else
      ; Just for MISSING_END_AT_EOF.
      section .ncomment      progbits      noalloc noexec  nowrite  align=1
    %endif
    s.ncomment.start:
  %else
    section .ncomment
  %endif
  %idefine section __nsection
%endm

%macro opt.o0 0    ; Make NASM compilation faster. For this file the output is the same.
%endm

%macro __had_error 0  ; Make NASM (0.98.39) fail eventually. `%error' in NASM 0.98.39 just prints a waring, and the NASM command will succeed.
  %ifndef __had_error
    %define __had_error  ; Make it a no-op next time.
    __ensure_section_ncomment
    db HAD_NASM_ERROR  ; NASM will fail with: error: symbol `HAD_NASM_ERROR' undefined
  %endif
%endm

%macro extrn 1
  extern %1
  dd %1
%endmacro

%macro call_extrn_at 2  ; If we use call_extrn_at in .xtext instead of jmp6_extrn in .idata, and no other code in .xtext uses .idata, then .xtext can become shorter.
  incbin_until %1
  extern %2
  call %2  ; 5 bytes.
%endmacro

%macro jmp6_extrn 1  ; If we use jmp6_extrn in .xtext instead of extrn in .idata, and no other code in .xtext uses .idata, then define.idata can be omitted.
  extern %1
  jmp strict near %1  ; 5 bytes.
  nop  ; 1 byte.
%endmacro

%macro assert_at 1
  times +$-(%1) times 0 nop
  times -$+(%1) times 0 nop
%endm


; --- The non-.x* sections.

%idefine section __nsection
%macro __nsection 1+
  sectiond%1 , dummy  ; The dummy argument makes sure that NASM fails if the section.* macro is not defined.
%endm

%macro __check_no_section_flags 1
  %ifnidn (%1),()
    %error SECTION_MUST_HAVE_NO_FLAGS
    __had_error
  %endif
%endm

%macro __undef_xs 0
  %undef  __vstart
  %undef  __fstart
  %undef  __fsize
%endm

; Don't use sections .text, .rodata, .rodata.str1.1, .data or .bss with
; `nasm -f bin'. Use .xtext etc. instead.
%ifnidn __OUTPUT_FORMAT__, bin
  %macro section.text 0
    sectiond.text , dummy
  %endm
  %macro sectiond.text 2
    section.text %1
  %endm
  %define section.text.align1 align=1
  %macro section.text 1+  ; Example: section.text align=4
    %undef section
    section .text section.text.align1 %1
    %define section.text.align1  ; Prevent subsequent warning.
    %idefine section __nsection
    __undef_xs
  %endm

  %macro section.rodata 0
    %undef section
    section .rodata
    %idefine section __nsection
    __undef_xs
  %endm
  %macro section.rodata 1+  ; Example: section.rodata align=1
    %undef section
    section .rodata %1
    %idefine section __nsection
    __undef_xs
  %endm
  %macro sectiond.rodata 2
    section.rodata %1
  %endm

  ; This doesn't work, because NASM doesn't generate the section flags from which GNU ld(1) would recognize it.
  ; TODO(pts): Add elfofix post-processing.
  ;%macro section.rodata.str1.1 0  ; Like .rodata, but GNU ld(1) unifies NUL-terminated string literals within here.
  ;  %undef section
  ;  section .rodata.str1.1
  ;  %idefine section __nsection
  ;  __undef_xs
  ;%endm
  ;%define section.rodata.str1.1.align1 progbits alloc noexec nowrite align=1
  ;%macro section.rodata.str1.1 1+  ; Example: section.rodata.str1.1 align=4
  ;  %undef section
  ;  section .rodata.str1.1 section.rodata.str1.1.align1 %1
  ;  %define section.rodata.str1.1.align1  ; Prevent subsequent warning.
  ;  %idefine section __nsection
  ;  __undef_xs
  ;%endm
  ;%macro sectiond.rodata.str1.1 2
  ;  section.rodata.str1.1 %1
  ;%endm

  %macro section.data 0
    sectiond.data , dummy
  %endm
  %macro sectiond.data 2
    section.data %1
  %endm
  %macro section.data 1+  ; Example: section.data align=1
    %undef section
    section .data %1
    %idefine section __nsection  ; NASM default: section .data          progbits      alloc   noexec  write    align=4
    __undef_xs
  %endm

%endif  ; %ifnidn __OUTPUT_FORMAT__, bin

%macro section.bss 0
  sectiond.bss , dummy
%endm
%macro sectiond.bss 2
  section.bss %1
%endm
%ifnidn __OUTPUT_FORMAT__, bin
  %define section.bss.qualifiers
%elifdef s.xbss.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.xbss
%elifdef s.xdebug.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.xdebug
%elifdef s.reloc.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.reloc
%elifdef s.idata.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.idata
%elifdef s.xdata.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.xdata
%elifdef s.xrodata.used
  %define section.bss.qualifiers nobits valign=4 vfollows=.xrodata
%else
  %define section.bss.qualifiers nobits valign=4 vfollows=.xtext
%endif
%macro section.bss 1+  ; Example: section.bss align=1
  %undef section
  section .bss section.bss.qualifiers %1  ; NASM default: section .bss           nobits        alloc   noexec  write    align=4
  %define section.bss.qualifiers  ; Prevent subsequent warning.
  %idefine section __nsection
  %define __snobits
  __undef_xs
%endm

%macro section.ncomment 0
  sectiond.ncomment , dummy
%endm
%macro sectiond.ncomment 2
  section.ncomment %1
%endm
%macro section.ncomment 1+
  __check_no_section_flags %1
  __ensure_section_ncomment
  __undef_xs
%endm

; --- The .x* sections: sections generated from XBINFN, with possible modifications.

; Fallback values for `%macro reloc_at'.
%define s.xdebug.getvsize 0
%define s.xdebug.getfsize 0
%define s.xrodata.getfsize 0
%define s.xdata.getvsize 0
%define s.xdata.getfsize 0
%define s.xtext.getfsize 0
%define s.xdebug.getvstart 0
%define s.xtext.getvstart 0
%define s.xdata.getvstart 0
%define s.xrodata.getvstart 0
%define s.xtext.getvstart 0

%macro __error_missing_define_for_x_section 1
  %error MISSING_DEFINE_FOR_X_SECTION (%1)
  __had_error
  %undef section
  section .bss  ; Make it consistent.
  %idefine section __nsection
%endm

%macro __check_no_x_section 1
  __check_no_x_section_used %1, %1.used  ; Two-step macro argument expansion. Not needed by NASM 0.98.39, but needed bt newer ones.
%endm
%macro __check_no_x_section_used 2  ; Example: __check_no_x_section_used .xtext, .xtext.used
  %ifdef s%2
    %error UNEXPECTED_X_SECTION (%1)
    __had_error
  %endif
%endm


%macro __check_x_section 1
  __check_x_section_used %1, %1.used  ; Two-step macro argument expansion. Not needed by NASM 0.98.39, but needed bt newer ones.
%endm
%macro __check_x_section_used 2  ; Example: __check_x_section_used .xtext, .xtext.used
  %ifndef s%2
    %error REQUIRED_X_SECTION_MISSING (%1)
    __had_error
  %endif
%endm

%macro __check_fout_and_vstart 1  ; Example: __check_fout_and_vstart .xtext
  %if ((s%1.fout)&0xfff) != ((s%1.vstart)&0xfff)
    %assign __bad_fout s%1.fout
    %assign __bad_vstart s%1.vstart
    %assign __bad_fout_rem (s%1.fout)&0xfff
    %assign __bad_vstart_rem (s%1.vstart)&0xfff
    %error OFFSET_MISMATCH_IN_X_SECTION_FOUT_AND_VSTART (%1) (__bad_fout)->(__bad_fout_rem) (__bad_vstart)->(__bad_vstart_rem)
    __had_error
  %endif
%endm
%macro __need_end_at_eof 0
  %ifndef MISSING_END_AT_EOF
    %define MISSING_END_AT_EOF MISSING_END_AT_EOF
    %define __need_end_at_eof  ; Make it a no-op next time.
    __ensure_section_ncomment
    %ifidn __OUTPUT_FORMAT__, bin
      __OSABI_Linux equ 3
      Elf32_Ehdr:
      db 0x7F,'ELF',1,1,1,__OSABI_Linux,0,0,0,0,0,0,0,0,2,0,3,MISSING_END_AT_EOF  ; Without MISSING_END_AT_EOF here, compilation would succeed without the `end' command at the end of the source file.
      dd 1,_start,Elf32_Phdr0-Elf32_Ehdr,0,0
      dw Elf32_Phdr0-Elf32_Ehdr,0x20,(Elf32_Phdr_end-Elf32_Phdr0)/0x20,0x28,0,0
      Elf32_Phdr0: dd 1, 0, s.ncomment.vstart, s.ncomment.vstart, p.re.fsize, p.re.fsize, 5, 0x1000
      ; LOAD off 0x0000ede4 vaddr 0x00400de4 paddr 0x00400de4 align 2**12 filesz 0x00001fbc memsz 0x00002a68 flags rw-
      ; Generate Elf32_Phdr1 later, only when we know we need it (because of .xdata, .xbss etc.).
    %else
      ; `section .comment' works in NASM 2.13.02, error in NASM 0.98.39:
      ; error: attempt to redefine reserved sectionname `.comment'. So
      ; we use `section .ncomment instead.
      ;
      ; If the user omits the `end' at the end of the .nasm source, NAsM would fail with:
      ; error: symbol `MISSING_END_AT_EOF' undefined
      db MISSING_END_AT_EOF
    %endif
    %undef section
    section .bss  ; Make it consistent.
    %idefine section __nsection
  %endif
%endm

%macro __define_x_sections 0
  %ifndef __define_x_sections
    %define __define_x_sections  ; Make it a no-op next time.
    %ifndef XBINFN
      %error MISSING_DEFINE_XBIN
      __had_error
    %endif
    %ifndef ALLOW_X_SECTIONS
      %ifnidn __OUTPUT_FORMAT__, bin
        ; .x* sections need proper post-processing. This error is prevent the
        ; usage of this feature by accident. Tools doing the post-processing
        ; specify `nasm -DALLOW_X_SECTIONS'.
        %error NON_BIN_OUTPUT_NEEDS_ALLOW_X_SECTIONS
        __had_error
      %endif
    %endif
    __need_end_at_eof
    %ifdef had.opt.move  ; Not defined in binpatch.inc.nasm.
      %define __xtext .text.x  ; GNU ld(1) will merge this to .text.
      %define __xdata .data.x
      %define __xbss .bss.x
      %define __xrodata .rodata.x
      %define __xdebug .rodata.xd
      %define __s_align 4
    %else
      %define __xtext .xtext
      %define __xdata .xdata
      %define __xbss .xbss
      %define __xrodata .xrodata
      %define __xdebug .xdebug
      %define __s_align 1
    %endif
    %undef section
    %ifidn __OUTPUT_FORMAT__, bin
      %ifdef s.header.used
        section .header align=1 valign=1 start=s.header.fout vstart=s.header.vstart
        s.header.start:
      %endif
      %ifdef s.xtext.used
        section __xtext align=1 valign=1 start=s.xtext.fout vstart=s.xtext.vstart
        s.xtext.start:
      %endif
      %ifdef s.xrodata.used
        section __xrodata align=1 valign=1 start=s.xrodata.fout vstart=s.xrodata.vstart
        s.xrodata.start:
      %endif
      %ifdef s.xdata.used
        section __xdata align=1 valign=1 start=s.xdata.fout vstart=s.xdata.vstart
        s.xdata.start:
      %endif
      %ifdef s.idata.used
        section __idata align=1 valign=1 start=s.idata.fout vstart=s.idata.vstart
        s.idata.start:
      %endif
      %ifdef s.reloc.used
        section .reloc align=1 valign=1 start=s.reloc.fout vstart=s.reloc.vstart
        s.reloc.start:
      %endif
      %ifdef s.xdebug.used
        section __xdebug align=1 valign=1 start=s.xdebug.fout vstart=s.xdebug.vstart
        s.xdebug.start:
      %endif
      %ifdef s.xbss.used
        section __xbss nobits align=1 start=s.xbss.vstart
        s.xbss.start:
      %endif
    %else
      section .header   progbits alloc exec   nowrite align=1  ; ''
        s.header.start:
      section .idata    progbits alloc noexec write   align=1  ; '.idata'
        s.idata.start:
      section __xtext   progbits alloc exec   nowrite align=1  ; 'CODE', '_TEXT'
        s.xtext.start:
      section __xdata   progbits alloc noexec write   align=__s_align  ; 'DATA', '.CRT$XIA'
        s.xdata.start:
      section __xbss    nobits   alloc noexec write   align=__s_align  ; ''
        s.xbss.start:
      section .reloc    progbits alloc noexec nowrite align=1  ; '.reloc'; TODO(pts): Don't even map it.
        s.reloc.start:
      section __xrodata progbits alloc noexec nowrite align=__s_align  ; Usually missing from some programs, it's typically part of .xtext.
        s.xrodata.start:
      section __xdebug  progbits alloc noexec nowrite align=__s_align  ; '.debug'; TODO(pts): Don't even map it. For ld(1), the section name .debug is special.
        s.xdebug.start:
    %endif
    %idefine section __nsection
  %endif
%endm

%macro assert_addr 1
  times +($-$$)-((%1)-__vstart) times 0 nop
  times -($-$$)+((%1)-__vstart) times 0 nop
%endm
%macro incbin_until 1
  ; Needs something like this: %define XBINFN 'origprog.bin'
  %if (%1)<__vstart
    %error INCBIN_UNTIL_CANNOT_START_BEFORE_VSTART
    __had_error
  %endif
  %if (%1)-(($-$$)+__vstart)<0
    %error INCBIN_UNTIL_CANNOT_GO_BACK
    __had_error
  %endif
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)
  assert_addr %1
%endm
%macro iu 1  ; Like `incbin_until %1', but faster, because it doesn't do any address checks.
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)
%endm

%macro nop_until 1
  fill_until %1, nop
%endm
%macro fill_until 1
  %ifdef __snobits
    %if -($-$$)+((%1)-__vstart)<0
      times -($-$$)+((%1)-__vstart) resb 0  ; A more consistent error.
    %else
      resb -($-$$)+((%1)-__vstart)
    %endif
    assert_addr %1
  %else
    fill_until %1, db 0
  %endif
%endm
%macro fill_until 2+  ; Example: fill_until 0x1234, clc
  times -($-$$)+((%1)-__vstart) %2
  assert_addr %1
%endm

extern emu_seh0_frame

;%macro seh0 3+
;  %define __seh0_addr 0x0
;  incbin_until %1
;  fs %3
;  assert_addr (%1)+(%2)
;%endm
%macro seh0 3+
  %define __seh0_addr emu_seh0_frame
  incbin_until %1
  nop  ; Instead of the fs prefix.
  %3
  assert_addr (%1)+(%2)
%endm

%macro replace1 3+  ; Like seh0, but can insert 0+ nops, as needed.
  incbin_until %1
  %%before: %3
  times (%2)-($-%%before) nop
  assert_addr (%1)+(%2)
%endm

; Internal macro by this .inc.nasm file.
%macro __define_x_section 4
  s%1.fsize equ %2
  s%1.vstart equ %3
  s%1.fstart equ %4
  %ifidn %1, .header
    ImageBase equ s.header.vstart
  %endif
%endmacro

%macro define.xbin 1
  %xdefine XBINFN %1
  %ifidn (XBINFN), ()
    %define incbin_or_fill_until fill_until
  %else
    %define incbin_or_fill_until incbin_until
  %endif
%endm
%macro define.xbin 0  ; Indicate that `incbin XBINFN, ...' won't work.
  %define XBINFN
  %define incbin_or_fill_until fill_until
%endm

%macro define.header 2  ; .fsize, .vstart  ; .fsize is based on the .fstart of the first section, .vstart is ImageBase in the output of `objdump -x' and `org' in the IDA .lst file.
  __define_x_section .header, %1, %2, 0
  %define s.header.used
%endm
%macro define.xtext 3  ; .fsize, .vstart, .fstart
  ; TODO(pts): Make it (and others) work without .fstart. .fstart is only needed for incbin_until.
  __define_x_section .xtext, %1, %2, %3
  %define s.xtext.getfsize s.xtext.fsize
  %define s.xtext.getvstart s.xtext.vstart
  %define s.xtext.used
%endm
%macro define.xdata 4
  __define_x_section .xdata, %1, %2, %3
  s.xdata.vsize equ %4  ; .VirtualSize of section '.xdata'. Missing from the output of `objdump -x`, got it from the IDA .lst file.
  %define s.xdata.getfsize s.xdata.fsize
  %define s.xdata.getvsize s.xdata.vsize
  %define s.xdata.getvstart s.xdata.vstart
  %define s.xdata.used
  %if s.xdata.vsize>s.xdata.fsize
    %define s.xbss.used
  %endif
%endm
%macro define.xdata 3
  define.xdata %1, %2, %3, 0  ; No .xbss.
%endm
%macro define.idata 4
  __define_x_section .idata, %1, %2, %3
  s.idata.vextrns equ %4
  %define s.idata.used
%endm
%macro define.reloc 3
  __define_x_section .reloc, %1, %2, %3
%endm
%macro define.xrodata 3  ; .fsize, .vstart, .fstart
  __define_x_section .xrodata, %1, %2, %3
  %define s.xrodata.getfsize s.xrodata.fsize
  %define s.xrodata.getvstart s.xrodata.vstart
  %define s.xrodata.used
%endm
%macro define.xdebug 4
  __define_x_section .xdebug, %1, %2, %3
  s.xdebug.vsize equ %4   ; .VirtualSize of section '.debug'.   Missing from the output of `objdump -x`, got it from the IDA .lst file.
  %define s.xdebug.getvsize s.xdebug.vsize
  %define s.xdebug.getvstart s.xebug.vstart
  %define s.xdebug.used
%endm

%macro section.header 0
  sectiond.header , dummy
%endm
%macro sectiond.header 2
  section.header %1
%endm
%macro section.header 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.header.used
    %undef section
    section .header
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.header.vstart
    %assign __fstart s.header.fstart
    %assign __fsize  s.header.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.idata 0
  sectiond.idata , dummy
%endm
%macro sectiond.idata 2
  section.idata %1
%endm
%macro section.idata 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.idata.used
    %undef section
    section .idata
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.idata.vstart
    %assign __fstart s.idata.fstart
    %assign __fsize  s.idata.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.xtext 0
  sectiond.xtext , dummy
%endm
%macro sectiond.xtext 2
  section.xtext %1
%endm
%macro section.xtext 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.xtext.used
    %undef section
    section __xtext
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.xtext.vstart
    %assign __fstart s.xtext.fstart
    %assign __fsize  s.xtext.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.xrodata 0
  sectiond.xrodata , dummy
%endm
%macro sectiond.xrodata 2
  section.xrodata %1
%endm
%macro section.xrodata 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.xrodata.used
    %undef section
    section __xrodata
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.xrodata.vstart
    %assign __fstart s.xrodata.fstart
    %assign __fsize  s.xrodata.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.xdata 0
  sectiond.xdata , dummy
%endm
%macro sectiond.xdata 2
  section.xdata %1
%endm
%macro section.xdata 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.xdata.used
    %undef section
    section __xdata
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.xdata.vstart
    %assign __fstart s.xdata.fstart
    %assign __fsize  s.xdata.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.xbss 0
  sectiond.xbss , dummy
%endm
%macro sectiond.xbss 2
  section.xbss %1
%endm
%macro section.xbss 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.xbss.used
    %undef section
    section __xbss
    %idefine section __nsection
    %define __snobits
    %assign __vstart s.xdata.vstart+s.xdata.fsize
    %undef  __fstart
    %undef  __fsize
  %else
    __error_missing_define_for_x_section .xbss
  %endif
%endm

%macro section.reloc 0
  sectiond.reloc , dummy
%endm
%macro sectiond.reloc 2
  section.reloc %1
%endm
%macro section.reloc 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.reloc.used
    %undef section
    section .reloc
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.reloc.vstart
    %assign __fstart s.reloc.fstart
    %assign __fsize  s.reloc.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%macro section.xdebug 0
  sectiond.xdebug , dummy
%endm
%macro sectiond.xdebug 2
  section.xdebug %1
%endm
%macro section.xdebug 1+
  __check_no_section_flags %1
  __define_x_sections
  %ifdef s.xdebug.used
    %undef section
    section __xdebug
    %idefine section __nsection
    %undef __snobits
    %assign __vstart s.xdebug.vstart
    %assign __fstart s.xdebug.fstart
    %assign __fsize  s.xdebug.fsize
  %else
    __error_missing_define_for_x_section .xtext
  %endif
%endm

%define p.rw.vsize.in.phdr1 p.rw.vsize  ; The user can override it.

%macro end 0  ; Mandatory at the end of the .nasm source file if any of the .x* sections have been defined.
  MISSING_END_AT_EOF equ 0  ; Prevent NASM error.
  %ifdef __define_x_sections  ; At least one of the .x* sections have been defined.
    __define_x_sections  ; Define all .x* sections.
    __ensure_section_ncomment
      s.ncomment.end:
    %ifdef s.header.used
      section.header
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.header.end:
    %endif
    %ifdef s.xtext.used
      section.xtext
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.xtext.end:
    %endif
    %ifdef s.xrodata.used
      section.xrodata
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.xrodata_end:
    %endif
    %ifdef s.xdata.used
      section.xdata
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.xdata.end:
    %endif
    %ifdef s.idata.used
      ; !! Where is it? It doesn't work between .xdata and .xbss, if s.xbss.used.
      section.idata
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.idata.end:
    %endif
    %ifdef s.reloc.used
      ; !! Where is it? It doesn't work between .xdata and .xbss, if s.xbss.used.
      section.reloc
        incbin_or_fill_until __vstart+__fsize
        assert_addr __vstart+__fsize  ; Check that section is not longer.
        s.reloc.end:
    %endif
    %ifdef s.xdebug.used
      ; !! Where is it? It doesn't work between .xdata and .xbss, if s.xbss.used.
      section.xdebug
        incbin_or_fill_until __vstart+__fsize
        times s.xdebug.vsize-__fsize db 0  ; The .debug section was truncated in the input file.
        assert_addr __vstart+s.debug.vsize  ; Check that section is not longer.
        s.xdebug.end:
    %endif
    %ifdef s.xbss.used
      section.xbss
        fill_until s.xdata.vstart+s.xdata.vsize
        s.xbss.end:
    %endif
    %ifidn __OUTPUT_FORMAT__, bin
      __ensure_section_ncomment
        %ifdef s.xdata.used  ; !! TODO(pts): Also for .idata etc. Which of those is writable?
          ; TODO(pts): Simulate `ld -N' by merging the two Phdrs.
          Elf32_Phdr1: dd 1, p.rw.fout, p.rw.vstart, p.rw.vstart, p.rw.fsize, p.rw.vsize.in.phdr1, 6, 0x1000
        %endif
        Elf32_Phdr_end:
      section .bss
      ; !! TODO(pts): Make it work with more .x* sections, starting with .xrodata.
      __check_no_x_section .header
      __check_x_section .xtext
      __check_no_x_section .xrodata
      ;__check_x_section .xdata  ; Can be either way.
      __check_no_x_section .idata
      __check_no_x_section .reloc
      __check_no_x_section .xdebug
      ;__check_x_section .xbss  ; Can be either way.
      s.ncomment.fsize equ s.ncomment.end-s.ncomment.start
      s.ncomment.vstart equ (s.xtext.vstart-s.ncomment.fsize)&~0xfff
      s.xtext.fout equ (s.ncomment.fsize)+((s.xtext.vstart-s.ncomment.fsize)&0xfff)
      __check_fout_and_vstart .xtext  ; The `s.xtext.fout equ' above ensures it.
      p.re.fsize equ s.xtext.fout+s.xtext.fsize
      %ifdef s.xdata.used
        ; TODO(pts): When autocomputing s.xdata.vstart from the autocomputed s.xtext.fsize, also consider align=4 default.
        %if s.xtext.vstart<=s.xdata.vstart && ((s.xtext.vstart+s.xtext.fsize)&~0xfff) >= (s.xdata.vstart&~0xfff)
          %error PAGE_OVERLAP_IN_XTEXT_AND_XDATA  ; Solution: just add a multiple of 0x1000 to s.xdata.vstart in define.xdata.
          __had_error
        %endif
        %if s.xtext.vstart>s.xdata.vstart && ((s.xdata.vstart+s.xdata.vsize)&~0xfff) >= (s.xtext.vstart&~0xfff)
          %error PAGE_OVERLAP_IN_XDATA_AND_XTEXT  ; Solution: just add a multiple of 0x1000 to s.text.vstart in define.xdata.
          __had_error
        %endif
        ; Simplified below:
        ;%if ((s.xtext.fout+s.xtext.fsize)&0xfff) <= ((s.xdata.vstart)&0xfff)
        ;  s.xdata.fout equ ((s.xtext.fout+s.xtext.fsize)&~0xfff) + ((s.xdata.vstart)&0xfff)
        ;%else
        ;  s.xdata.fout equ ((s.xtext.fout+s.xtext.fsize)&~0xfff) + ((s.xdata.vstart)&0xfff) + 0x1000
        ;%endif
        s.xdata.fout equ (s.xtext.fout+s.xtext.fsize)+((s.xdata.vstart-s.xtext.fout-s.xtext.fsize)&0xfff)
        %ifdef s.xbss.used
          s.xbss.vstart equ s.xdata.vstart+s.xdata.fsize  ; TODO(pts): When autocomputing s.xbss.vstart from the autocomputed s.xdata.fsize, also consider align=4 default.
        %endif
        __check_fout_and_vstart .xdata  ; The `s.xdata.fout equ' above ensures it.
        p.rw.fout equ s.xdata.fout
        p.rw.vstart equ s.xdata.vstart
        p.rw.fsize equ s.xdata.fsize
        p.rw.vsize equ s.xdata.vsize  ; Also includes .xbss.
      %else
        %ifdef s.xbss.used  ; !s.xdata.used implies !s.xbss.used.
          %error XBSS_WITHOUT_XDATA
          __had_error
        %endif
        %if 0  ; We don't even generate Elf32_Phdr1.
          p.rw.fout equ s.ncomment.fsize+s.xtext.fsize
          p.rw.vstart equ (s.ncomment.vstart+p.re.fsize+0xfff)&~0xfff  ; Dummy.
          p.rw.fsize equ 0
          p.rw.vsize equ 0
        %endif
      %endif
    %else  ; of %ifidn __OUTPUT_FORMAT__, bin
      %ifdef s.xdata.used
        s.ncomment.fsize equ 0x74  ; Approximation.
      %else
        s.ncomment.fsize equ 0x54  ; Approximation.
      %endif
      %ifdef s.xtext.used
        s.ncomment.vstart equ (s.xtext.vstart-s.ncomment.fsize)&~0xfff
        Elf32_Ehdr equ s.xtext.start-s.xtext.vstart+s.ncomment.vstart
        ;Elf32_Ehdr equ s.ncomment.vstart
      ; TODO(pts): %else ... other .x* sections.
        Elf32_Phdr0 equ Elf32_Ehdr+0x34  ; Approximation. TODO(pts): Is there better symbol generated by GNU ld(1)?
        %ifdef s.xdata.used
          Elf32_Phdr1 equ Elf32_Ehdr+0x54  ; Approximation.
        %endif
      %endif
    %endif
  %endif
  ; TODO(pts): Make subsequent code and data statements (e.g., `db', `nop', `inc') emit an error, without redefining them.
  section .bss  ; Make it consistent. Also make subsequent non-resb code and data statements emit a warning: warning: attempt to initialise memory in BSS section `.bss': ignored
%endm

%macro reloc_at 2  ; Creates a relocation at addr %1, pointing to addr %2 (either in .xtext or .xdata).
  incbin_until %1
  %if (%2)>=s.xtext.getvstart && (%2)<=s.xtext.getvstart+s.xtext.getfsize
    dd s.xtext.start-s.xtext.getvstart+(%2)  ; db 'RRRT'
  %elif (%2)>=s.xrodata.getvstart && (%2)<=s.xrodata.getvstart+s.xrodata.getfsize
    dd s.xrodata.start-s.xrodata.getvstart+(%2)
  %elif (%2)>=s.xdebug.getvstart && (%2)<=s.xdebug.getvstart+s.xdebug.getvsize
    dd s.xdebug.start-s.xdebug.getvstart+(%2)
  %elif (%2)>=s.xdata.getvstart+s.xdata.getfsize && (%2)<=s.xdata.getvstart+s.xdata.getvsize
    dd s.xbss.start-s.xdata.getvstart-s.xdata.getfsize+(%2)
  %elif (%2)>=s.xdata.getvstart && (%2)<=s.xdata.getvstart+s.xdata.getvsize
    dd s.xdata.start-s.xdata.getvstart+(%2)  ; db 'RRRD'
  %else
    %assign __reloc_value (%2)
    %error RELOC_TARGET_SECTION_NOT_FOUND (%2) __reloc_value
    __had_error
  %endif
%endm

%macro requ 1  ; Example: environ requ 0x40056a
  __define_x_sections
  %if (%1)>=s.xtext.getvstart && (%1)<=s.xtext.getvstart+s.xtext.getfsize
    %00 equ s.xtext.start-s.xtext.getvstart+(%1)
  %elif (%1)>=s.xrodata.getvstart && (%1)<=s.xrodata.getvstart+s.xrodata.getfsize
    %00 equ s.xrodata.start-s.xrodata.getvstart+(%1)
  %elif (%1)>=s.xdebug.getvstart && (%1)<=s.xdebug.getvstart+s.xdebug.getvsize
    %00 equ s.xdebug.start-s.xdebug.getvstart+(%1)
  %elif (%1)>=s.xdata.getvstart+s.xdata.getfsize && (%1)<=s.xdata.getvstart+s.xdata.getvsize
    %00 equ s.xbss.start-s.xdata.getvstart-s.xdata.getfsize+(%1)
  %elif (%1)>=s.xdata.getvstart && (%1)<=s.xdata.getvstart+s.xdata.getvsize
    %00 equ s.xdata.start-s.xdata.getvstart+(%1)
  %else
    %assign __requ_value (%1)
    %error LABEL_TARGET_SECTION_NOT_FOUND (%00)=(%1) __requ_value
    __had_error
  %endif
%endm

%macro rt 2  ; Faster version of reloc_at pointing to .xtext, and omitting some checks.
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)  ; Same, but without checks: incbin_until %1
  dd s.xtext.start-s.xtext.vstart+(%2)
%endm
%macro rd 2  ; Faster version of reloc_at pointing to .xdata, and omitting some checks.
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)  ; Same, but without checks: incbin_until %1
  dd s.xdata.start-s.xdata.vstart+(%2)
%endm
%macro rr 2  ; Faster version of reloc_at pointing to .xrodata, and omitting some checks.
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)  ; Same, but without checks: incbin_until %1
  dd s.xrodata.start-s.xrodata.vstart+(%2)
%endm
%macro rb 2  ; Faster version of reloc_at pointing to .xbss, and omitting some checks.
  incbin XBINFN, ($-$$)+__fstart, (%1)-(($-$$)+__vstart)  ; Same, but without checks: incbin_until %1
  dd s.xbss.start-s.xdata.vstart-s.xdata.fsize+(%2)
%endm
; ---

;section __text  ; No default. It would actually default to the last definition (e.g. .bss or .ncomment).
section .bss  ; A useless default, to encourage the user to specify explicitly.

; __END__
