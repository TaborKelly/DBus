//
//  DispatchStatus.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 2/27/16.
//

/// Indicates the status of incoming data on a `DBusConnection`.
///
/// This determines whether `DBusConnection.dispatch()` needs to be called.
public enum DBusDispatchStatus: UInt32 {

    /// There is more data to potentially convert to messages.
    case dataRemains

    /// All currently available data has been processed.
    case complete

    /// More memory is needed to continue.
    case needMemory
}
