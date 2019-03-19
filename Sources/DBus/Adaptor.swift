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
    let adaptor = Unmanaged<Adaptor>.fromOpaque(p).takeUnretainedValue()
    return adaptor.objectPathMessage(message)
}

/**
 This is how the Adaptor will call you back with messages. The `DBusMessage` is the message from the client. The
 `DBusConnection` is passed as a convience in case you wish to use it to send a signal. If you return a `DBusMessage` it
 will be sent as a reply to the client. You will be called on the `DBusManager` dispatch queue, so don't block.
 */
public typealias AdaptorCall = (DBusMessage, DBusConnection) -> (DBusMessage?)

/**
 This Adaptor lets you expose your Swift code so that it can be called over DBus. That is, it lets you act as a DBus
 Server. Named adaptor vs adapter to match Qt as well as the sometimes used style that an adapter is a person and an
 adaptor is a thing.
 */
public class Adaptor {
    private var connection: DBusConnection
    // The outermost String is the name of the interface, the inner string is the name of the method.
    private var interfaces: [String: [String: AdaptorCall]] = [:]
    private var path: String
    private var vtable: DBusObjectPathVTable

    init(connection: DBusConnection, objectPath: String) throws {
        Log.entry("")

        self.connection = connection
        self.path = objectPath
        self.vtable = DBusObjectPathVTable()
        self.vtable.message_function = objectPathMessageFunction

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let error = DBusError()
        let b = Bool(dbus_connection_try_register_object_path(self.connection.internalPointer, self.path, &self.vtable,
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
     - Parameters:
         - interface: DBus interface name to register fn for.
         - member: The member name to register fn for.
         - fn: The function to call when this interface + member is called
     */
    public func addMethod(interface: String, member: String, fn: @escaping AdaptorCall) {
        if var i = self.interfaces[interface] {
            i[member] = fn
            self.interfaces[interface] = i
        } else {
            self.interfaces[interface] = [member: fn]
        }
    }

    func objectPathMessage(_ message: DBusMessage) -> CDBus.DBusHandlerResult {
        Log.entry("")

        if message.type != .methodCall {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let i = self.interfaces[message.getInterface()] else {
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
