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

    // TODO: can we remove this?
    private func signature() throws -> DBusSignature {

        guard let cString = dbus_message_iter_get_signature(&iter)
            else { throw RuntimeError.generic("dbus_message_iter_get_signature() failed") }

        let string = String(cString: cString)

        dbus_free(UnsafeMutableRawPointer(cString))

        return DBusSignature(string)
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

    // TODO: REVISIT. Can we get rid of this? It would let us remove a lot of code.
    func append(argument: DBusMessageArgument) throws {

        switch argument {

        case let .byte(value):
            var basicValue = CDBus.DBusBasicValue(byt: value)
            try append(&basicValue, .byte)
        case let .boolean(value):
            var basicValue = CDBus.DBusBasicValue(bool_val: dbus_bool_t(value))
            try append(&basicValue, .boolean)
        case let .int16(value):
            var basicValue = CDBus.DBusBasicValue(i16: value)
            try append(&basicValue, .int16)
        case let .uint16(value):
            var basicValue = CDBus.DBusBasicValue(u16: value)
            try append(&basicValue, .uint16)
        case let .int32(value):
            var basicValue = CDBus.DBusBasicValue(i32: value)
            try append(&basicValue, .int32)
        case let .uint32(value):
            var basicValue = CDBus.DBusBasicValue(u32: value)
            try append(&basicValue, .uint32)
        case let .int64(value):
            var basicValue = CDBus.DBusBasicValue(i64: dbus_int64_t(value))
            try append(&basicValue, .int64)
        case let .uint64(value):
            var basicValue = CDBus.DBusBasicValue(u64: dbus_uint64_t(value))
            try append(&basicValue, .uint64)
        case let .double(value):
            var basicValue = CDBus.DBusBasicValue(dbl: value)
            try append(&basicValue, .double)
        case let .fileDescriptor(value):
            var basicValue = CDBus.DBusBasicValue(fd: value.rawValue)
            try append(&basicValue, .fileDescriptor)

        case let .string(value):
            try append(value)
        case let .objectPath(value):
            try append(value.rawValue, .objectPath)
        case let .signature(value):
            try append(value.rawValue, .signature)

        case let .array(array):
            try appendContainer(type: .array, signature: DBusSignature([array.type])) {
                for element in array {
                    try $0.append(argument: element)
                }
            }

        case let .struct(structure):
            try appendContainer(type: .struct) {
                for element in structure {
                    try $0.append(argument: element)
                }
            }

        case let .variant(variant):
            try appendContainer(type: .variant, signature: DBusSignature([variant.type])) {
                try $0.append(argument: variant)
            }
        }
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

    /**
     Appends a container-typed value to the message.
    */
    private func appendContainer(type: DBusType, signature: DBusSignature? = nil, container: (inout DBusMessageIter) throws -> ()) throws {

        var subIterator = DBusMessageIter()

        /**
         On success, you are required to append the contents of the container using the returned sub-iterator, and then call dbus_message_iter_close_container(). Container types are for example struct, variant, and array. For variants, the contained_signature should be the type of the single value inside the variant. For structs and dict entries, contained_signature should be NULL; it will be set to whatever types you write into the struct. For arrays, contained_signature should be the type of the array elements.
        */

        guard Bool(dbus_message_iter_open_container(&iter, Int32(type.integerValue), signature?.rawValue, &subIterator.iter))
            else { throw RuntimeError.generic("dbus_message_iter_open_container() failed") }

        defer { dbus_message_iter_close_container(&iter, &subIterator.iter) }

        try container(&subIterator)
    }
}
