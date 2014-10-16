#!/usr/bin/env python2

"""
Pandoc filter to process image blocks and make absolute paths to
images.
"""

import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

def realpath(key, value, fmt, meta):
  if key == 'Image':
      # There is a bug in pandocfilters that prevents
      # me to simple do: [[alt],[src,tit]] = value.
      alt = value[0]
      src = value[1][0]
      tit = value[1][1]
      return Image(alt, [os.path.realpath(src), tit])

if __name__ == "__main__":
  toJSONFilter(realpath)
