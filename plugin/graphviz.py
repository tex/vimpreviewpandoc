#!/usr/bin/env python2

"""
Pandoc filter to process code blocks with class "dot" into
graphviz-generated images.
"""

import subprocess
import hashlib
import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

def sha1(x):
  return hashlib.sha1(x).hexdigest()

imagedir = ".dot"

def pipe(cmd, data):
    p = subprocess.Popen(cmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)
    p.stdin.write(data)
    p.stdin.close()
    data = p.stdout.read()
    p.stdout.close()
    return data

def graphviz(key, value, format, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    caption = ""
    if "dot" in classes:
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
        data = pipe(["dot", "-Tpng", "-s100"], code)
        with open(src, 'w') as f:
          f.write(data)
      return Para([Image([alt], [src,tit])])

if __name__ == "__main__":
  toJSONFilter(graphviz)
