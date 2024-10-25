#! /bin/sh --
# by pts@fazekas.hu at Fri Oct 25 03:02:48 CEST 2024

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
  elif test "$1" = --noenv; then shift; exec "$mydir/tools/busybox" env -i LC_ALL=C "$mydir/tools/busybox" sh -- "$0" --bbsh-script "$mydir" "$@"; exit 1
  else exec "$mydir/tools/busybox" sh -- "$0" --bbsh-script "$mydir" "$@"; exit 1
  fi
fi

set -ex
cd "$mydir"

do_del_tmp=
for f in "$@"; do  # Import each specified file.
  hash="$(sha256sum <"$f")"
  if test "$hash" = "8b9922b071c35bfeb5ad3bfa20a97089668a0b835bf40e35f345a3de12b39135  -"; then  # import_src/Interactive UNIX386 2.2 rel3.2 (5.25).7z
    # Download from https://winworldpc.com/download/405f52c3-bd18-c39a-11c3-a4e284a2c3a5
    # Interactive UNIX386 Release 3.2 Version 2.2 (5.25): `Interactive UNIX386 2.2 rel3.2 (5.25).7z`, 6586165 bytes.
    # https://winworldpc.com/product/pc-ix/interactive-unix-386-2x
    case "$f" in /*) ;; *) f="$PWD/$f" ;; esac
    case "$mydir" in /*) mydira="$mydir" ;; *) mydira="$PWD/$mydir" ;; esac
    rm -rf import.tmp
    do_del_tmp=1
    mkdir  import.tmp
    (cd import.tmp && "$mydira/tools/tiny7zx" x "$f") || exit "$?"
    f="import.tmp/Interactive UNIX386 2.2 rel3.2 (5¼)/disk23.img"
    hash="$(sha256sum <"$f")"
    test "$hash" = "83beba85b33469d17b2622f4748edfd071f73e389d9588af0a57407937ca0f0e  -"
  fi
  if test "$hash" = "83beba85b33469d17b2622f4748edfd071f73e389d9588af0a57407937ca0f0e  -"; then  # Interactive UNIX386 2.2 rel3.2 (5¼)/disk23.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/f.bin
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0xbc00, 0x1b792' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3as-1989-10-03.svr3 import.tmp/f.nasm
    test "$(sha256sum <import.tmp/svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
    cmp import.tmp/svr3as-1989-10-03.svr3 svr3as-1989-10-03.svr3 2>/dev/null || cp -ai import.tmp/svr3as-1989-10-03.svr3 svr3as-1989-10-03.svr3
    #
    rm -f import.tmp/f.bin
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x6e800, 0x19a82' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3ld-1989-10-03.svr3 import.tmp/f.nasm
    test "$(sha256sum <import.tmp/svr3ld-1989-10-03.svr3)" = "fd019d3e9b3fd5608c3d3bab28ac45d5a3d9d76751ffdea07bc182227d619e14  -"
    cmp import.tmp/svr3ld-1989-10-03.svr3 svr3ld-1989-10-03.svr3 2>/dev/null || cp -ai import.tmp/svr3ld-1989-10-03.svr3 svr3ld-1989-10-03.svr3
    TZ=GMT touch -d '1989-10-03 12:00:00' import.tmp/svr3as-1989-10-03.svr3 import.tmp/svr3ld-1989-10-03.svr3
  fi
  if test "$do_del_tmp"; then rm -rf import.tmp; fi
done

test ! -f svr3as-1989-10-03.svr3 || test "$(sha256sum <svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
test ! -f svr3ld-1989-10-03.svr3 || test "$(sha256sum <svr3ld-1989-10-03.svr3)" = "fd019d3e9b3fd5608c3d3bab28ac45d5a3d9d76751ffdea07bc182227d619e14  -"

: "$0" OK.
