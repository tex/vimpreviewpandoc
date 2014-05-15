#!/usr/bin/env python2

"""
Pandoc filter to process code blocks with class "dot" into
graphviz-generated images.
"""

import pygraphviz
import hashlib
import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

def sha1(x):
  return hashlib.sha1(x).hexdigest()

imagedir = ".dot"

def graphviz(key, value, format, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    caption = "caption"
    if "dot" in classes:
      G = pygraphviz.AGraph(string = code)
      G.layout()
      filename = sha1(code)
      if format == "html":
        filetype = "png"
      elif format == "latex":
        filetype = "pdf"
      else:
        filetype = "png"
      alt = Str(caption)
      src = imagedir + '/' + filename + '.' + filetype
      if not os.path.isfile(src):
        try:
          os.mkdir(imagedir)
        except OSError:
          pass
        G.draw(src)
      tit = ""
      return Para([Image([alt], [src,tit])])

if __name__ == "__main__":
  toJSONFilter(graphviz)
