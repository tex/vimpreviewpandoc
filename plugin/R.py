#!/usr/bin/env python2

"""
Pandoc filter to process code blocks with class "R" into
R-generated images.
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
    p = subprocess.Popen(cmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    p.stdin.write(data)
    p.stdin.close()
    data = p.stdout.read()
    p.stdout.close()
    err = p.stderr.read()
    p.stderr.close()
    return data, err

def graphviz(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], raw_code] = value
    caption = ""
    if "R" in classes:
      path = os.path.dirname(os.path.abspath(__file__))
      filename = sha1(raw_code)
      alt = Str(caption)
      tit = ""
      src = imagedir + '/' + filename + '.png'
      if not os.path.isfile(src):
        try:
            os.mkdir(imagedir)
        except OSError:
            pass
        code = "ppi <- 300\npng('" + src + \
                "', width=6*ppi, height=6*ppi, res=ppi)\n" + raw_code
        data, err = pipe(["R", "--no-save"], code)
        if (len(err) > 0):
            return Para([Str(err)])
      return Para([Image([alt], [src,tit])])

if __name__ == "__main__":
  toJSONFilter(graphviz)
