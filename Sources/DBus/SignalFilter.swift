//
//  Filter.swift
//  DBus
//
//  Created by Tabor Kelly on 3/1/19.
//  All rights reserved.
//

import Foundation
import CDBus
import LoggerAPI

/**
 This is how the `DBusSignalFilter` will call you back with messages. The `DBusMessage` is the signal from the server.
 You will be called on the `DBusManager` dispatch queue, so don't block.
 */
public typealias SignalCall = (DBusMessage) -> ()

private func handleMessageFunction(connection: OpaquePointer?, // DBusConnection *connection
                                   message: OpaquePointer?, // DBusMessage *message
                                   data: UnsafeMutableRawPointer?) -> CDBus.DBusHandlerResult {
    Log.entry("")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }

    guard let m = message else {
        // This should never happen
        Log.error("got a nil message!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }

    let message = DBusMessage(m)

    // Extract pointer to 'DBusFilter' from void pointer:
    let filter = Unmanaged<DBusSignalFilter>.fromOpaque(p).takeUnretainedValue()
    return filter.handleMessage(message: message)
}

/**
 A class that lets you listen for DBus signals. That is, recieve DBus signals when you are a client.
 */
public class DBusSignalFilter {
    private let connection: DBusConnection
    private var filters: [String: [String: SignalCall]] = [:]

    init(connection: DBusConnection) throws {
        Log.entry("")

        self.connection = connection

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let b = Bool(dbus_connection_add_filter(connection.internalPointer,
                                                handleMessageFunction,
                                                data,
                                                nil))
        if (b == false) {
            throw RuntimeError.generic("DBusFilter(): dbus_connection_add_filter() failed")
        }
    }

    func addFilter(interface: String, signal: String, fn: @escaping SignalCall) throws {
        let error = DBusError()
        dbus_bus_add_match(connection.internalPointer,
                           "type='signal',interface='\(interface)',member='\(signal)'",
                           &error.cError)
        if error.isSet {
            throw error
        }
        if var i = self.filters[interface] {
            i[signal] = fn
            self.filters[interface] = i
        } else {
            self.filters[interface] = [signal: fn]
        }
    }

    func handleMessage(message: DBusMessage) -> CDBus.DBusHandlerResult {
        Log.entry("\(message)")

        // right now, we only care about signals, so short circuit for anything else
        let t = dbus_message_get_type(message.internalPointer)
        if t != DBUS_MESSAGE_TYPE_SIGNAL {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let i = self.filters[message.getInterface()] else {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        guard let fn = i[message.getMember()] else {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        fn(message)

        return DBUS_HANDLER_RESULT_HANDLED // for our implementation, this seems right?
    }
}
