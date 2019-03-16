import Foundation
import LoggerAPI

//
// This is where the code lives to actually decode the DBus message.
//
extension _DBusDecoder {
    final class DBusSingleValueContainer: DBusDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        var storage: DBusBasicValue? = nil

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
        }

        // DOES NOT ADVANCE THE ITERATOR
        func dbusDecode() throws {
            let t = try self.msgIter.getType()
            switch t {
            case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor,
                 .string, .objectPath, .signature:
                storage = try msgIter.getBasic()
            default:
                throw RuntimeError.logicError("Unhandeled case in _DBusDecoder.SingleValueContainer.dbusDecode()")
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
        var storage: DBusBasicValue

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], storage: DBusBasicValue) {
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

            switch storage {
            case .boolean(let v):
                return v

            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(storage) as Bool"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Bool.self, context)
            }
        }

        func decode(_ type: String.Type) throws -> String {
            Log.entry("")

            switch storage {
            case .string(let v), .objectPath(let v), .signature(let v):
                return v
            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(storage) as String"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(String.self, context)
            }
        }

        func decode(_ type: Double.Type) throws -> Double {
            Log.entry("")

            switch storage {
            case .double(let v):
                return v

            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(storage) as Double"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Double.self, context)
            }
        }

        func decode(_ type: Float.Type) throws -> Float {
            Log.entry("")

            switch storage {
            case .double(let v):
                return Float(v)

            default:
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(storage) as Float"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Float.self, context)
            }
        }

        func decode<T>(_ type: T.Type) throws -> T where T : BinaryInteger & Decodable {
            Log.entry("")

            var t: T?
            switch storage {
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
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): can not return \(storage) as BinaryInteger & Decodable"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(T.self, context)
            }

            guard let value = t else {
                let debugDescription = "_DBusDecoder.SingleValueContainer.dbusDecode(): failed to decode \(storage) as BinaryInteger & Decodable"
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
}
