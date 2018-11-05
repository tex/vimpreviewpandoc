#!/usr/bin/env python3

"""
Pandoc filter to process code blocks. This is just a workaround to ?bug? in
qutebrowser causing that newlines in <pre> are ignored when injected
through innerHTML JavaScript.
"""

import os
import sys
from pandocfilters import toJSONFilter, Str, Para, CodeBlock

def pre(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    return [CodeBlock([ident, classes, keyvals], c) for c in code.split('\n')]

if __name__ == "__main__":
  toJSONFilter(pre)
