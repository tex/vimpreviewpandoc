#!/usr/bin/env python2

"""
Pandoc filter to process image blocks and make absolute paths to
images.
"""

import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

def realpath(key, value, format, meta):
  if key == 'Image':
      [[alt], [src, tit]] = value
      return Image([alt], [os.path.realpath(src), tit])

if __name__ == "__main__":
  toJSONFilter(realpath)
