//
//  Adaptor.swift
//
//  Created by Tabor Kelly on 3/18/19.
//

import Foundation
import CDBus
import LoggerAPI

// Called for C land when we get a new message for a server object
private func objectPathMessageFunction(connection: OpaquePointer?, message: OpaquePointer?,
                                       data: UnsafeMutableRawPointer?) -> CDBus.DBusHandlerResult {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("objectPathMessageFunction() got a nil data!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }

    guard let m = message else {
        // This should never happen
        Log.error("objectPathMessageFunction() got a nil message!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }
    let message = DBusMessage(m)

    // Extract pointer to 'Adaptor' from void pointer:
    let adaptor = Unmanaged<DBusServerAdaptor>.fromOpaque(p).takeUnretainedValue()
    return adaptor.objectPathMessage(message)
}

/**
 This is how the `DBusServerAdaptor` will call you back with messages. The `DBusMessage` is the message from the client.
 The `DBusConnection` is passed as a convience in case you wish to use it to send a signal. If you return a
 `DBusMessage` it will be sent as a reply to the client. You will be called on the `DBusManager` dispatch queue, so
 don't block.
 */
public typealias AdaptorCall = (DBusMessage, DBusConnection) -> (DBusMessage?)

/**
 This ServerAdaptor lets you expose your Swift code so that it can be called over DBus. That is, it lets you act as a
 DBus Server. Named adaptor vs adapter to match Qt as well as the sometimes used style that an adapter is a person and
 an adaptor is a thing.
 */
public class DBusServerAdaptor {
    private var connection: DBusConnection
    private var dispatchQueue: DispatchQueue
    // The outermost String is the name of the interface, the inner string is the name of the method.
    private var interfaces: [String: [String: AdaptorCall]] = [:]
    private var path: String
    private var vtable: DBusObjectPathVTable

    init(connection: DBusConnection, dispatchQueue: DispatchQueue, objectPath: String) throws {
        Log.entry("")

        // This attempts to make libdbus somewhat thread safe, but it is only really for connection related stuff, and
        // not for Messages or Dispatch. We very carefully dispatch from a single threaded event loop.
        var b = Bool(dbus_threads_init_default())
        if b == false {
            throw RuntimeError.generic("dbus_threads_init_default() failed")
        }

        self.connection = connection
        self.dispatchQueue = dispatchQueue
        self.path = objectPath
        self.vtable = DBusObjectPathVTable()
        self.vtable.message_function = objectPathMessageFunction

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let error = DBusError()
        b = Bool(dbus_connection_try_register_object_path(self.connection.internalPointer, self.path, &self.vtable,
                                                          data, &error.cError))
        if b == false && error.isSet {
            throw error
        }
    }

    deinit {
        Log.entry("")

        let b = Bool(dbus_connection_unregister_object_path(self.connection.internalPointer, self.path))
        if b == false {
            Log.error("dbus_connection_unregister_object_path() failed for \(self.path)")
        }
    }

    /**
     Add a method to the ServerAdaptor. This runs on the DBusManager DispatchQueue, so don't call it from a callback on
     the DBusManager DispatchQueue or you will deadlock.

     - Parameters:
         - interface: DBus interface name to register fn for.
         - member: The member name to register fn for.
         - fn: The function to call when this interface + member is called
     */
    public func addMethod(interface: String, member: String, fn: @escaping AdaptorCall) {
        self.dispatchQueue.sync(flags: .barrier) { [weak self] in
            guard let s = self else {
                Log.error("couldn't get self!")
                return
            }

            if var i = s.interfaces[interface] {
                i[member] = fn
                s.interfaces[interface] = i
            } else {
                s.interfaces[interface] = [member: fn]
            }
        } // dispatchQueue.sync()
    }

    func objectPathMessage(_ message: DBusMessage) -> CDBus.DBusHandlerResult {
        Log.entry("")

        if message.type != .methodCall {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let interface = message.interface else {
            // This should never happen
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let i = self.interfaces[interface] else {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let fn = i[message.getMember()] else {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        if let reply = fn(message, self.connection) {
            do {
                let _ = try self.connection.send(message: reply)
            } catch {
                Log.error("self.connection.send(message: reply) failed.")
            }
        }

        return DBUS_HANDLER_RESULT_HANDLED // for the time being this should be good enough?
    }
}
