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
            </interface>
        </node>
    """

    foo = signal()

    def s(self, s):
        print('s({})'.format(s))
        self.foo("foo signal {}".format(s))
        return s

bus = SessionBus()
bus.publish("com.racepointenergy.DBus.EchoServer", EchoServer())
loop.run()
