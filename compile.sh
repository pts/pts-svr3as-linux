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
  test "$(sha256sum <svr3as-1987-10-28)" = "2c9857cb4b52923ccfb5a39ed1a319ba7916045872544d8e2507ec4e674b5ef9  -"
fi

if test -f svr3as-1988-05-27; then
  test "$(sha256sum <svr3as-1988-05-27.svr3)" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"
  rm -f svr3as-1988-05-27
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1988-05-27 svr3as-1988-05-27.nasm
  chmod +x svr3as-1988-05-27
  test "$(sha256sum <svr3as-1988-05-27)" = "ad18592a45714213abc6da503ab8c9b892cf6a1b2c8b7d5fdcd56cf90731eb46  -"
fi

if test -f svr3as-1989-10-03.svr3; then
  test "$(sha256sum <svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
  rm -f svr3as-1989-10-03
  nasm -w+orphan-labels -f bin -O0 -o svr3as-1989-10-03 svr3as-1989-10-03.nasm
  chmod +x svr3as-1989-10-03
  test "$(sha256sum <svr3as-1989-10-03)" = "64668ea0a639a877953bfd9d45369fcc821f2e7713ac43982d64d29218344153  -"
fi

# --- Tests. They don't work with cross-compilation.

for prog in svr3as-1987-10-28 svr3as-1988-05-27 svr3as-1989-10-03; do
  test -f "$prog" || continue
  rm -f test.o
  ./"$prog" -dt test.s
  cmp -l test.o.good test.o
done

: "$0" OK.
