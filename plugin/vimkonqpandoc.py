#!/usr/bin/env python2

import os
import sys
import base64
import subprocess
import dbus
import time
from xml.dom import minidom

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
    raise "Konqueror not running"

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

def main():
    filterpath = os.path.dirname(os.path.abspath(__file__))
    projectpath = os.path.dirname(os.path.abspath(sys.argv[1]))

    cmd = ["pandoc", "--filter="+filterpath+"/graphviz.py", \
            "--filter="+filterpath+"/realpath.py", \
            sys.argv[1]]
    p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
            close_fds=True, cwd=projectpath)
    data = p.stdout.read()

    curr = os.path.realpath(filterpath + "/../static/index.html")
    dest = FindDest()
    if CurrentUrl(dest) != "file://" + curr:
        OpenUrl(dest, curr)
        time.sleep(1)
    EvalJS(dest, "setOutput('" + base64.b64encode(data) + "')")

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

