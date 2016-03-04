#!/usr/bin/env python2

"""
Pandoc filter to process image blocks and make absolute paths to
images.
"""

import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

def realpath1(url):
    if url.startswith("http:") or url.startswith("https:"):
        return url
    else:
        return os.path.realpath(url)

def realpath(key, value, fmt, meta):
    if key == 'Image':
         try:
            # Current version of pandoc has the following Image type
            [attr,inline,[url,title]] = value
            return Image(attr, inline, [realpath1(url), title])
         except:
             try:
                # Older versions of pandoc had the following Image type
                 [attr,[url,title]] = value
                 return Image(attr, [realpath1(url), title])
             except:
                 pass

if __name__ == "__main__":
    toJSONFilter(realpath)

