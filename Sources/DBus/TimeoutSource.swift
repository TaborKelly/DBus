//
//  TimerSource.swift
//  DBus
//
//  Created by Tabor Kelly on 2/27/19.
//  Copyright © 2019 Racepoint Energy LLC.
//  All rights reserved.
//

import Foundation
import CDBus

// It exists to bridge libdbus land to Swift land.
public class DBusTimeoutSource {
    var enabled = false // DispatchSourceTimer is very fragile
    let timerSource: DispatchSourceTimer
    let timeout: OpaquePointer?

    public init(dispatchQueue: DispatchQueue, timeout: OpaquePointer?) {
        print("DBusTimeoutSource.init()")

        self.timeout = timeout
        timerSource = DispatchSource.makeTimerSource(queue: dispatchQueue)
        timerSource.setEventHandler(handler: self.fire)

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        dbus_timeout_set_data(timeout, data, nil)

        if dbus_timeout_get_enabled(timeout) != 0 {
            toggle()
        }
    }

    func toggle() {
        print("DBusTimeoutSource.toggle()")

        if dbus_timeout_get_enabled(timeout) == 0 {
            disable()
        } else {
            enable()
        }
    }

    private func enable() {
        print("DBusTimeoutSource.enable()")

        if enabled == false {
            let intervalMilliseconds = dbus_timeout_get_interval(timeout)
            let interval = Double(intervalMilliseconds)/1000.0
            // WARNING: Some of Apple's dispatch sources are very fragile. I'm not 100% sure that this will work as
            // intended. That is, calling schedule more than once. We set this here because libdbus may disable the
            // timer and then re-enable it with a different timeout interval as per their documentation
            timerSource.schedule(deadline: .now() + interval, repeating: interval)
            timerSource.resume()
            enabled = true
        }
    }

    private func disable() {
        print("DBusTimeoutSource.disable()")
        if enabled == true {
            timerSource.suspend()
            enabled = false
        }
    }

    private func fire() {
        print("DBusTimeoutSource.fire()")

        let b = dbus_timeout_handle(timeout)
        if b == 0 {
            print("DBusTimeoutSource.fire(): dbus_timeout_handle() returned FALSE")
        }
    }
}
