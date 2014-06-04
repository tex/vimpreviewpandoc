#!/usr/bin/env python2

import os
import sys
import socket
import base64
import subprocess

cmd = ["pandoc", "--filter="+sys.argv[2]+"/graphviz.py", \
                 "--filter="+sys.argv[2]+"/realpath.py", \
       sys.argv[1]]
p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
                     close_fds=True, cwd=sys.argv[3])
data = p.stdout.read()
os.remove(sys.argv[1])

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.1', 32000))
s.send("setOutput('" + base64.b64encode(data) + "')")
data = s.recv(2048)
s.close()

