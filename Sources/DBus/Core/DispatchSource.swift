//
//  DispatchSource.swift
//  DBus
//
//  Created by Tabor Kelly on 2/26/19.
//  All rights reserved.
//

import Foundation
import CDBus
import LoggerAPI

// This gets called back from C land in libdbus.
// As per the documentation:
//     If the dispatch status is DBUS_DISPATCH_DATA_REMAINS, then dbus_connection_dispatch() needs to be called to
//     process incoming messages. However, dbus_connection_dispatch() MUST NOT BE CALLED from inside the
//     DBusDispatchStatusFunction. Indeed, almost any reentrancy in this function is a bad idea. Instead, the
//     DBusDispatchStatusFunction should simply save an indication that messages should be dispatched later, when the
//     main loop is re-entered.
//
// So, we we write the status to a pipe that we read once we are out of the callback context
private func dispatchStatusFunction(connection: OpaquePointer?, new_status: CDBus.DBusDispatchStatus,
                                    data: UnsafeMutableRawPointer?) {
    Log.entry("(\(String(describing: connection)), \(new_status), \(String(describing: data)))")

    guard let p = data else {
        // This should never happen
        Log.error("got a nil data!")
        return
    }

    guard let newStatus = DBusDispatchStatus.init(rawValue: new_status.rawValue) else {
        Log.error("Unknown DBusDispatchStatus: \(new_status)")
        return
    }

    // Extract pointer to 'DBusDispatchSource' from void pointer:
    let dispatchSource = Unmanaged<DBusDispatchSource>.fromOpaque(p).takeUnretainedValue()
    // finally, call the class method
    dispatchSource.dispatchStatus(newStatus: newStatus)
}

// This is not the Foundation DispatchSource. This has no analog in libdbus.
// It exists to bridge libdbus land to Swift land.
public class DBusDispatchSource {
    private let connection: DBusConnection
    private var dispatchStatus: DBusDispatchStatus
    private let readerSource: DispatchSourceRead
    private let PIPE_READ = 0
    private let PIPE_WRITE = 1
    private var pipeFds: [Int32] = [-1, -1]

    public init(connection: DBusConnection, dispatchQueue: DispatchQueue) throws {
        Log.entry("")
        self.connection = connection
        let c_dispatchStatus = dbus_connection_get_dispatch_status(connection.internalPointer)
        guard let d = DBusDispatchStatus.init(rawValue: c_dispatchStatus.rawValue) else {
             throw RuntimeError.generic("DispatchSource(): unknown dispatchStatus")
        }
        dispatchStatus = d

        let r = pipe(&pipeFds)
        if r != 0 {
            throw RuntimeError.generic("DispatchSource(): pipe() failed")
        }

        readerSource = DispatchSource.makeReadSource(fileDescriptor: pipeFds[PIPE_READ],
                                                     queue: dispatchQueue)
        readerSource.setEventHandler(handler: self.handleRead)
        readerSource.resume()

        // Grap an UnsafeMutableRawPointer to self so that we can pass it into C land
        let data = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        dbus_connection_set_dispatch_status_function(connection.internalPointer,
                                                     dispatchStatusFunction, data, nil)
    }

    func dispatchStatus(newStatus: DBusDispatchStatus) {
        Log.entry("\(newStatus)")
        dispatchStatus = newStatus

        // if libdbus that we have data remaining to read, then write to our end of the pipe
        if (newStatus == .dataRemains) {
            // Swift does not make this easy
            let buffer: UnsafeMutablePointer<UInt32> = UnsafeMutablePointer.allocate(capacity: 1)
            buffer[0] = newStatus.rawValue
            write(pipeFds[PIPE_WRITE], buffer, 4)
        }
    }

    private func handleRead() {
        Log.entry("")

        // Swift does not make this easy
        let buffer: UnsafeMutablePointer<UInt32> = UnsafeMutablePointer.allocate(capacity: 1)
        read(pipeFds[PIPE_READ], buffer, 4)

        var c_DispatchStatus = DBUS_DISPATCH_DATA_REMAINS // our starting value doesn't matter
        repeat {
            c_DispatchStatus = dbus_connection_dispatch(connection.internalPointer);
        } while (c_DispatchStatus == DBUS_DISPATCH_DATA_REMAINS)
    }

    private func handleReadCancel() {
        Log.entry("")
    }
}
