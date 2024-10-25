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
  hash="$(sha256sum <"$f")"; hash2=

  if test "$hash" = "8b9922b071c35bfeb5ad3bfa20a97089668a0b835bf40e35f345a3de12b39135  -"; then  # import_src/Interactive UNIX386 2.2 rel3.2 (5.25).7z
    # Download from https://winworldpc.com/download/405f52c3-bd18-c39a-11c3-a4e284a2c3a5
    # Interactive UNIX386 Release 3.2 Version 2.2 (5.25): `Interactive UNIX386 2.2 rel3.2 (5.25).7z`, 6586165 bytes.
    # https://winworldpc.com/product/pc-ix/interactive-unix-386-2x
    case "$f" in /*) ;; *) f="$PWD/$f" ;; esac
    case "$mydir" in /*) mydira="$mydir" ;; *) mydira="$PWD/$mydir" ;; esac
    rm -rf import.tmp
    do_del_tmp=1
    mkdir import.tmp
    (cd import.tmp && "$mydira/tools/tiny7zx" x "$f") || exit "$?"
    f="import.tmp/Interactive UNIX386 2.2 rel3.2 (5¼)/disk23.img"; hash="$(sha256sum <"$f")"
    test "$hash" = "83beba85b33469d17b2622f4748edfd071f73e389d9588af0a57407937ca0f0e  -"
    # Fall through.
  fi
  if test "$hash" = "83beba85b33469d17b2622f4748edfd071f73e389d9588af0a57407937ca0f0e  -"; then  # Interactive UNIX386 2.2 rel3.2 (5¼)/disk23.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/f.bin import.tmp/f.nasm import.tmp/*.svr3
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0xbc00, 0x1b792' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3as-1989-10-03.svr3 import.tmp/f.nasm
    f=import.tmp/svr3as-1989-10-03.svr3; hash="$(sha256sum <"$f")"
    test "$hash" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
    #
    rm -f import.tmp/f.bin
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x6e800, 0x19a82' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3ld-1989-10-03.svr3 import.tmp/f.nasm
    f2=import.tmp/svr3ld-1989-10-03.svr3; hash2="$(sha256sum <"$f2")"
    test "$hash2" = "fd019d3e9b3fd5608c3d3bab28ac45d5a3d9d76751ffdea07bc182227d619e14  -"
    # Fall through.
  fi
  if test "$hash" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"; then  # as (svr3as-1989-10-03.svr3)
    if ! cmp -- "$f" svr3as-1989-10-03.svr3 2>/dev/null; then
      cp -ai "$f" svr3as-1989-10-03.svr3
      TZ=GMT touch -d '1989-10-03 12:00:00' svr3as-1989-10-03.svr3
    fi
    if test "$hash2"; then f="$f2"; hash="$hash2"; f2=; hash2=; fi
    # Fall through.
  fi
  if test "$hash" = "fd019d3e9b3fd5608c3d3bab28ac45d5a3d9d76751ffdea07bc182227d619e14  -"; then  # ld (svr3ld-1989-10-03.svr3)
    if ! cmp -- "$f" svr3ld-1989-10-03.svr3 2>/dev/null; then
      cp -ai "$f" svr3ld-1989-10-03.svr3
      TZ=GMT touch -d '1989-10-03 12:00:00' svr3ld-1989-10-03.svr3
    fi
  fi

  if test "$hash" = "cee926538286ea8db7c3b477f9a906c75768ed4baeae71db789e7cfdf83a88fc  -"; then  # SYSV_386_3.2_SDS_4.1.5.zip
    # Download http://bitsavers.org/bits/ATT/SYSV_386/SYSV_386_3.2_SDS_4.1.5.zip
    # Download from http://bitsavers.org/bits/ATT/SYSV_386/
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/sds1.imd
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    unzip -p "$f" SYSV_386_3.2_SDS_4.1.5/SDS1.IMD >import.tmp/sds1.imd
    f=import.tmp/sds1.imd; hash="$(sha256sum <"$f")"
    test "$hash" = "69c306d2fe96b2f686aea044e7a1ea6df65e52f4cdc3d59f90f3e82c78f19d8e  -"
    # Fall through.
  fi
  if test "$hash" = "69c306d2fe96b2f686aea044e7a1ea6df65e52f4cdc3d59f90f3e82c78f19d8e  -"; then  # SYSV_386_3.2_SDS_4.1.5/SDS1.IMD
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/sds1.import.imd import.tmp/sds1.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    ln -s "$ff" import.tmp/sds1.import.imd  # disk-analyse requires the .imd extension.
    disk-analyse import.tmp/sds1.import.imd import.tmp/sds1.img  # Slow.
    f=import.tmp/sds1.img; hash="$(sha256sum <"$f")"
    test "$hash" = "5577d763edd9b0a80174ac229f76da602ef77abe5007df98b5b372e4c85f1c10  -"
    # Fall through.
  fi
  if test "$hash" = "5577d763edd9b0a80174ac229f76da602ef77abe5007df98b5b372e4c85f1c10  -";  then   # sds1.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/f.bin import.tmp/f.nasm import.tmp/*.svr3
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x21b82, 0x1b774' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3as-1988-05-27.svr3 import.tmp/f.nasm
    f=import.tmp/svr3as-1988-05-27.svr3; hash="$(sha256sum <"$f")"
    test "$hash" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"
    #
    rm -f import.tmp/f.bin
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x3d349, 0x19a64' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3ld-1988-05-27.svr3 import.tmp/f.nasm
    f2=import.tmp/svr3ld-1988-05-27.svr3; hash2="$(sha256sum <"$f2")"
    test "$hash2" = "9205364de3df93659ede3ac8d2dabe76151c860090af9b5a71f9ff0edef64d16  -"
    # Fall through.
  fi
  if test "$hash" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"; then  # as (svr3as-1988-05-27.svr3)
    if ! cmp -- "$f" svr3as-1988-05-27.svr3 2>/dev/null; then
      cp -ai "$f" svr3as-1988-05-27.svr3
      TZ=GMT touch -d '1988-05-27 12:00:00' svr3as-1988-05-27.svr3
    fi
    if test "$hash2"; then f="$f2"; hash="$hash2"; f2=; hash2=; fi
    # Fall through.
  fi
  if test "$hash" = "9205364de3df93659ede3ac8d2dabe76151c860090af9b5a71f9ff0edef64d16  -"; then  # ld (svr3ld-1988-05-27.svr3)
    if ! cmp -- "$f" svr3ld-1988-05-27.svr3 2>/dev/null; then
      cp -ai "$f" svr3ld-1988-05-27.svr3
      TZ=GMT touch -d '1988-05-27 12:00:00' svr3ld-1988-05-27.svr3
    fi
  fi

  if test "$hash" = "93845a123ee5a2c8c18b79b03b5453869823cd94203cecbeff02b64559a1f934  -"; then  # SYSV_386_3.1_1.2mb_disk1_missing.zip
    # Download http://bitsavers.org/bits/ATT/SYSV_386/SYSV_386_3.1_1.2mb_disk1_missing.zip
    # Download from http://bitsavers.org/bits/ATT/SYSV_386/
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/41base2.imd
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    unzip -p "$f" SYSV_386_3.1_1.2mb_disk1_missing/41BASE2.IMD >import.tmp/41base2.imd
    f=import.tmp/41base2.imd; hash="$(sha256sum <"$f")"
    test "$hash" = "6a7cdbc4ed8d061c95bb879d92d335a4191b26a2d859f5872bfb34bc992322a7  -"
    # Fall through.
  fi
  if test "$hash" = "6a7cdbc4ed8d061c95bb879d92d335a4191b26a2d859f5872bfb34bc992322a7  -"; then  # SYSV_386_3.1_1.2mb_disk1_missing/41BASE2.IMD
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/41base2.import.imd import.tmp/41base2.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    ln -s "$ff" import.tmp/41base2.import.imd  # disk-analyse requires the .imd extension.
    disk-analyse import.tmp/41base2.import.imd import.tmp/41base2.img  # Slow.
    f=import.tmp/41base2.img; hash="$(sha256sum <"$f")"
    test "$hash" = "be7619558c5484003b7372ece77d646235bb5a9fb53ed24cfc141a30ee11c1cd  -"
    # Fall through.
  fi
  if test "$hash" = "be7619558c5484003b7372ece77d646235bb5a9fb53ed24cfc141a30ee11c1cd  -";  then   # 41base2.img
    do_del_tmp=1
    test -d import.tmp || mkdir import.tmp
    case "$f" in /*) ff="$f" ;; *) f="./$f"; ff="../$f" ;; esac
    rm -f import.tmp/f.bin import.tmp/f.nasm import.tmp/*.svr3
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x2b521, 0x1b26c' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3as-1987-10-28.svr3 import.tmp/f.nasm
    f=import.tmp/svr3as-1987-10-28.svr3; hash="$(sha256sum <"$f")"
    test "$hash" = "877f6a1f614a0fd3fe1864b3f89a6f379b942a7b6c415b9f02987018a9a52c3d  -"
    #
    rm -f import.tmp/f.bin
    ln -s "$ff" import.tmp/f.bin
    echo 'incbin "import.tmp/f.bin", 0x467e2, 0x196d4' >import.tmp/f.nasm
    nasm -O0 -f bin -o import.tmp/svr3ld-1987-10-28.svr3 import.tmp/f.nasm
    f2=import.tmp/svr3ld-1987-10-28.svr3; hash2="$(sha256sum <"$f2")"
    test "$hash2" = "dbd3392779e515dc1ccbec86a64e28ac5af280290b6115ecc57aee23d78b7d1d  -"
    # Fall through.
  fi
  if test "$hash" = "877f6a1f614a0fd3fe1864b3f89a6f379b942a7b6c415b9f02987018a9a52c3d  -"; then  # idas (svr3as-1987-10-28.svr3)
    if ! cmp -- "$f" svr3as-1987-10-28.svr3 2>/dev/null; then
      cp -ai "$f" svr3as-1987-10-28.svr3
      TZ=GMT touch -d '1987-10-28 12:00:00' svr3as-1987-10-28.svr3
    fi
    if test "$hash2"; then f="$f2"; hash="$hash2"; f2=; hash2=; fi
    # Fall through.
  fi
  if test "$hash" = "dbd3392779e515dc1ccbec86a64e28ac5af280290b6115ecc57aee23d78b7d1d  -"; then  # idld (svr3ld-1987-10-28.svr3)
    if ! cmp -- "$f" svr3ld-1987-10-28.svr3 2>/dev/null; then
      cp -ai "$f" svr3ld-1987-10-28.svr3
      TZ=GMT touch -d '1987-10-28 12:00:00' svr3ld-1987-10-28.svr3
    fi
  fi

  if test "$do_del_tmp"; then rm -rf import.tmp; fi
done

test ! -f svr3as-1989-10-03.svr3 || test "$(sha256sum <svr3as-1989-10-03.svr3)" = "f6bbc0d5332bc5c12d471ff8fb430b644b21ceaf2037b3572d4f1d01a7a223d0  -"
test ! -f svr3ld-1989-10-03.svr3 || test "$(sha256sum <svr3ld-1989-10-03.svr3)" = "fd019d3e9b3fd5608c3d3bab28ac45d5a3d9d76751ffdea07bc182227d619e14  -"
test ! -f svr3as-1988-05-27.svr3 || test "$(sha256sum <svr3as-1988-05-27.svr3)" = "ab7048e14136b142c0264d4f13e9771a05c489661acab562b37929931c0f4c04  -"
test ! -f svr3ld-1988-05-27.svr3 || test "$(sha256sum <svr3ld-1988-05-27.svr3)" = "9205364de3df93659ede3ac8d2dabe76151c860090af9b5a71f9ff0edef64d16  -"
test ! -f svr3as-1987-10-28.svr3 || test "$(sha256sum <svr3as-1987-10-28.svr3)" = "877f6a1f614a0fd3fe1864b3f89a6f379b942a7b6c415b9f02987018a9a52c3d  -"
test ! -f svr3ld-1987-10-28.svr3 || test "$(sha256sum <svr3ld-1987-10-28.svr3)" = "dbd3392779e515dc1ccbec86a64e28ac5af280290b6115ecc57aee23d78b7d1d  -"

: "$0" OK.
