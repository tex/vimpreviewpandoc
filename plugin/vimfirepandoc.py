#!/usr/bin/env python2

import os
import sys
import socket
import base64
import subprocess

def main():
    filterpath = os.path.dirname(os.path.abspath(__file__))
    projectpath = os.path.dirname(os.path.abspath(sys.argv[1]))

    cmd = ["pandoc", "--filter="+filterpath+"/graphviz.py", \
                     "--filter="+filterpath+"/realpath.py", \
           sys.argv[1]]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
                         close_fds=True, cwd=projectpath)
    data = p.stdout.read()

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 32000))
    s.send("setOutput('" + base64.b64encode(data) + "')")
    data = s.recv(2048)
    s.close()

    cmd = ["pandoc", "--filter="+filterpath+"/graphviz.py", \
                     "--filter="+filterpath+"/realpath.py", \
            sys.argv[1], \
            "-o" + sys.argv[2] + ".docx"]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=None, \
            close_fds=True, cwd=projectpath)
    p.wait()

    os.remove(sys.argv[1])

if __name__ == "__main__":
    main()

