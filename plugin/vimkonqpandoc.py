#!/usr/bin/env python2

import os
import sys
import base64
import subprocess
import dbus

def dbus_iface(dest, path, iface):
    bus = dbus.SessionBus()
    remote = bus.get_object(dest, path)
    return dbus.Interface(remote, iface)

def FindDest():
    names = dbus_iface("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus").ListNames()
    for i in names:
        if i.startswith("org.kde.konqueror"):
            return i
    raise "Konqueror not running"

def FindWidget(dest):
    for i in (1,2,3,4,5):
        try:
            widgets = dbus_iface(dest, "/KHTML/%d" % i, "org.freedesktop.DBus.Introspectable").Introspect()
            return i
        except:
            pass
    raise "Konqueror widget not found"

def OpenUrl(dest, path):
    dbus_iface(dest, "/konqueror/MainWindow_1", "org.kde.Konqueror.MainWindow").openUrl(path, False)

def CurrentUrl(dest):
    location = EvalJS(dest, "window.location.href")
    return location

def EvalJS(dest, js):
    widget = FindWidget(dest)
    return dbus_iface(dest, "/KHTML/%d/widget" % widget, "org.kde.KHTMLPart").evalJS(js)

cmd = ["pandoc", "--filter="+sys.argv[2]+"/graphviz.py", \
                 "--filter="+sys.argv[2]+"/realpath.py", \
       sys.argv[1]]
p = subprocess.Popen(cmd, shell=False, stdin=None, stdout=subprocess.PIPE, \
                     close_fds=True, cwd=sys.argv[3])
data = p.stdout.read()
os.remove(sys.argv[1])

curr = os.path.realpath(os.sys.argv[2] + "/../static/index.html")
dest = FindDest()
if CurrentUrl(dest) != "file://" + curr:
    OpenUrl(dest, curr)
EvalJS(dest, "setOutput('" + base64.b64encode(data) + "')")

