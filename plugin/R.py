#!/usr/bin/env python3

"""
Pandoc filter to process code blocks with class "R" into
R-generated images.
"""

import subprocess
import hashlib
import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image, attributes, get_value, get_caption

def sha1(x):
  return hashlib.sha1(x.encode("utf-8")).hexdigest()

imagedir = ".dot"

def pipe(cmd, data):
    p = subprocess.Popen(cmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    p.stdin.write(data.encode("utf-8"))
    p.stdin.close()
    data = p.stdout.read()
    p.stdout.close()
    err = p.stderr.read().decode("utf-8")
    p.stderr.close()
    return data, err

def R(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], raw_code] = value
    if "r" in classes:
      path = os.path.dirname(os.path.abspath(__file__))
      caption, typef, keyvals = get_caption(keyvals)
      width, keyvals = get_value(keyvals, "width", 7)
      height, keyvals = get_value(keyvals, "height", 7)
      filename = sha1(raw_code + str(width) + str(height))
      src = imagedir + '/' + filename + '.png'
      if not os.path.isfile(src):
        try:
            os.mkdir(imagedir)
        except OSError:
            pass
        code = "ppi <- 100\npng('" + src + \
                "', width=" + width + "*ppi, height=" + height + "*ppi, res=ppi)\n" + raw_code
        data, err = pipe(["R", "--no-save"], code)
        if (len(err) > 0):
            return Para([Str(err)])
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
  toJSONFilter(R)
