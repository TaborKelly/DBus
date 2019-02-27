//
//  WatchSource.swift
//  DBus
//
//  Created by Tabor Kelly on 2/27/19.
//  Copyright © 2019 Racepoint Energy LLC.
//  All rights reserved.
//

import Foundation
import CDBus

// It exists to bridge libdbus land to Swift land.
public class DBusWatchSource {
    var enabled = true // DispatchSourceRead/Write are very fragile
    let readerSource: DispatchSourceRead?
    let writerSource: DispatchSourceWrite?
    let watch: OpaquePointer?

    public init(dispatchQueue: DispatchQueue, watch: OpaquePointer?) {
        print("DBusWatchSource.init()")

        // libdbus is a little funky about watches. It will create one for reading and a seperate one for writing
        // per socket. Then it will toggle them independently, which almost makes sense. Almost.
        let flags = dbus_watch_get_flags(watch)

        self.watch = watch
        let fileDescriptor = dbus_watch_get_unix_fd(watch)

        if flags == DBUS_WATCH_READABLE.rawValue {
            readerSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor,
                                                         queue: dispatchQueue)
        } else {
            readerSource = nil
        }
        if flags == DBUS_WATCH_WRITABLE.rawValue {
            writerSource = DispatchSource.makeWriteSource(fileDescriptor: fileDescriptor,
                                                          queue: dispatchQueue)
        } else {
            writerSource = nil
        }
        readerSource?.setEventHandler(handler: self.handleRead)
        writerSource?.setEventHandler(handler: self.handleWrite)

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        dbus_watch_set_data(watch, data, nil)

        if dbus_watch_get_enabled(watch) == 0 {
            self.enabled = false
        } else {
            readerSource?.resume()
            writerSource?.resume()
        }
    }

    func toggle() {
        print("DBusWatchSource.toggle()")

        if dbus_watch_get_enabled(watch) == 0 {
            disable()
        } else {
            enable()
        }
    }

    private func enable() {
        print("DBusWatchSource.enable()")

        if enabled == false {
            readerSource?.resume()
            writerSource?.resume()
            enabled = true
        }
    }

    private func disable() {
        print("DBusWatchSource.disable()")
        if enabled == true {
            readerSource?.suspend()
            writerSource?.suspend()
            enabled = false
        }
    }

    private func handleRead() {
        print("DBusWatchSource.handleRead()")

        let b = dbus_watch_handle(watch, DBUS_WATCH_READABLE.rawValue)
        if b == 0 {
            print("DBusWatchSource.handleRead(): dbus_watch_handle() returned FALSE, disabling watch")
            disable()
        }
    }

    private func handleWrite() {
        print("DBusWatchSource.handleWrite()")

        let b = dbus_watch_handle(watch, DBUS_WATCH_WRITABLE.rawValue)
        if b == 0 {
            print("DBusWatchSource.handleWrite(): dbus_watch_handle() returned FALSE, disabling watch")
            disable()
        }
    }
}
