#!/usr/bin/env python3

"""
Pandoc filter to process code blocks with class "dot" into
graphviz-generated images.
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

def graphviz(key, value, fmt, meta):
    if key == 'CodeBlock':
        [[ident,classes,keyvals], code] = value
        if "dot" in classes:
            caption, typef, keyvals = get_caption(keyvals)
            path = os.path.dirname(os.path.abspath(__file__))
            filename = sha1(code)
            src = imagedir + '/' + filename + '.png'
            if not os.path.isfile(src):
                try:
                    os.mkdir(imagedir)
                except OSError:
                    pass
                data, err = pipe(["dot", "-Tpng", "-s100"], code)
                if (len(err) > 0):
                    return Para([Str(err)])
                with open(src, 'wb') as f:
                    f.write(data)
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
    toJSONFilter(graphviz)
