//
//  Manager.swift
//  DBus
//
//  Created by Tabor Kelly on 2/26/19.
//  All rights reserved.
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

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addWatch(watch: watch)
}

private func removeWatchFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeWatch(watch: watch)
}

private func watchToggledFunction(watch: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
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

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    return manager.addTimeout(timeout: timeout)
}

private func removeTimeoutFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.removeTimeout(timeout: timeout)
}

private func timeoutToggledFunction(timeout: OpaquePointer?, data: UnsafeMutableRawPointer?) {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    // Extract pointer to 'DBusManager' from void pointer:
    let manager = Unmanaged<DBusManager>.fromOpaque(p).takeUnretainedValue()
    manager.timeoutToggled(timeout: timeout)
}

/**
 * This class exists to make it easy for clients to interact with DBus. It has no analogy in libdbus, but includes
 * things like event loop integration for Swift.
 *
 * TODO: add support for system bus.
 */
public final class DBusManager {
    private static var manager: DBusManager?

    /**
     * Get the singleton DBusManager object. This may need to change when we add system bus support.
     */
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

    /// The DBus connection to send/receive messages on.
    public let connection: DBusConnection
    private let dispatchSource: DBusDispatchSource
    private let dispatchQueue: DispatchQueue
    private let signalFilter: DBusSignalFilter
    private var watches: [UnsafeMutableRawPointer:DBusWatchSource] = [:]
    private var timeouts: [UnsafeMutableRawPointer:DBusTimeoutSource] = [:]

    private init() throws {
        // our only DispatchQueue
        // TODO: add system bus support
        self.dispatchQueue = DispatchQueue(label: "com.racepointenergy.DBus.session", qos: .utility,
                                           attributes: []) // serial, because that's all we want
        self.connection = try DBusConnection(busType: .session)
        self.signalFilter = try DBusSignalFilter(connection: connection)
        self.dispatchSource = try DBusDispatchSource(connection: connection, dispatchQueue: dispatchQueue)

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

    /**
     Get a DBus property.

     - Parameters:
         - destination: The destination (probably a well known service name).
         - objectPath: The object path.
         - interface: The name of the DBus interface to query.
         - property: The property name to query.
     */
    public func getProperty(destination: String, objectPath: String,
                            interface: String, property: String) throws -> DBusMessage? {
        let message = try DBusMessage(destination: destination,
                                      path: objectPath,
                                      iface: "org.freedesktop.DBus.Properties",
                                      method: "Get")
        let encoder = DBusEncoder()
        try encoder.encode(interface, to: message, signature: "s")
        try encoder.encode(property, to: message, signature: "s")

        guard let r = try connection.sendWithReply(message: message) else {
            throw RuntimeError.generic("DBusManager.sendWithReply() failed!")
        }
        r.block()

        return r.replyMessage
    }

    /**
     Add a signal filter. This lets you get notified (acting as a client) when a server sends a signal.

     - Parameters:
         - interface: The name of the interface to listen for.
         - signal: The name of the signal that you wish to be notified about.
         - fn: The function to call when the signal occurs.
     */
    public func addSignalFilter(interface: String, signal: String, fn: @escaping SignalCall) throws {
        // This should be thread safe.
        try self.signalFilter.addFilter(interface: interface, signal: signal, fn: fn)
    }

    /**
     Create a new `DBusServerAdaptor` which will let you expose your Swift code so that it can be called over DBus.
     That is, it lets you act as a DBus Server.

     - Parameters:
         - objectPath: The object path that the `DBusServerAdaptor` represents.
     */
    public func newServerAdaptor(objectPath: String) throws -> DBusServerAdaptor {
        Log.entry("")

        return try DBusServerAdaptor(connection: self.connection, dispatchQueue: self.dispatchQueue,
                                     objectPath: objectPath)
    }

    //
    // From here down are internal implementation details that normal users of the library should not care about.
    //

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
