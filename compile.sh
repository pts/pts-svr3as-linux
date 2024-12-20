#! /bin/sh --
# by pts@fazekas.hu at Thu Oct 24 02:35:50 CEST 2024

# Magic to reproducibly run the rest of this script using tools in `tools/*'.
export LC_ALL=C  # To avoid surprises with localized error messages etc.
if test "$1" = --bbsh-script; then  # Running under tools/busybox with applets e.g. `env' built in, ignoring $PATH.
  shift; mydir="$1"; shift
  export PATH="$mydir/tools"
  if test "$1" = --noenv; then shift; exec env -i LC_ALL=C sh "$0" --bbsh-script "$mydir" "$@"; exit 1; fi
else
  unset mydir; mydir="${0%/*}"  # TODO(pts): Use readlink(1) if available.
  case "$mydir" in /* | . | ./*) ;; *) mydir="./$mydir" ;; esac
  # TODO(pts): --sys --noenv should keep $PATH.
  if test "$1" = --sys-all; then shift  # Use the current shell, nasm(1), sha256sum(1) etc. on the system.
  elif test "$1" = --sys; then shift; export PATH="$mydir/tools:$PATH"  # Use the current shell, sha256sum(1) etc. on the system, but use `tools/nasm'.
  elif test "$1" = --noenv; then shift; exec "$mydir/tools/busybox" env -i LC_ALL=C "$mydir/tools/busybox" sh -- "$0" --bbsh-script "$mydir" "$@"; exit 1
  else exec "$mydir/tools/busybox" sh -- "$0" --bbsh-script "$mydir" "$@"; exit 1
  fi
fi

set -ex
cd "$mydir"
type nasm

if test -f svr3as-1987-10-28.svr3; then
  test "$(sha256sum <svr3as-1987-10-28.svr3)" = "877f6a1f614a0fd3fe1864b3f89a6f379b942a7b6c415b9f02987018a9a52c3d  -"
  rm -f svr3as-1987-10-28
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1987-10-28 svr3as-1987-10-28.nasm
  chmod +x svr3as-1987-10-28
  test "$(sha256sum <svr3as-1987-10-28)" = "33bbf74ff46dd714adcfb9b5542b09d88afef3edce620fb0333d18a66859ca9b  -"
fi

if test -f svr3as-1988-05-27.svr3; then
  test "$(sha256sum <svr3as-1988-05-27.svr3)" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"
  rm -f svr3as-1988-05-27
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1988-05-27 svr3as-1988-05-27.nasm
  chmod +x svr3as-1988-05-27
  test "$(sha256sum <svr3as-1988-05-27)" = "a251f7194ec830d7b661b1a139921389968cbb8ade21d052a6761f6ddf09ae2e  -"
fi

if test -f svr3as-1989-10-03.svr3; then
  test "$(sha256sum <svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
  rm -f svr3as-1989-10-03
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1989-10-03 svr3as-1989-10-03.nasm
  chmod +x svr3as-1989-10-03
  test "$(sha256sum <svr3as-1989-10-03)" = "d0ee5856c95fa32f22693631e954e2dfb12bd7320aadc0aac15f3a70898e6fc0  -"
fi

if test -f sunos4as-1988-11-16.svr3; then
  test "$(sha256sum <sunos4as-1988-11-16.svr3)" = "1430efc421121826f6e04cb6f21f87007f1786961c1ae8c4d5e05b6c5dbe061a  -"
  rm -f sunos4as-1988-11-16
  nasm -w+orphan-labels -f bin -O0 -o sunos4as-1988-11-16 sunos4as-1988-11-16.nasm
  chmod +x sunos4as-1988-11-16
  test "$(sha256sum <sunos4as-1988-11-16)" = "dc98cf5e6b39f536c8f31148e387d6e60bbbe7b476cfe52db71013615f0fc99d  -"
  if test -f sunos4as-1988-11-16.sym.inc.nasm; then
    nasm -w+orphan-labels -f elf -O0 -DALLOW_X_SECTIONS -DUSE_SYMS -DUSE_DEBUG -o sunos4as-1988-11-16.o sunos4as-1988-11-16.nasm
    # GNU ld(1) puts PT_LOAD sections in the opposite order in the file, that's why there are mismatches.
    /usr/bin/ld -m elf_i386 -static -nostdlib --fatal-warnings --section-start=.xtext=0x0d142e --section-start=.xdata=0x011074 --section-start=.xbss=0x1942e -o sunos4as-1988-11-16.elf sunos4as-1988-11-16.o
  fi
fi

# --- Tests. They don't work with cross-compilation.

for prog in svr3as-1987-10-28 svr3as-1988-05-27 svr3as-1989-10-03; do
  test -f "$prog" || continue
  rm -f test.o
  # The -dg and -dv flags are ignored.
  ./"$prog" -dt -dg -dv test.s
  cmp -l test.o.good test.o
done
for prog in sunos4as-1988-11-16 sunos4as-1988-11-16.elf; do
  test -f "$prog" || continue
  rm -f test.o
  # The -dg flag prevents the -lg symbol from being generated.
  # The -dv flag prevents the .version directive from adding a string to the .comment section.
  ./"$prog" -dt -dg -dv test.s
  cmp -l test.o.good test.o
done

: "$0" OK.
