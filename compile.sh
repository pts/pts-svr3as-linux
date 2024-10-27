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

if test -f svr3as-1988-05-27; then
  test "$(sha256sum <svr3as-1988-05-27.svr3)" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"
  rm -f svr3as-1988-05-27
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1988-05-27 svr3as-1988-05-27.nasm
  chmod +x svr3as-1988-05-27
  test "$(sha256sum <svr3as-1988-05-27)" = "c905a43a52718cac373962c2f4617fed522d874f70c0423541c3c2e10096d6dd  -"
fi

if test -f svr3as-1989-10-03.svr3; then
  test "$(sha256sum <svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
  rm -f svr3as-1989-10-03
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1989-10-03 svr3as-1989-10-03.nasm
  chmod +x svr3as-1989-10-03
  test "$(sha256sum <svr3as-1989-10-03)" = "58559fd25dbc756a8f1ed4663d0227eca4ff75ff6d5ab103a4451dd91e8843b6  -"
fi

# --- Tests. They don't work with cross-compilation.

if test -f svr3as-1988-05-27; then
  rm -f test.o
  ./svr3as-1988-05-27 test.s
  cmp -l test.o.good test.o
fi

if test -f svr3as-1989-10-03; then
  rm -f test.o
  ./svr3as-1989-10-03 test.s
  cmp -l test.o.good test.o
fi

: "$0" OK.
