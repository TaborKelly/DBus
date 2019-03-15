import Foundation
import LoggerAPI

enum SingleValueDecoderStorage {
    case basicType(DBusBasicValue)
    case container(DBusDecodingContainer)
}

//
// This is where the code lives to actually decode the DBus message.
//
extension _DBusDecoder {
    final class DBusSingleValueContainer: DBusDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        var sigIter: DBusSignatureIter // TODO: remove
        var storage: SingleValueDecoderStorage? = nil

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) throws {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = try DBusSignatureIter(msgIter.getSignature())
        }

        // DOES NOT ADVANCE THE ITERATOR
        func dbusDecode() throws {
            let t = try self.sigIter.getCurrentType()
            switch t {
            case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor,
                 .string, .objectPath, .signature:
                storage = .basicType(try msgIter.getBasic())
            default:
                throw RuntimeError.generic("Unhandeled case in _DBusDecoder.SingleValueContainer.dbusDecode()")
            }
        }
    }
}

//
// This is where the code lives that the Swift decodable framework will call
//
extension _DBusDecoder {
    final class SingleValueContainer: SingleValueDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var storage: SingleValueDecoderStorage? = nil

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], storage: SingleValueDecoderStorage?) {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }

        func decodeNil() -> Bool {
            Log.entry("")

            Log.error("DBus can not represent nil")

            return false
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            Log.entry("")

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Bool.self, context)
            }

            guard case let .basicType(basicValue) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a basic type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Bool.self, context)
            }

            switch basicValue {
            case .boolean(let v):
                return v

            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as Bool"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Bool.self, context)
            }
        }

        func decode(_ type: String.Type) throws -> String {
            Log.entry("")

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(String.self, context)
            }

            guard case let .basicType(basicValue) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a basic type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(String.self, context)
            }

            switch basicValue {
            case .string(let v), .objectPath(let v), .signature(let v):
                return v
            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as String"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(String.self, context)
            }
        }

        func decode(_ type: Double.Type) throws -> Double {
            Log.entry("")

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Double.self, context)
            }

            guard case let .basicType(basicValue) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a basic type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Double.self, context)
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

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Float.self, context)
            }

            guard case let .basicType(basicValue) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a basic type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Float.self, context)
            }

            switch basicValue {
            case .double(let v):
                return Float(v)

            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(basicValue) as Float"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Float.self, context)
            }
        }

        func decode<T>(_ type: T.Type) throws -> T where T : BinaryInteger & Decodable {
            Log.entry("")

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(T.self, context)
            }

            guard case let .basicType(basicValue) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a basic type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(T.self, context)
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
                throw DecodingError.typeMismatch(T.self, context)
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

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is nil"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(T.self, context)
            }

            guard case let .container(container) = storage else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): self.storage is not a container type"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(T.self, context)
            }

            let decoder = try _DBusDecoder(userInfo: userInfo, decodingContainer: container)
            let value = try T(from: decoder)

            return value
        }
    }
}
