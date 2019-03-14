import Foundation
import CDBus
import LoggerAPI

//
// Supporting types
//

enum SingleValueContainerStorage {
    case basicType(DBusBasicValue)
    case encoder(_DBusEncoder)
}

extension _DBusEncoder {
    //
    // The Apple Codeable framework calls this class. It is split into two extensions (see below).
    //
    final class SingleValueContainer {
        private var storage: SingleValueContainerStorage? = nil
        fileprivate func checkCanEncode(value: Any?) throws {
            Log.entry("")
            if self.storage != nil {
                let context = EncodingError.Context(codingPath: self.codingPath,
                                                    debugDescription: "Attempt to encode value through single value container when previously value already encoded.")
                throw EncodingError.invalidValue(value as Any, context)
            }
        }

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            Log.entry("")
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        deinit {
            Log.entry("")
        }
    }
}

//
// This is the code that the Apple Codeable framework calls. We really just save the data that we ware about for later
// use (in storage).
//
extension _DBusEncoder.SingleValueContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        Log.entry("")

        let context = EncodingError.Context(codingPath: self.codingPath,
                                            debugDescription: "DBus can not encode nil values")
        let value: Any? = nil
        throw EncodingError.invalidValue(value as Any, context)
    }

    func encode(_ value: Bool) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.boolean(value))
    }

    func encode(_ value: String) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.string(value))
    }

    func encode(_ value: Double) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.double(value))
    }

    func encode(_ value: Float) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.double(Double(value)))
    }

    func encode(_ value: Int) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        switch Int.bitWidth {
        case 32:
            self.storage = .basicType(.int32(Int32(value)))
        case 64:
            self.storage = .basicType(.int64(Int64(value)))
        default:
            throw RuntimeError.generic("SingleValueContainer.encode(): unsupported Integer width!")
        }
    }

    func encode(_ value: Int8) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.byte(UInt8(value)))
    }

    func encode(_ value: Int16) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.int16(value))
    }

    func encode(_ value: Int32) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.int32(value))
    }

    func encode(_ value: Int64) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.int64(value))
    }

    func encode(_ value: UInt) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        switch UInt.bitWidth {
        case 32:
            self.storage = .basicType(.uint32(UInt32(value)))
        case 64:
            self.storage = .basicType(.uint64(UInt64(value)))
        default:
            throw RuntimeError.generic("SingleValueContainer.encode(): unsupported Integer width!")
        }
    }

    func encode(_ value: UInt8) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.byte(value))
    }

    func encode(_ value: UInt16) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.uint16(value))
    }

    func encode(_ value: UInt32) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.uint32(value))
    }

    func encode(_ value: UInt64) throws {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = .basicType(.uint64(value))
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        Log.entry("\(value)")
        try checkCanEncode(value: value)

        let encoder = _DBusEncoder()
        try value.encode(to: encoder)
        self.storage = .encoder(encoder)
    }
}

extension _DBusEncoder.SingleValueContainer: _DBusEncodingContainer {
    //
    // The actualy DBus encoding happens here
    //

    // This is exposed so that KeyedEncodingContainer can use it
    static func dbusEncodeBasic(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, codingPath: [CodingKey],
                                _ value: String) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        switch t {
        case .string:
            try msgIter.append(.string(value))
        case .objectPath:
            try msgIter.append(.objectPath(value))
        case .signature:
            try msgIter.append(.signature(value))

        default:
            throw RuntimeError.generic("Can't encode type String because DBus signature says \(t) for path \(codingPath)")
        }
    }

    // This is exposed so that KeyedEncodingContainer can use it
    static func dbusEncodeBasic(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, codingPath: [CodingKey],
                                _ value: Bool) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .boolean {
            throw RuntimeError.generic("Can't encode type Bool because DBus signature says \(t) for path \(codingPath)")
        }

        try msgIter.append(argument: .boolean(value))
    }

    // This is exposed so that KeyedEncodingContainer can use it
    static func dbusEncodeBasic<T>(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, codingPath: [CodingKey],
                                   _ value: T) throws where T : BinaryInteger & Encodable {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .byte &&
            t != .int16 &&
            t != .uint16 &&
            t != .int32 &&
            t != .uint32 &&
            t != .int64 &&
            t != .uint64 &&
            t != .fileDescriptor {
            throw RuntimeError.generic("Can't encode type BinaryInteger because DBus signature says \(t) for path \(codingPath)")
        }

        switch t {
        case .byte:
            if let uint8 = UInt8(exactly: value) {
                try msgIter.append(argument: .byte(uint8))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a byte for path \(codingPath)")
            }

        case .int16:
            if let int16 = Int16(exactly: value) {
                try msgIter.append(argument: .int16(int16))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a int16 for path \(codingPath)")
            }

        case .uint16:
            if let uint16 = UInt16(exactly: value) {
                try msgIter.append(argument: .uint16(uint16))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a uint16 for path \(codingPath)")
            }

        case .int32:
            if let int32 = Int32(exactly: value) {
                try msgIter.append(argument: .int32(int32))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a int32 for path \(codingPath)")
            }

        case .uint32, .fileDescriptor:
            if let uint32 = UInt32(exactly: value) {
                try msgIter.append(argument: .uint32(uint32))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a uint32 for path \(codingPath)")
            }

        case .int64:
            if let int64 = Int64(exactly: value) {
                try msgIter.append(argument: .int64(int64))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a int64 for path \(codingPath)")
            }

        case .uint64:
            if let uint64 = UInt64(exactly: value) {
                try msgIter.append(argument: .uint64(uint64))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a uint64 for path \(codingPath)")
            }

        default:
            throw RuntimeError.generic("logic error in _DBusEncoder.SingleValueContainer.dbusEncode<T>(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: T) throws where T : BinaryInteger & Encodable")
        }
    }

    // This is exposed so that KeyedEncodingContainer can use it
    static func dbusEncodeBasic(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, codingPath: [CodingKey],
                                _ value: Double) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .double {
            throw RuntimeError.generic("Can't encode type Double because DBus signature says \(t) for path \(codingPath)")
        }

        try msgIter.append(argument: .double(value))
    }

    // This is exposed so that KeyedEncodingContainer can use it
    static func dbusEncodeBasic(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, codingPath: [CodingKey],
                                _ value: Float) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .double {
            throw RuntimeError.generic("Can't encode type Float because DBus signature says \(t) for path \(codingPath)")
        }

        let double = Double(value)
        try msgIter.append(argument: .double(double))
    }

    func dbusEncode(msgIter msgIterIn: DBusMessageIter, sigIter: DBusSignatureIter, _ value: DBusBasicValue) throws {
        Log.entry("")

        // This is a little tricky, but we synthesize a new type and msgIter if we are dealing with a variant
        let msgIter: DBusMessageIter
        var sigIter = sigIter
        let t = try sigIter.getCurrentType()
        var synthesizedType = false
        if t == .variant {
            sigIter = try DBusSignatureIter(value.getVariantSignature())
            synthesizedType = true
        }

        if synthesizedType {
            msgIter = try msgIterIn.openContainer(containerType: .variant,
                                                  containedSignature: sigIter.getSignature())
        } else {
            msgIter = msgIterIn
        }

        switch (value) {
        case .byte(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .boolean(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .int16(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .uint16(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .int32(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .uint32(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .int64(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .uint64(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .double(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .fileDescriptor(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .string(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .objectPath(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        case .signature(let v):
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, v)
        }

        if synthesizedType {
            // Close the variant
            let b = Bool(dbus_message_iter_close_container(&msgIterIn.iter, &msgIter.iter))
            if b == false {
                throw RuntimeError.generic("dbus_message_iter_close_container() failed in _DBusEncoder.SingleValueContainer.dbusEncode()")
            }
        }

    }

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        Log.entry("")

        guard let storage = self.storage else {
            throw RuntimeError.generic("SingleValueContainer.dbusEncode: self.storage is nil!")
        }

        switch storage {
        case .basicType(let basicType):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, basicType)
        case .encoder(let encoder):
            try encoder.dbusEncode(msgIter: msgIter, sigIter: sigIter)
        }
    }

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: Double) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .double {
            throw RuntimeError.generic("Can't encode type Double because DBus signature says \(t) for path \(codingPath)")
        }

        try msgIter.append(argument: .double(value))
    }

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: Float) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .double {
            throw RuntimeError.generic("Can't encode type Float because DBus signature says \(t) for path \(codingPath)")
        }

        let double = Double(value)
        try msgIter.append(argument: .double(double))
    }

    func dbusEncode<T>(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: T) throws where T : Encodable {
        Log.entry("")

        let encoder = _DBusEncoder()
        try value.encode(to: encoder)
        try encoder.dbusEncode(msgIter: msgIter, sigIter: sigIter)
    }
}
