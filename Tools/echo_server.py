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
                <method name='y'>
                    <arg type='y' name='value' direction='in'/>
                    <arg type='y' name='value' direction='out'/>
                </method>
                <method name='b'>
                    <arg type='b' name='value' direction='in'/>
                    <arg type='b' name='value' direction='out'/>
                </method>
                <method name='n'>
                    <arg type='n' name='value' direction='in'/>
                    <arg type='n' name='value' direction='out'/>
                </method>
                <method name='i'>
                    <arg type='i' name='value' direction='in'/>
                    <arg type='i' name='value' direction='out'/>
                </method>
                <method name='u'>
                    <arg type='u' name='value' direction='in'/>
                    <arg type='u' name='value' direction='out'/>
                </method>
                <method name='x'>
                    <arg type='x' name='value' direction='in'/>
                    <arg type='x' name='value' direction='out'/>
                </method>
                <method name='t'>
                    <arg type='t' name='value' direction='in'/>
                    <arg type='t' name='value' direction='out'/>
                </method>
                <method name='d'>
                    <arg type='d' name='value' direction='in'/>
                    <arg type='d' name='value' direction='out'/>
                </method>
                <method name='s'>
                    <arg type='s' name='value' direction='in'/>
                    <arg type='s' name='value' direction='out'/>
                </method>
                <method name='ay'>
                    <arg type='ay' name='value' direction='in'/>
                    <arg type='ay' name='value' direction='out'/>
                </method>
                <method name='array_s'>
                    <arg type='as' name='value' direction='in'/>
                    <arg type='as' name='value' direction='out'/>
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

    #
    # Basic types
    #

    def y(self, value):
        print('y({})'.format(value))
        return value

    def b(self, value):
        print('b({})'.format(value))
        return value

    def n(self, value):
        print('n({})'.format(value))
        return value

    def i(self, value):
        print('i({})'.format(value))
        return value

    def u(self, value):
        print('u({})'.format(value))
        return value

    def x(self, value):
        print('x({})'.format(value))
        return value

    def t(self, value):
        print('t({})'.format(value))
        return value

    def d(self, value):
        print('d({})'.format(value))
        return value

    #
    # String types
    #

    def s(self, value):
        print('s({})'.format(value))
        self.foo("foo signal {}".format(value))
        return value

    #
    # Container types
    #
    def ay(self, value):
        print('ay({})'.format(value))
        return value

    def array_s(self, value):
        print('array_s({})'.format(value))
        return value

    @property
    def propertyS(self):
        return self._propertyS

bus = SessionBus()
bus.publish("com.racepointenergy.DBus.EchoServer", EchoServer())
loop.run()
