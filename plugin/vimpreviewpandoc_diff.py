#!/usr/bin/env python2

import os
import subprocess
import sys
import vimpreviewpandoc
import htmltreediff

def pandoc(cwdpath, filterpath, inp):
    cmd = ["pandoc" \
          , "--filter="+filterpath+"/graphviz.py" \
          , "--filter="+filterpath+"/blockdiag.py" \
          , "--filter="+filterpath+"/realpath.py" \
          , "--number-section"]
    p = subprocess.Popen(cmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, \
            close_fds=True, cwd=cwdpath)
    p.stdin.write(inp)
    p.stdin.close()
    return p.stdout.read()

def git_show(filename, rev):
    cwdpath = os.path.dirname(os.path.abspath(filename))
    cmd = ["git" \
          , "show" \
          , rev+":"+filename]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
            close_fds=True, cwd=cwdpath)
    return p.stdout.read()

def main():
    try:
        filterpath = os.path.dirname(os.path.abspath(__file__))

        filename = sys.argv[1]
        cwdpath = os.path.dirname(os.path.abspath(filename))

        oldrev = sys.argv[2]
        newrev = sys.argv[3]

        # Diff html
        tn = pandoc(cwdpath, filterpath, git_show(filename, newrev))
        to = pandoc(cwdpath, filterpath, git_show(filename, oldrev))
        diff = htmltreediff.diff(to, tn)

        vimpreviewpandoc.try_output(diff)

    except Exception as e:
        try_output(
                "<h1>Fatal error</h1>" + "<h2>vimpreviewpandoc_diff.py</h2>" +
                "<p>" + traceback.format_exc() + "</p>")

if __name__ == "__main__":
    main()

