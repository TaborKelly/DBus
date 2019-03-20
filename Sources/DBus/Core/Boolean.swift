//
//  Boolean.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 2/25/16.
//

import CDBus

extension Bool {

    init(_ boolValue: dbus_bool_t) {

        self = boolValue != 0
    }
}

extension dbus_bool_t {

    init(_ boolValue: Bool) {

        self = boolValue ? 1 : 0
    }
}

extension dbus_bool_t: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {

        self.init(value)
    }
}
