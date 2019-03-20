//
//  Timeout.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 10/10/18.
//

import CDBus

/// A wrapper around libdbus timeouts which are in milliseconds.
public struct Timeout: RawRepresentable {

    /// The raw integer representation of the libdbus timeout value in milliseconds.
    public var rawValue: Int32

    /**
     Initialize a new Timeout struct.

     - Parameters:
         - rawValue: The timeout value in milliseconds.

     */
    public init(rawValue: Int32) {

        self.rawValue = rawValue
    }
}

public extension Timeout {
    /// The defualt timeout value (DBUS_TIMEOUT_USE_DEFAULT)
    public static let `default`: Timeout = Timeout(rawValue: DBUS_TIMEOUT_USE_DEFAULT)
    /// Never timeout (DBUS_TIMEOUT_INFINITE)
    public static let infinite: Timeout = Timeout(rawValue: DBUS_TIMEOUT_INFINITE)
}

extension Timeout: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int32) {

        self.init(rawValue: value)
    }
}
