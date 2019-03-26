//
//  SuperManager.swift
//  DBus
//
//  Created by Tabor Kelly on 3/26/19.
//

import Foundation
import CDBus
import LoggerAPI

private func addWatchFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) -> dbus_bool_t {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return 0 // TODO: Bool?
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addWatch(watch: watch)
}

private func removeWatchFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeWatch(watch: watch)
}

private func watchToggledFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    manager.watchToggled(watch: watch)
}

// dbus_bool_t(* DBusAddTimeoutFunction) (DBusTimeout *timeout, void *data)
private func addTimeoutFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) -> dbus_bool_t {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return 0
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addTimeout(timeout: timeout)
}

private func removeTimeoutFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeTimeout(timeout: timeout)
}

private func timeoutToggledFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusSuperManager' from void pointer:
    let manager = Unmanaged<DBusSuperManager>.fromOpaque(p).takeUnretainedValue()
    manager.timeoutToggled(timeout: timeout)
}

// DBus users should never need to know about this
//
// TODO: figure out removing connections?
final class DBusSuperManager {
    private static var superManager: DBusSuperManager?

    /**
     * Get the singleton DBusManager object. This may need to change when we add system bus support.
     */
    public class func getSuperManager() throws -> DBusSuperManager {
        if superManager == nil {
            try DispatchQueue.global().sync(flags: .barrier) {
                if superManager == nil {
                    superManager = try DBusSuperManager()
                }
            }
        }

        return superManager!
    }

    let dispatchQueue: DispatchQueue // Internal, so that DBusManager can use it
    private var watches: [UnsafeMutableRawPointer:DBusWatchSource] = [:]
    private var timeouts: [UnsafeMutableRawPointer:DBusTimeoutSource] = [:]

    private init() throws {
        // our only DispatchQueue
        self.dispatchQueue = DispatchQueue(label: "com.racepointenergy.DBus.SuperManager", qos: .utility,
                                           attributes: []) // serial, because that's all we want

        // This attempts to make libdbus somewhat thread safe, but it is only really for connection related stuff, and
        // not for Messages or Dispatch. We very carefully dispatch from a single threaded event loop.
        let b = Bool(dbus_threads_init_default())
        if b == false {
            throw RuntimeError.generic("dbus_threads_init_default() failed")
        }
    }

    func setupConnection(connection: DBusConnection) throws {
        Log.entry("")

        // Grab an UnsafeMutableRawPointer to self so that we can pass it into C land
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
    }

    func addWatch(watch: OpaquePointer?) -> dbus_bool_t {
        Log.entry("")

        let w = DBusWatchSource(dispatchQueue: dispatchQueue, watch: watch)
        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            Log.error("dbus_watch_get_data() failed!")
            return 0
        }
        watches[p] = w

        return 1 // success
    }

    func removeWatch(watch: OpaquePointer?) {
        Log.entry("")

        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            Log.error("dbus_watch_get_data() failed!")
            return
        }
        watches[p] = nil
    }

    func watchToggled(watch: OpaquePointer?) {
        Log.entry("")

        guard let p = dbus_watch_get_data(watch) else {
            // This should never happen
            Log.error("dbus_watch_get_data() failed!")
            return
        }

        guard let watchObject = watches[p] else {
            Log.error("failed to find watch!")
            return
        }

        watchObject.toggle()
    }

    func addTimeout(timeout: OpaquePointer?) -> dbus_bool_t {
        Log.entry("\(String(describing: timeout))")

        let t = DBusTimeoutSource(dispatchQueue: dispatchQueue, timeout: timeout)
        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            Log.error("dbus_timeout_get_data() failed!")
            return 0
        }
        timeouts[p] = t

        return 1 // success
    }

    func removeTimeout(timeout: OpaquePointer?) {
        Log.entry("\(String(describing: timeout))")

        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            Log.error("dbus_timeout_get_data() failed!")
            return
        }

        guard let timeoutSource = timeouts[p] else {
            Log.error("failed to find timeout!")
            return
        }
        timeoutSource.remove()

        timeouts[p] = nil
    }

    func timeoutToggled(timeout: OpaquePointer?) {
        Log.entry("\(String(describing: timeout))")

        guard let p = dbus_timeout_get_data(timeout) else {
            // This should never happen
            Log.error("dbus_timeout_get_data() failed!")
            return
        }

        guard let timeoutSource = timeouts[p] else {
            Log.error("failed to find watch!")
            return
        }

        timeoutSource.toggle()
    }
}
