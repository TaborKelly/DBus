import Foundation
import CDBus
import LoggerAPI

extension _DBusEncoder {
    final class SingleValueContainer {
        fileprivate var canEncodeNewValue = true
        fileprivate func checkCanEncode(value: Any?) throws {
            Log.entry("")
            guard self.canEncodeNewValue else {
                let context = EncodingError.Context(codingPath: self.codingPath,
                                                    debugDescription: "Attempt to encode value through single value container when previously value already encoded.")
                throw EncodingError.invalidValue(value as Any, context)
            }
        }

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let iter: DBusMessageIter

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], iter: DBusMessageIter) {
            Log.entry("")
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.iter = iter
        }
    }
}

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
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .boolean(value))
    }

    func encode(_ value: String) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .string(value))
    }

    func encode(_ value: Double) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .double(value))
    }

    func encode(_ value: Float) throws {
        Log.entry("")
        // DBus does not support Float, so just encode Double
        try encode(Double(value))
    }

    func encode(_ value: Int) throws {
        if Int.bitWidth == 32 {
            return try encode(Int32(value))
        } else if Int.bitWidth == 64 {
            return try encode(Int64(value))
        } else {
            let context = EncodingError.Context(codingPath: self.codingPath,
                                                debugDescription: "Cannot encode integer of size \(Int.bitWidth).")
            throw EncodingError.invalidValue(value, context)
        }
    }

    func encode(_ value: UInt) throws {
        if UInt.bitWidth == 32 {
            return try encode(UInt32(value))
        } else if UInt.bitWidth == 64 {
            return try encode(UInt64(value))
        } else {
            let context = EncodingError.Context(codingPath: self.codingPath,
                                                debugDescription: "Cannot encode integer of size \(Int.bitWidth).")
            throw EncodingError.invalidValue(value, context)
        }
    }

    func encode(_ value: Int8) throws {
        Log.entry("")
        // DBus does not a signed 8 bit integer, so just encode UInt8
        try encode(UInt8(value))
    }

    func encode(_ value: Int16) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .int16(value))
    }

    func encode(_ value: Int32) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .int32(value))
    }

    func encode(_ value: Int64) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .int64(value))
    }

    func encode(_ value: UInt8) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .byte(value))
    }

    func encode(_ value: UInt16) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .uint16(value))
    }

    func encode(_ value: UInt32) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .uint32(value))
    }

    func encode(_ value: UInt64) throws {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        try iter.append(argument: .uint64(value))
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        Log.entry("")
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        let encoder = try _DBusEncoder(iter: iter)
        try value.encode(to: encoder)
    }
}

extension _DBusEncoder.SingleValueContainer: _DBusEncodingContainer {
}
