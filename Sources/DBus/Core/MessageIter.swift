//
//  MessageItr.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 10/12/18.
//

import CDBus

// MARK: - Iterating

// A thin wrapper for the libdbus DBusMessageIter
// NOT a Swift iterator
public class DBusMessageIter {
    var iter: CDBus.DBusMessageIter

    init() {
        iter = CDBus.DBusMessageIter()
    }
}

extension DBusMessageIter {
    public convenience init(iterating message: DBusMessage) {
        self.init()
        dbus_message_iter_init(message.internalPointer, &iter)
    }

    func openContainer(containerType: DBusType,
                       // For variants, the contained_signature should be the type of the single value inside the
                       // variant. For structs and dict entries, contained_signature should be NULL; it will be set to
                       // whatever types you write into the struct. For arrays, contained_signature should be the type
                       // of the array elements.
                       containedSignature: String?) throws -> DBusMessageIter {
        let sub = DBusMessageIter()
        let b = Bool(dbus_message_iter_open_container(&iter, Int32(containerType.integerValue),
                                                      containedSignature, &sub.iter))
        if b == false {
            throw RuntimeError.generic("dbus_message_iter_open_container() failed!")
        }

        return sub
    }

    // When writing a message, recurse into a container type
    func recurse() throws -> DBusMessageIter {
        guard let t = DBusType(dbus_message_iter_get_arg_type(&iter)) else {
            throw RuntimeError.generic("dbus_message_iter_get_arg_type() failed!")
        }
        if t.isContainer == false {
            throw RuntimeError.generic("Can't recures into a \(t)")
        }

        let sub = DBusMessageIter()
        dbus_message_iter_recurse(&iter, &sub.iter)

        return sub
    }

    func next() -> Bool {
        return Bool(dbus_message_iter_next(&iter))
    }

    /// Read a basic value into the provided pointer.
    @inline(__always)
    private func readBasic() -> CDBus.DBusBasicValue {

        var basicValue = CDBus.DBusBasicValue()
        withUnsafeMutablePointer(to: &basicValue) {
            dbus_message_iter_get_basic(&iter, UnsafeMutableRawPointer($0))
        }
        return basicValue
    }

    private func readString() -> String {

        guard let cString = readBasic().str
            else { fatalError("Nil string pointer") }

        return String(cString: cString)
    }

    public func getBasic() throws -> DBusBasicValue {
        let t = try getType()
        if t.isBasic == false {
            throw RuntimeError.generic("DBusMessageIter.getBasic(): \(t) is not a basic type.")
        }

        switch t {
        case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor:
            let cBasic = readBasic()
            return try DBusBasicValue(cBasic, t)
        case .string, .objectPath, .signature:
            let s = readString()
            return try DBusBasicValue(s, t)
        default:
            throw RuntimeError.generic("DBusMessageIter.getBasic(): \(t) is not a basic type.")
        }
    }

    public func getSignature() -> String {
        return String(cString: dbus_message_iter_get_signature(&iter))
    }

    public func getType() throws -> DBusType {
        let i = dbus_message_iter_get_arg_type(&iter)
        guard let t = DBusType(i) else {
            throw RuntimeError.generic("DBusMessageIter.getType(): DBusType() initializer failed")
        }

        return t
    }

    public func getElementType() throws -> DBusType {
        let i = dbus_message_iter_get_element_type(&iter)
        guard let t = DBusType(i) else {
            throw RuntimeError.generic("DBusMessageIter.getElementType(): DBusType() initializer failed")
        }

        return t
    }

    public func hasNext() -> Bool {
        return Bool(dbus_message_iter_has_next(&iter))
    }
}

// MARK: - Appending

internal extension DBusMessageIter {

    /// Initializes a DBusMessageIter for appending arguments to the end of a message.
    convenience init(appending message: DBusMessage) {
        self.init()
        dbus_message_iter_init_append(message.internalPointer, &iter)
    }

    func append(_ value: DBusBasicValue) throws {
        let type = value.getType()
        var cBasicValue = try value.getC()
        try self.append(&cBasicValue, type)
    }

    private func append(_ basicValue: inout CDBus.DBusBasicValue, _ type: DBusType) throws {

        guard withUnsafePointer(to: &basicValue, {
            Bool(dbus_message_iter_append_basic(&iter, Int32(type.integerValue), UnsafeRawPointer($0)))
        }) else { throw RuntimeError.generic("dbus_message_iter_append_basic() failed") }
    }

    private func append(_ string: String, _ type: DBusType = .string) throws {

        try string.withCString {
            let cString = UnsafeMutablePointer<Int8>(mutating: $0)
            var basicValue = CDBus.DBusBasicValue(str: cString)
            try append(&basicValue, type)
        }
    }
}
