//
//  Manager.swift
//  DBus
//
//  Created by Tabor Kelly on 2/26/19.
//

import Foundation
import CDBus
import LoggerAPI

/**
 * This class exists to make it easy for clients to interact with DBus. It has no analogy in libdbus, but includes
 * things like event loop integration for Swift.
 */
public final class DBusManager {
    /// The DBus connection to send/receive messages on.
    public let connection: DBusConnection
    // DBusDispatchSource manages half of our event loop integration
    private let dispatchSource: DBusDispatchSource
    private let signalFilter: DBusSignalFilter
    // DBusSuperManager manages the other half of the event loop integration
    private let superManager: DBusSuperManager

    /**
     * Initialize a new DBusManager. This will take care of Swift event loop integration and thread safety.
     *
     * TODO: revisit. What happens if we free this DBusManager?
     *
     * - Parameters:
     *     - busType: The type of bus to connect to.
     */
    public init(busType: DBusBusType = .session) throws {
        self.superManager = try DBusSuperManager.getSuperManager()
        self.connection = try DBusConnection(busType: busType)
        try self.superManager.setupConnection(connection: self.connection)
        self.dispatchSource = try DBusDispatchSource(connection: connection, dispatchQueue: superManager.dispatchQueue)

        self.signalFilter = try DBusSignalFilter(connection: connection)

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

        return try DBusServerAdaptor(connection: self.connection, dispatchQueue: self.superManager.dispatchQueue,
                                     objectPath: objectPath)
    }
}
