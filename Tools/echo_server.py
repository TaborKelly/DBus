#!/usr/bin/env python3

# Based on http://stackoverflow.com/questions/22390064/use-dbus-to-just-send-a-message-in-python

# Python DBUS Test Server
# runs until the Quit() method is called via DBUS

from gi.repository import GLib
from pydbus import SessionBus
from pydbus.generic import signal

loop = GLib.MainLoop()

class EchoServer(object):
    """
        <node>
            <interface name='com.racepointenergy.DBus.EchoServer'>
                <method name='s'>
                    <arg type='s' name='s' direction='in'/>
                    <arg type='s' name='s' direction='out'/>
                </method>
                <method name='Quit'/>
                <signal name="foo">
                    <arg type='s' name='s' direction='out'/>
                </signal>
                <property name="propertyS" type="s" access="read"/>
            </interface>
        </node>
    """
    foo = signal()

    def __init__(self):
        self._propertyS = "foo"

    def s(self, s):
        print('s({})'.format(s))
        self.foo("foo signal {}".format(s))
        return s

    @property
    def propertyS(self):
        return self._propertyS

bus = SessionBus()
bus.publish("com.racepointenergy.DBus.EchoServer", EchoServer())
loop.run()
