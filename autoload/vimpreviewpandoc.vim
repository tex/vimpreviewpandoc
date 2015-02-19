" Python support required!
if has("python")

" Make sure it gets loaded.
py import vim

let s:path = expand('<sfile>:p:h')

function! vimpreviewpandoc#VimPreviewPandocGitDiff(file, from, to)
    python Diff(vim.eval("a:file"), vim.eval("a:from"), vim.eval("a:to"))
endfunction

function! vimpreviewpandoc#VimPreviewPandoc(force)
    if a:force == 1
        \ || !exists("b:vimpreviewpandoc_changedtick")
        \ || b:vimpreviewpandoc_changedtick != b:changedtick
        python Preview()
    endif
    let b:vimpreviewpandoc_changedtick = b:changedtick
endfunction

function! vimpreviewpandoc#VimPreviewScrollTo()
    if exists("b:vimpreviewpandoc_changedtick")
        \ && b:vimpreviewpandoc_changedtick == b:changedtick
        python ScrollTo()
    endif
endfunction

function! vimpreviewpandoc#VimPreviewPandocConvertTo(exts)
    python ConvertTo(vim.eval("a:exts"))
endfunction

python << EOF
import vim
import os
import sys
import base64
import subprocess
import time
import socket
import traceback
from xml.dom import minidom
import threading
import htmltreediff
import imp

try:
    imp.find_module('dbus')
    import dbus
    dbus_found = True
except ImportError:
    dbus_found = False

## Konqueror

def dbus_iface(dest, path, iface):
    bus = dbus.SessionBus()
    remote = bus.get_object(dest, path)
    return dbus.Interface(remote, iface)

def FindDest():
    names = dbus_iface("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus").ListNames()
    for i in names:
       if i.startswith("org.kde.konqueror"):
           xml = dbus_iface(i, "/", "org.freedesktop.DBus.Introspectable").Introspect()
           dom = minidom.parseString(xml)
           nodes = dom.getElementsByTagName("node")[0].getElementsByTagName("node")
           for node in nodes:
               if node.attributes["name"].value == "KHTML":
                   return i
    raise Exception("Konqueror not running")

def FindWidget(dest):
    xml = dbus_iface(dest, "/KHTML", "org.freedesktop.DBus.Introspectable").Introspect()
    dom = minidom.parseString(xml)
    nodes = dom.getElementsByTagName("node")[0].getElementsByTagName("node")
    for node in nodes:
        i = node.attributes["name"].value
        xml = dbus_iface(dest, "/KHTML/%s" % i, "org.freedesktop.DBus.Introspectable").Introspect()
        dom = minidom.parseString(xml)
        nodes = dom.getElementsByTagName("node")[0].getElementsByTagName("node")
        for node in nodes:
            if node.attributes["name"].value == "widget":
                return i
    return False

def OpenUrl(dest, path):
    dbus_iface(dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow").openUrl(path, False)

def CurrentUrl(dest):
    location = EvalJS(dest, "window.location.href")
    return location

def EvalJS(dest, js):
    widget = FindWidget(dest)
    return dbus_iface(dest, "/KHTML/%s/widget" % widget, "org.kde.KHTMLPart").evalJS(js)

#################

def konqueror_output(swd, data):
    if (dbus_found != True):
       raise
    curr = os.path.realpath( \
              os.path.join(swd, \
                 "static", "index.html"))
    dest = FindDest()
    if CurrentUrl(dest) != "file://" + curr:
        OpenUrl(dest, curr)
        time.sleep(1)
    EvalJS(dest, data)

## Firefox

def firefox_output(swd, data):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 32000))
    s.send(data)
    data = s.recv(2048)
    s.close()

## Common

def output(swd, data):
    try:
        konqueror_output(swd, data)
    except Exception as e:
        # print("Konqueror failed", e)
        try:
            firefox_output(swd, data)
        except Exception as e:
            # print("Firefox failed", e)
            pass

def escape(data):
    return base64.b64encode(data.encode("utf8"))

#################

def get_swd():
    swd = os.path.dirname(os.path.abspath(vim.eval("s:path")))
    return swd

def ScrollTo():
    F, W, C = FindPosition()
    # print(F, W, C)
    if F:
        W = base64.b64encode(W)
        output(get_swd(), "setCursor('" + W + "', " + str(C) + ")")

def FindPosition():
    wordUnderCursor = vim.eval("expand('<cword>')")
    if len(wordUnderCursor) >= 3:
        cb = vim.current.buffer
        (row, col) = vim.current.window.cursor
        count = 0
        inBlock = False
        for i in xrange(0, row):
            line = cb[i]
            if line[0:3] == '```':
                if inBlock:
                    inBlock = not inBlock
                elif line[0:6] == '```dot' \
                    or line[0:4] == '```R' \
                    or line[0:11] == '```plantuml' \
                    or line[0:12] == '```blockdiag' \
                    or line[0:10] == '```seqdiag' \
                    or line[0:10] == '```actdiag' \
                    or line[0:9] == '```nwdiag':
                    inBlock = True
            if i == row - 1:                # last line?
                if inBlock:                 #  in a block?
                    return False, "", 0     #   not found
                line = line[0:col]          #  limit line to cursor's position column
            else:
                if inBlock:                 #  in a block?
                    continue                #   skip the line
            if i + 1 < row \
                and cb[i+1].count("{.bookmark") \
                and cb[i+1][0] == "#":              # next line follows?
                                                    # is that line a bookmark?
                continue                            #  skip current line
            count += line.count(wordUnderCursor)
        # add a one because the cursor's position column always trims the
        # word under cursor so it won't be found with line.count(...)
        count += 1
        return True, wordUnderCursor, count
    else:
        return False, "", 0

# The realpath.py filter must be last!
def get_filters(swd):
    return [ "--filter="+swd+"/graphviz.py" \
           , "--filter="+swd+"/blockdiag.py" \
           , "--filter="+swd+"/R.py" \
           , "--filter="+swd+"/plantuml.py" \
           , "--filter="+swd+"/realpath.py" ]

def pandoc(cwd, swd, buffer):
    swd = os.path.join(swd, "plugin")
    cmd = ["pandoc"] + get_filters(swd) + ["--number-section"]
    p = subprocess.Popen(cmd, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, \
            close_fds=True, cwd=cwd)
    for l in buffer:
        p.stdin.write(l)
        p.stdin.write("\n")
    p.stdin.close()
    data = p.stdout.read().decode("utf8")
    error = p.stderr.read()
    sys.stderr.write(error)

    return data

class PreviewThread(threading.Thread):
    def __init__(self, buffer, swd, cwd):
        threading.Thread.__init__(self)
        self.buffer = []
        for i in xrange(0, len(buffer)):
            self.buffer.append(buffer[i])
        self.su = None
        self.cwd = cwd
        self.swd = swd
        if subprocess.mswindows:
            self.su = subprocess.STARTUPINFO()
            self.su.dwFlags |= subprocess._subprocess.STARTF_USESHOWWINDOW
            self.su.wShowWindow = subprocess._subprocess.SW_HIDE

    def run(self):
        html = pandoc(self.cwd, self.swd, self.buffer)
        output(self.swd, "setOutput('" + escape(html) + "')")

def Preview():
    thread = PreviewThread(vim.current.buffer \
                          , get_swd() \
                          , os.path.dirname(os.path.abspath(vim.eval("expand('%p')"))))
    thread.start()

def git_show(cwd, filename, rev):
    cmd = ["git" \
          , "show" \
          , rev + ":" + filename]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
            stderr=None, close_fds=True, cwd=cwd)
    return p.stdout.read()

def Diff(filename, fr, to):
    try:
        swd = get_swd()
        cwd = os.path.dirname(os.path.abspath(filename))
        old = git_show(cwd, filename, fr)
        old = old.split("\n")
        old = pandoc(cwd, swd, old)
        new = git_show(cwd, filename, to)
        new = new.split("\n")
        new = pandoc(cwd, swd, new)
        diff = htmltreediff.html.diff(old, new)
        output(swd, "setOutput('" + escape(diff) + "')")
        print("Done!")
    except Exception as e:
        print("Diff failed", e)

def ConvertTo(exts):
    filename = os.path.abspath(vim.eval("expand('%p')"))
    cwd = os.path.dirname(filename)
    swd = os.path.join(get_swd(), "plugin")
    ps = []
    for ext in exts.split(","):
        cmd = ["pandoc"] +get_filters(swd) + \
              [filename, "-o" + filename + "." + ext]
        p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=None, \
                close_fds=True, cwd=cwd)
        ps.append(p)
    for p in ps:
        p.wait()
EOF

else

echoerr "VimPreviewPandoc: Python support required!"

endif
