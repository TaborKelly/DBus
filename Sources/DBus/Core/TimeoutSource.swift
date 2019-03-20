//
//  TimerSource.swift
//  DBus
//
//  Created by Tabor Kelly on 2/27/19.
//  All rights reserved.
//

import Foundation
import CDBus
import LoggerAPI

// It exists to bridge libdbus land to Swift land.
public class DBusTimeoutSource {
    var enabled = false // DispatchSourceTimer is very fragile
    let timerSource: DispatchSourceTimer
    let timeout: OpaquePointer?

    public init(dispatchQueue: DispatchQueue, timeout: OpaquePointer?) {
        Log.entry("")

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

    func remove() {
        disable()
        // WARNING: I'm not sure this is enough to have the DispatchSourceTimer removed from the DispatchQueue
        timerSource.cancel()
    }

    func toggle() {
        Log.entry("\(String(describing: timeout))")

        if dbus_timeout_get_enabled(timeout) == 0 {
            disable()
        } else {
            enable()
        }
    }

    private func enable() {
        Log.entry("\(String(describing: timeout))")

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
        Log.entry("\(String(describing: timeout))")
        if enabled == true {
            timerSource.suspend()
            enabled = false
        }
    }

    private func fire() {
        Log.entry("\(String(describing: timeout))")

        let b = dbus_timeout_handle(timeout)
        if b == 0 {
            Log.error("dbus_timeout_handle() returned FALSE")
        }
    }
}
