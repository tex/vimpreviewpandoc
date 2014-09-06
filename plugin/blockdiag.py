#!/usr/bin/env python2

"""
Pandoc filter to process code blocks with class "blockdiag", "seqdiag",
"actdiag", "nwdiag" into generated images.
"""

import subprocess
import hashlib
import os
import sys
import tempfile
from pandocfilters import toJSONFilter, Str, Para, Image

def sha1(x):
  return hashlib.sha1(x).hexdigest()

imagedir = ".dot"

def save(data):
    fd, name = tempfile.mkstemp()
    os.write(fd, data)
    os.close(fd)
    return name

def isDiag(classes):
    for i in ["blockdiag", "seqdiag", "actdiag", "nwdiag"]:
        if i in classes:
            return True, i
    return False, ""

def blockdiag(key, value, format, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    caption = ""
    found, cmd = isDiag(classes)
    if found == True:
      path = os.path.dirname(os.path.abspath(__file__))
      filename = sha1(code)
      alt = Str(caption)
      tit = ""
      src = imagedir + '/' + filename + '.png'
      if not os.path.isfile(src):
        try:
            os.mkdir(imagedir)
        except OSError:
            pass
        tmp = save(code)
        p = subprocess.Popen([cmd, "-Tpng", "-a", tmp, "-o", src],
                shell=False, stdin=None, stdout=None, stderr=subprocess.PIPE, close_fds=True)
        err = p.stderr.read()
        p.stderr.close()
        if (len(err) > 0):
            return Para([Str(err)])
        os.remove(tmp)
      return Para([Image([alt], [src,tit])])

if __name__ == "__main__":
  toJSONFilter(blockdiag)
