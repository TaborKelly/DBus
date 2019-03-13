//
//  DBusSignatureIter.swift
//  DBus
//
//  Created by Tabor Kelly on 3/7/19.
//  Copyright © 2019 Racepoint Energy LLC.
//  All rights reserved.
//

import Foundation
import CDBus
import LoggerAPI

class DBusSignatureIter {
    var iter: CDBus.DBusSignatureIter
    private var signature: UnsafePointer<Int8>? = nil

    // new DBusSignatureIter from a CDBus.DBusSignatureIter
    init(_ iter: CDBus.DBusSignatureIter) {
        Log.entry("")

        self.iter = iter
    }

    deinit {
        signature?.deallocate()
    }

    // new DBusSignatureIter from a dbus signature
    init(_ signature: String) throws {
        Log.entry("\(signature)")
        self.signature = try swiftStringToConstCharStar(signature)

        // First check to see if this signature is valid
        let error = DBusError()
        let b = Bool(dbus_signature_validate(signature, &error.cError))
        if error.isSet {
            throw error
        } else if b == false {
            throw RuntimeError.generic("dbus_signature_validate() returned false but error was not set!")
        }

        // Then initialize the DBusSignatureIter
        iter = CDBus.DBusSignatureIter()
        dbus_signature_iter_init(&iter, self.signature)
    }

    // This should really never throw short of memory corruption
    func getCurrentType() throws -> DBusType {
        let i = dbus_signature_iter_get_current_type(&iter)
        guard let t = DBusType(i) else {
            throw RuntimeError.generic("invalid DBus type! (this should never happen)")
        }

        return t
    }

    func getSignature() -> String {
        return String(cString: dbus_signature_iter_get_signature(&iter))
    }

    func getElementType() throws -> DBusType {
        let currentType = try getCurrentType()
        if currentType != .array {
            throw RuntimeError.generic("getElementType() is only for arrays!, not for \(currentType)")
        }

        let i = dbus_signature_iter_get_element_type(&iter)
        guard let t = DBusType(i) else {
            throw RuntimeError.generic("invalid DBus type! (this should never happen)")
        }

        return t
    }

    func next() -> Bool {
        return Bool(dbus_signature_iter_next(&iter))
    }

    func recurse() throws -> DBusSignatureIter {
        if isContainer() == false {
            let t = try getElementType()
            throw RuntimeError.generic("Can not recurse into \(t)!")
        }

        var subiter = CDBus.DBusSignatureIter()
        dbus_signature_iter_recurse(&iter, &subiter)

        // TODO: pass reference to self so that parent isn't deallocated before child by the ARC
        return DBusSignatureIter(subiter)
    }

    func isBasic() -> Bool {
        return Bool(dbus_type_is_basic(dbus_signature_iter_get_current_type(&iter)))
    }

    func isContainer() -> Bool {
        return Bool(dbus_type_is_container(dbus_signature_iter_get_current_type(&iter)))
    }
}
