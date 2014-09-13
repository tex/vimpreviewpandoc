#!/usr/bin/env python2

import os
import sys
import base64
import subprocess
import dbus
import time
import socket
from xml.dom import minidom
import htmltreediff
import traceback

FILTER_PATH = os.path.dirname(os.path.abspath(__file__))

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

def konqueror_output(data):
    curr = os.path.realpath(FILTER_PATH + "/../static/index.html")
    dest = FindDest()
    if CurrentUrl(dest) != "file://" + curr:
        OpenUrl(dest, curr)
        time.sleep(1)
    EvalJS(dest, "setOutput('" + base64.b64encode(data) + "')")

## Firefox

def firefox_output(data):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 32000))
    s.send("setOutput('" + base64.b64encode(data) + "')")
    data = s.recv(2048)
    s.close()

## Common

def try_output(data):
    try:
        konqueror_output(data)
    except Exception:
        try:
            firefox_output(data)
        except Exception:
            pass

def pandoc(cwdpath, filename):
    cmd = ["pandoc" \
          , "--filter="+FILTER_PATH+"/graphviz.py" \
          , "--filter="+FILTER_PATH+"/blockdiag.py" \
          , "--filter="+FILTER_PATH+"/realpath.py" \
          , "--number-section"
          , "--ascii"
          , filename]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
            close_fds=True, cwd=cwdpath)
    data = p.stdout.read()
    return data

def main():
    try:
        cwdpath = os.path.dirname(os.path.abspath(sys.argv[2]))
        newfilename = sys.argv[1]
        oldfilename = sys.argv[2]

        # Diff html
        tn = pandoc(cwdpath, newfilename)
        to = pandoc(cwdpath, oldfilename)
        diff = htmltreediff.diff(to, tn)

        try_output(diff);

        # Generate Microsoft Word docx document
        cmd = ["pandoc" \
              , "--filter="+FILTER_PATH+"/graphviz.py" \
              , "--filter="+FILTER_PATH+"/blockdiag.py" \
              , "--filter="+FILTER_PATH+"/realpath.py" \
              , newfilename \
              , "-o" + oldfilename + ".docx"]
        p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=None, \
                close_fds=True, cwd=cwdpath)
        p.wait()

        os.remove(sys.argv[1])

    except Exception as e:
        try_output(
                "<h1>Fatal error</h1>" + "<h2>vimpreviewpandoc.py</h2>" +
                "<p>" + traceback.format_exc() + "</p>")

if __name__ == "__main__":
    main()

