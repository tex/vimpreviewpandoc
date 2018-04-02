#!/usr/bin/env python3

"""
Pandoc filter to process code blocks - this is just a workaround to ?bug? in
qutebrowser causing that <pre> (newlines ignored) is ignored when injected
through innerHTML JavaScript.
"""

import os
import sys
import pandocfilters

def pre(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    return [pandocfilters.CodeBlock([ident, classes, keyvals],c) for c in code.split("\n")]

if __name__ == "__main__":
  pandocfilters.toJSONFilter(pre)
