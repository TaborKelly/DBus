//
//  Manager.swift
//  DBus
//
//  Created by Tabor Kelly on 2/26/19.
//  Copyright © 2019 Racepoint Energy LLC.
//  All rights reserved.
//

import Foundation
import CDBus

private func addWatchFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) -> dbus_bool_t {
    print("addWatchFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: addWatchFunction() got a nil data!")
        return 0 // TODO: Bool?
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addWatch(watch: watch)
}

private func removeWatchFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    print("removeWatchFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: addWatchFunction() got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeWatch(watch: watch)
}

private func watchToggledFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    print("watchToggledFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: addWatchFunction() got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.watchToggled(watch: watch)
}

// dbus_bool_t(* DBusAddTimeoutFunction) (DBusTimeout *timeout, void *data)
private func addTimeoutFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) -> dbus_bool_t {
    print("addTimeoutFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: addTimeoutFunction() got a nil data!")
        return 0
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addTimeout(timeout: timeout)
}

private func removeTimeoutFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    print("removeTimeoutFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: removeTimeoutFunction() got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeTimeout(timeout: timeout)
}

private func timeoutToggledFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    print("timeoutToggledFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: timeoutToggledFunction() got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.timeoutToggled(timeout: timeout)
}

// This class has no analog in libdbus. It exists to integrate libdbus with the Swift Dispatch Queues.
public final class DBusManager {
    private static var manager: DBusManager?

    // Get the singleton manager object
    public class func getManager() throws -> DBusManager {
        if manager == nil {
            try DispatchQueue.global().sync(flags: .barrier) {
                if manager == nil {
                    manager = try DBusManager()
                }
            }
        }

        return manager!
    }

    public let connection: DBusConnection
    private let dispatchSource: DBusDispatchSource
    private let dispatchQueue: DispatchQueue
    private var watches: [UnsafeMutableRawPointer:DBusWatchSource] = [:]
    private var timeouts: [UnsafeMutableRawPointer:DBusTimeoutSource] = [:]

    private init() throws {
        // our only DispatchQueue
        // TODO: add system bus support
        dispatchQueue = DispatchQueue(label: "com.racepointenergy.DBus.session", qos: .utility,
                                      attributes: []) // serial, because that's all we want
        connection = try DBusConnection(busType: .session)
        dispatchSource = try DBusDispatchSource(connection: connection, dispatchQueue: dispatchQueue)

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var b = Bool(dbus_connection_set_watch_functions(connection.internalPointer, addWatchFunction,
                                                         removeWatchFunction, watchToggledFunction, data, nil))
        if (b == false) {
            throw RuntimeError.generic("DispatchSource(): dbus_connection_set_watch_functions() failed")
        }

        b = Bool(dbus_connection_set_timeout_functions(connection.internalPointer,
                                                      addTimeoutFunction,
                                                      removeTimeoutFunction,
                                                      timeoutToggledFunction,
                                                      data, nil))
        if (b == false) {
            throw RuntimeError.generic("DispatchSource(): dbus_connection_set_timeout_functions() failed")
        }

        // libdbus is a little crufty. Now that we have set everything up, kick it if we have data remaining
        let status = dbus_connection_get_dispatch_status(connection.internalPointer)
        if status == DBUS_DISPATCH_DATA_REMAINS {
            dispatchSource.dispatchStatus(newStatus: .dataRemains)
        }
    }

    func addWatch(watch: OpaquePointer?) -> dbus_bool_t {
        print("DBusManager.addWatch()")

        let w = DBusWatchSource(dispatchQueue: dispatchQueue, watch: watch)
        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            print("DBusManager.addWatch(): dbus_watch_get_data() failed!")
            return 0
        }
        watches[p] = w

        return 1 // success
    }

    func removeWatch(watch: OpaquePointer?) {
        print("DBusManager.removeWatch()")

        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            print("DBusManager.removeWatch(): dbus_watch_get_data() failed!")
            return
        }
        watches[p] = nil
    }

    func watchToggled(watch: OpaquePointer?) {
        print("DBusManager.watchToggled()")

        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            print("DBusManager.watchToggled(): dbus_watch_get_data() failed!")
            return
        }

        guard let watchObject = watches[p] else {
            print("DBusManager.watchToggled(): failed to find watch!")
            return
        }

        watchObject.toggle()
    }

    func addTimeout(timeout: OpaquePointer?) -> dbus_bool_t {
        print("addTimeout()")

        let t = DBusTimeoutSource(dispatchQueue: dispatchQueue, timeout: timeout)
        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            print("DBusManager.addWatch(): dbus_timeout_get_data() failed!")
            return 0
        }
        timeouts[p] = t

        return 1 // success
    }

    func removeTimeout(timeout: OpaquePointer?) {
        print("DBusManager.removeTimeout()")

        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            print("DBusManager.removeTimeout(): dbus_timeout_get_data() failed!")
            return
        }
        timeouts[p] = nil
    }

    func timeoutToggled(timeout: OpaquePointer?) {
        print("DBusManager.timeoutToggled()")

        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            print("DBusManager.timeoutToggled(): dbus_timeout_get_data() failed!")
            return
        }

        guard let timeoutObject = timeouts[p] else {
            print("DBusManager.timeoutToggled(): failed to find watch!")
            return
        }

        timeoutObject.toggle()
    }
}
