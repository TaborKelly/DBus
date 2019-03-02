//
//  Filter.swift
//  DBus
//
//  Created by Tabor Kelly on 3/1/19.
//  Copyright © 2019 Racepoint Energy LLC.
//  All rights reserved.
//

import Foundation
import CDBus

public struct SignalFilter {
    let interface: String
    let signalName: String
    // This will run on the DBusManager dispatch queue. Don't block it, or you will block all of your DBus
    // messages.
    let fn: (DBusMessage) -> ()

    public init(interface: String, signalName: String, fn: @escaping (DBusMessage) -> ()) {
        self.interface = interface
        self.signalName = signalName
        self.fn = fn
    }
}

private func handleMessageFunction(connection: OpaquePointer?, // DBusConnection *connection
                                   message: OpaquePointer?, // DBusMessage *message
                                   data: UnsafeMutableRawPointer?) -> CDBus.DBusHandlerResult {
    print("handleMessageFunction()")

    guard let p = data else {
        // This should never happen
        print("ERROR: handleMessageFunction() got a nil data!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }

    guard let m = message else {
        // This should never happen
        print("ERROR: handleMessageFunction() got a nil message!")
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
    }

    let message = DBusMessage(m)

    // Extract pointer to 'DBusFilter' from void pointer:
    let filter = Unmanaged<DBusFilter>.fromOpaque(p).takeUnretainedValue()
    return filter.handleMessage(message: message)
}

// This exists to bridge libdbus land to Swift land, particularly for signals for the time being.
public class DBusFilter {
    let connection: DBusConnection
    var filters: [SignalFilter] = []

    init(connection: DBusConnection) throws {
        print("DBusFilter.init()")

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

    public func addFilter(_ sf: SignalFilter) throws {
        let error = DBusError()
        dbus_bus_add_match(connection.internalPointer,
                           "type='signal',interface='\(sf.interface)',member='\(sf.signalName)'",
                           &error.cError)
        if error.isSet {
            throw error
        }
        filters.append(sf)
    }

    func handleMessage(message: DBusMessage) -> CDBus.DBusHandlerResult {
        print("DBusFilter.handleMessage(\(message))")

        // right now, we only care about signals, so short circuit for anything else
        let t = dbus_message_get_type(message.internalPointer)
        if t != DBUS_MESSAGE_TYPE_SIGNAL {
            return DBUS_HANDLER_RESULT_NOT_YET_HANDLED
        }

        // loop through all of our filters
        for f in filters {
            // if we find one that matches
            let b = Bool(dbus_message_is_signal(message.internalPointer,
                                                f.interface,
                                                f.signalName))
            if b == true {
                // then call it
                f.fn(message)
            }
        }

        return DBUS_HANDLER_RESULT_HANDLED // for our implementation, this seems right?
    }
}
