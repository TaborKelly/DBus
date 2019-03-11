import Foundation
import CDBus
import AnyCodable
import LoggerAPI

extension _DBusEncoder {
    //
    // The Apple Codeable framework calls this class. It is split into two extensions (see below).
    //
    final class SingleValueContainer {
        private var storage: AnyCodable? = nil
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

    func encode<T>(_ value: T) throws where T : Encodable {
        Log.entry("")
        try checkCanEncode(value: value)

        self.storage = AnyCodable(value)
    }
}

extension _DBusEncoder.SingleValueContainer: _DBusEncodingContainer {
    //
    // The actualy DBus encoding happens here
    //
    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        guard let value = self.storage else {
            throw RuntimeError.generic("SingleValueContainer.dbusEncode: storage is nil!")
        }

        switch (value.value) {
        case is (Void):
            throw RuntimeError.generic("SingleValueContainer.dbusEncode: value.value is nil!")
        case let (v as Bool):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Int):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Int8):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Int16):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Int32):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Int64):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as UInt):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as UInt8):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as UInt16):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as UInt32):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as UInt64):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Float):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as Double):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)
        case let (v as String):
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, v)

        default:
            try self.dbusEncode(msgIter: msgIter, sigIter: sigIter, value)
        }
    }

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: Bool) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .boolean {
            throw RuntimeError.generic("Can't encode type Bool because DBus signature says \(t) for path \(codingPath)")
        }

        try msgIter.append(argument: .boolean(value))
    }

    func dbusEncode<T>(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: T) throws where T : BinaryInteger & Encodable {
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

        // TODO: Revisit .fileDescriptor. This may be platform dependant.
        case .int32, .fileDescriptor:
            if let int32 = Int32(exactly: value) {
                try msgIter.append(argument: .int32(int32))
            } else {
                throw RuntimeError.generic("Could not encode \(t) as a int32 for path \(codingPath)")
            }

        case .uint32:
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

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: String) throws {
        Log.entry("")

        let t = try sigIter.getCurrentType()
        if t != .string {
            throw RuntimeError.generic("Can't encode type String because DBus signature says \(t) for path \(codingPath)")
        }

        try msgIter.append(argument: .string(value))
    }

    func dbusEncode<T>(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: T) throws where T : Encodable {
        Log.entry("")

        let encoder = _DBusEncoder()
        try value.encode(to: encoder)
        try encoder.dbusEncode(msgIter: msgIter, sigIter: sigIter)
    }
}
