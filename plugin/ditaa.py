#!/usr/bin/env python3

"""
Pandoc filter to process code blocks with class "ditaa".
"""

import subprocess
import hashlib
import os
import sys
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

def ditaa(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    if "ditaa" in classes:
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
        p = subprocess.Popen(["ditaa", tmp, src],
                shell=False, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, close_fds=True)
        err = p.stderr.read().decode("utf-8")
        p.stderr.close()
        if (len(err) > 0):
            return Para([Str(err)])
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
  toJSONFilter(ditaa)
