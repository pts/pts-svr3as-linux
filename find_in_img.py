#! /usr/bin/python
# This program needs Python 2.4--2.7 or 3.x.

import sys


def main(args):
  #bd = open(b'import.tmp/Interactive UNIX386 2.2 rel3.2 (5\xc2\xbc)/disk23.img', 'rb').read()
  #a = open('svr3as-1989-10-03.svr3', 'rb')  # incbin ?, 0xbc00, 0x1b792
  #a = open('svr3ld-1989-10-03.svr3')  # incbin ?, 0x6e800, 0x19a82
  #bs = 1 << 17  # Block size.
  # bs = 0x100

  bd = open(b'import.tmp/sds1.img', 'rb').read()
  #a = open('svr3as-1988-05-27.svr3', 'rb')  # incbin ?, 0x21b82, 0x1b774
  a = open('svr3ld-1988-05-27.svr3')  # incbin ?, 0x3d349, 0x19a64
  bs = 1 << 17  # Block size.

  i = -1
  prev_ofs = None
  while 1:
    i += 1
    data = a.read(bs)
    if not data:
      break
    #data2 = data
    #if len(data) < bs:
    #  data2 = data + '\0' * (bs - len(data))
    if prev_ofs is not None and bd[prev_ofs + bs : prev_ofs + bs + len(data)] == data:
      ofs = prev_ofs + bs
    else:
      ofs = bd.find(data)
      assert ofs >= 0, i
    assert bd[ofs : ofs + len(data)] == data
    print('incbin ?, 0x%x, 0x%x' % (ofs, len(data)))
    prev_ofs = ofs


if __name__ == '__main__':
  sys.exit(main(sys.argv))
