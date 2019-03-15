import Foundation
import LoggerAPI

//
// This is where the code lives to actually decode the DBus message.
//
extension _DBusDecoder {
    final class DBusKeyedContainer: DBusDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        let sigIter: DBusSignatureIter // TODO: remove
        var storage: [String: DBusDecodingContainer] = [:]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) throws {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = try DBusSignatureIter(msgIter.getSignature())
        }

        func nestedCodingPath(_ key: String) -> [CodingKey] {
            Log.entry("")

            return self.codingPath + [AnyCodingKey(stringValue: key)]
        }

        func decodeKey(msgIter: DBusMessageIter) throws -> String {
            Log.entry("")

            let basicValue = try msgIter.getBasic()

            switch basicValue {
            case .byte(let v):
                return String(v)
            case .int16(let v):
                return String(v)
            case .uint16(let v):
                return String(v)
            case .int32(let v):
                return String(v)
            case .uint32(let v):
                return String(v)
            case .int64(let v):
                return String(v)
            case .uint64(let v):
                return String(v)
            case .fileDescriptor(let v):
                return String(v)
            case .string(let v), .objectPath(let v), .signature(let v):
                return String(v)
            case .boolean(_):
                let debugDescription = "Swift doesn't know what to do with a key of type boolean!"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Bool.self, context)
            case .double(_):
                let debugDescription = "Swift doesn't know what to do with a key of type double!"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Double.self, context)
            }
        }

        // TODO: variant and dictionary cases
        func dbusDecode() throws {
            Log.entry("")

            let outerType = try self.sigIter.getCurrentType()
            if outerType != .array {
                throw RuntimeError.generic("_DBusDecoder.KeyedContainer.dbusDecode() can't handle a \(outerType)")
            }

            let msgArrayIter = try self.msgIter.recurse()
            let innerType = try self.sigIter.getElementType()
            if innerType != .dictionaryEntry {
                throw RuntimeError.generic("_DBusDecoder.KeyedContainer.dbusDecode() can't handle a \(innerType)")
            }

            repeat {
                let msgDictIter = try msgArrayIter.recurse()
                let key = try decodeKey(msgIter: msgDictIter)
                let b = msgDictIter.next()
                if b == false {
                    let debugDescription = "Found dict with only one value!"
                    let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                    throw DecodingError.dataCorrupted(context)
                }

                storage[key] = try decodeValue(codingPath: nestedCodingPath(key), userInfo: userInfo,
                                               msgIter: msgDictIter)
            } while msgArrayIter.next()
        }
    }
}

//
// This is where the code lives that the Swift decodable framework will call
//
extension _DBusDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let storage: [String: DBusDecodingContainer] // TODO: make this optional

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any],
             storage: [String: DBusDecodingContainer]) {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }
    }
}

extension _DBusDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        Log.entry("")

        return self.storage.keys.map{ Key(stringValue: $0)! }
    }

    func contains(_ key: Key) -> Bool {
        Log.entry("")

        return self.storage.keys.contains(key.stringValue)
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        Log.entry("")

        let debugDescription = "_DBusDecoder.KeyedContainer.decodeNil(): DBus does not support nil values"
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
        throw DecodingError.typeMismatch(Any.self, context)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        Log.entry("")

        guard let container = self.storage[key.stringValue] else {
            throw RuntimeError.generic("Could not find key \(key)")
        }
        let decoder = DBusDecoder()
        let value = try decoder.decode(T.self, decodingContainer: container)

        return value
    }


    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        Log.entry("")

        let k = AnyCodingKey(key)
        guard let container = self.storage[k.stringValue] else {
            throw RuntimeError.generic("Could not find key \(k)")
        }

        guard let unkeyedContainer = container as? _DBusDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return unkeyedContainer
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")

        let k = AnyCodingKey(key)
        guard let container = self.storage[k.stringValue] else {
            throw RuntimeError.generic("Could not find key \(k)")
        }

        guard let keyedContainer = container as? _DBusDecoder.KeyedContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return KeyedDecodingContainer(keyedContainer)
    }

    func superDecoder() throws -> Decoder {
        Log.entry("")
        fatalError("Unimplemented") // What does this even mean?
        /*

        return try _DBusDecoder(userInfo: self.userInfo, msgIter: self.msgIter) */
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        Log.entry("")
        fatalError("Unimplemented") // What does this even mean?

        /*
        let decoder = try _DBusDecoder(userInfo: self.userInfo, msgIter: self.msgIter)
        decoder.codingPath = [key]

        return decoder*/
    }
}
