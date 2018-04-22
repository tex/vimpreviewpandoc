#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Pandoc filter to process code blocks. This is just a workaround to ?bug? in
qutebrowser causing that <pre> (newlines ignored) is ignored when injected
through innerHTML JavaScript. This is just a workaround to ?bug? in
htmltreediff when doing diff of <pre><code> where it cannot handle
spaces correctly.
"""

import os
import sys
from pandocfilters import toJSONFilter, Str, Para, CodeBlock

def pre(key, value, fmt, meta):
  if key == 'CodeBlock':
    [[ident,classes,keyvals], code] = value
    # Well, empty CodeBlock is not working properly therefore we do
    # the thing with 'c if c else " "'...
    # Well, htmltreediff does not correctly diffs spaces so replacing
    # spaces with U+2005. This is diffed and rendered correctly...
    return [CodeBlock([ident, classes, keyvals], c.replace(" ", u'\u2005') if c else u'\u2005') for c in code.split('\n')]

if __name__ == "__main__":
  toJSONFilter(pre)
