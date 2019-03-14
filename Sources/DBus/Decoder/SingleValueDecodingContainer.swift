import Foundation
import LoggerAPI

extension _DBusDecoder {
    final class SingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        var sigIter: DBusSignatureIter
        var storage: DBusBasicValue? = nil

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) throws {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = try DBusSignatureIter(msgIter.getSignature())
        }
    }
}

extension _DBusDecoder.SingleValueContainer: DBusDecodingContainer {
    // DOES NOT ADVANCE THE ITERATOR
    func dbusDecode() throws {
        let t = try self.sigIter.getCurrentType()
        switch t {
        case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor,
             .string, .objectPath, .signature:
            storage = try msgIter.getBasic()
        default:
            throw RuntimeError.generic("Unhandeled case in _DBusDecoder.SingleValueContainer.dbusDecode()")
        }
    }
}

extension _DBusDecoder.SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        Log.entry("")

        Log.error("DBus can not represent nil")

        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        Log.entry("")

        guard let basicValue = self.storage else {
            throw RuntimeError.generic("_DBusDecoder.SingleValueContainer.dbusDecode(_ type: Bool.Type): storage is nil!")
        }

        switch basicValue {
        case .boolean(let v):
            return v

        default:
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as Bool"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }

    func decode(_ type: String.Type) throws -> String {
        Log.entry("")

        guard let basicValue = self.storage else {
            throw RuntimeError.generic("_DBusDecoder.SingleValueContainer.dbusDecode(_ type: String.Type): storage is nil!")
        }

        switch basicValue {
        case .string(let v), .objectPath(let v), .signature(let v):
            return v
        default:
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as String"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }

    func decode(_ type: Double.Type) throws -> Double {
        Log.entry("")

        guard let basicValue = self.storage else {
            throw RuntimeError.generic("_DBusDecoder.SingleValueContainer.dbusDecode(_ type: Double.Type): storage is nil!")
        }

        switch basicValue {
        case .double(let v):
            return v

        default:
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as Double"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }

    func decode(_ type: Float.Type) throws -> Float {
        Log.entry("")

        guard let basicValue = self.storage else {
            throw RuntimeError.generic("_DBusDecoder.SingleValueContainer.dbusDecode(_ type: Float.Type): storage is nil!")
        }

        switch basicValue {
        case .double(let v):
            return Float(v)

        default:
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as Float"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }

    func decode<T>(_ type: T.Type) throws -> T where T : BinaryInteger & Decodable {
        Log.entry("")

        guard let basicValue = self.storage else {
            throw RuntimeError.generic("_DBusDecoder.SingleValueContainer.dbusDecode(_ type: T.Type): storage is nil!")
        }

        var t: T?
        switch basicValue {
        case .byte(let v):
            t = T(exactly: v)
        case .int16(let v):
            t = T(exactly: v)
        case .uint16(let v):
            t = T(exactly: v)
        case .int32(let v):
            t = T(exactly: v)
        case .uint32(let v):
            t = T(exactly: v)
        case .int64(let v):
            t = T(exactly: v)
        case .uint64(let v):
            t = T(exactly: v)
        case .fileDescriptor(let v):
            t = T(exactly: v)

        default:
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as BinaryInteger & Decodable"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Double.self, context)
        }

        guard let value = t else {
            let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): failed to decode \(basicValue) as BinaryInteger & Decodable"
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(T.self, context)
        }

        return value
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        Log.entry("")

        var debugDescription = "_DBusDecoder.SingleValueContainer.decode(): _DBusDecoder.SingleValueContainer doesn't "
        debugDescription += "know about this type."
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
        throw DecodingError.typeMismatch(Double.self, context)
    }
}
