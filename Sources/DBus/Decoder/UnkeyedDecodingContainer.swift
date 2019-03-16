import Foundation
import LoggerAPI

//
// This is where the code lives to actually decode the DBus message.
//
extension _DBusDecoder {
    final class DBusUnkeyedContainer: DBusDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        var storage: [DBusDecodingContainer] = []

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
        }

        var nestedCodingPath: [CodingKey] {
            Log.entry("")

            return self.codingPath + [AnyCodingKey(intValue: storage.count)]
        }

        func dbusDecode() throws {
            let msgSubIter: DBusMessageIter

            let outerType = try self.msgIter.getType()
            switch outerType {
            case .array, .struct:
                msgSubIter = try self.msgIter.recurse()
                let _ = msgIter.next()
            default:
                throw RuntimeError.generic("Unhandeled case in _DBusDecoder.UnkeyedContainer.dbusDecode()")
            }

            repeat {
                let container = try decodeValue(codingPath: nestedCodingPath, userInfo: userInfo, msgIter: msgSubIter)
                        try container.dbusDecode()
                storage.append(container)
            } while msgSubIter.next()
        }
    }
}

extension _DBusDecoder {
    final class UnkeyedContainer: UnkeyedDecodingContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let storage: [DBusDecodingContainer]?
        var currentIndex: Int = 0

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], storage: [DBusDecodingContainer]?) {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }

        var count: Int? {
            guard let storage = self.storage else {
                return nil
            }
            return storage.count
        }

        var isAtEnd: Bool {
            guard let count = self.count else {
                return true
            }

            return currentIndex >= count
        }

        func checkCanDecodeValue() throws {
            guard !self.isAtEnd else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }
        }

        func decodeNil() throws -> Bool {
            Log.entry("")

            let debugDescription = "_DBusDecoder.UnkeyedContainer.decodeNil(): DBus does not support nil values."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.typeMismatch(Any.self, context)
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            Log.entry("")

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.UnkeyedContainer.decode<T>(): wrong container type."
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Any.self, context)
            }

            try checkCanDecodeValue()
            defer { self.currentIndex += 1 }

            let container = storage[self.currentIndex]
            let decoder = DBusDecoder()
            let value = try decoder.decode(T.self, decodingContainer: container)

            return value
        }

        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            Log.entry("")
            try checkCanDecodeValue()
            defer { self.currentIndex += 1 }

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.UnkeyedContainer.nestedUnkeyedContainer(): wrong container type."
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Any.self, context)
            }

            let container = storage[self.currentIndex] as! _DBusDecoder.UnkeyedContainer

            return container
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            Log.entry("")
            try checkCanDecodeValue()
            defer { self.currentIndex += 1 }

            guard let storage = self.storage else {
                let debugDescription = "_DBusDecoder.UnkeyedContainer.nestedContainer<NestedKey>(): wrong container type."
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.typeMismatch(Any.self, context)
            }

            let container = storage[self.currentIndex] as! _DBusDecoder.KeyedContainer<NestedKey>

            return KeyedDecodingContainer(container)
        }

        func superDecoder() throws -> Decoder {
            Log.entry("")
            fatalError("Unimplemented") // What does this even mean?
            // return try _DBusDecoder(userInfo: self.userInfo, msgIter: self.msgIter)
        }
    }
}
