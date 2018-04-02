#!/usr/bin/env python2

"""
Pandoc filter to process code blocks with class "blockdiag", "seqdiag",
"actdiag", "nwdiag", "packetdiag", "rackdiag" into generated images.
This has to be executed by python2 because diag and others are implemented
in python2. Executing in python3 leads to module named site not found
error.
"""

import subprocess
import hashlib
import os
import tempfile
from pandocfilters import toJSONFilter, Str, Para, Image, attributes, get_value, get_caption

def sha1(x):
  return hashlib.sha1(x.encode("utf-8")).hexdigest()

imagedir = ".dot"

def save(data):
    fd, name = tempfile.mkstemp()
    os.write(fd, data.encode("utf-8"))
    os.close(fd)
    return name

def isDiag(classes):
    for i in ["blockdiag", "seqdiag", "actdiag", "nwdiag", "packetdiag", "rackdiag"]:
        if i in classes:
            return True, i
    return False, ""

def blockdiag(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    found, cmd = isDiag(classes)
    if found == True:
      caption, typef, keyvals = get_caption(keyvals)
      path = os.path.dirname(os.path.abspath(__file__))
      filename = sha1(code)
      src = imagedir + '/' + filename + '.png'
      if not os.path.isfile(src):
        try:
            os.mkdir(imagedir)
        except OSError:
            pass
        tmp = save(code)
        p = subprocess.Popen([cmd, "-a", tmp, "-o", src],
                shell=False, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
        out = p.stdout.read().decode("utf-8")
        err = p.stderr.read().decode("utf-8")
        p.stderr.close()
        if (len(err) > 0):
            return Para([Str(out + " " + err)])
        os.remove(tmp)
      try:
        image = Image([ident, [], keyvals], caption, [src, typef])
        return Para([image])
      except:
        try:
          image = Image(caption, [src, typef])
          return Para([image])
        except:
          pass

if __name__ == "__main__":
  toJSONFilter(blockdiag)
