import Foundation
import LoggerAPI

extension _DBusDecoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        let sigIter: DBusSignatureIter
        var storage: [DBusDecodingContainer] = []
        var currentIndex: Int = 0

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) throws {
            Log.entry("")

            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = try DBusSignatureIter(msgIter.getSignature())
        }

        var count: Int? {
            return storage.count
        }

        var nestedCodingPath: [CodingKey] {
            Log.entry("")

            return self.codingPath + [AnyCodingKey(intValue: self.count ?? 0)!]
        }
    }
}

extension _DBusDecoder.UnkeyedContainer:DBusDecodingContainer {
    // TODO: variant and dictionary cases
    func dbusDecode() throws {
        let msgSubIter: DBusMessageIter
        var sigSubIter: DBusSignatureIter

        let outerType = try self.sigIter.getCurrentType()
        switch outerType {
        case .array, .struct:
            msgSubIter = try self.msgIter.recurse()
            sigSubIter = try self.sigIter.recurse()
            let _ = msgIter.next()
        default:
            throw RuntimeError.generic("Unhandeled case in _DBusDecoder.UnkeyedContainer.dbusDecode()")
        }

        let innerType = try sigSubIter.getCurrentType()
        repeat {
            switch innerType {
            case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor,
                 .string, .objectPath, .signature:
                    let container = try _DBusDecoder.SingleValueContainer(codingPath: nestedCodingPath, userInfo: userInfo,
                                                                          msgIter: msgSubIter)
                    try container.dbusDecode()
                    storage.append(container)

            case .array, .struct:
                let container = try _DBusDecoder.UnkeyedContainer(codingPath: nestedCodingPath, userInfo: userInfo,
                                                                  msgIter: msgSubIter)
                try container.dbusDecode()
                storage.append(container)

            default:
                throw RuntimeError.generic("Unhandeled case in _DBusDecoder.UnkeyedContainer.dbusDecode()")
            }
        } while msgSubIter.next()
    }
}

extension _DBusDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
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
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.storage[self.currentIndex]
        let decoder = DBusDecoder()
        let value = try decoder.decode(T.self, decodingContainer: container)

        return value
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        Log.entry("")
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.storage[self.currentIndex] as! _DBusDecoder.UnkeyedContainer

        return container
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.storage[self.currentIndex] as! _DBusDecoder.KeyedContainer<NestedKey>

        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        Log.entry("")
        fatalError("Unimplemented") // What does this even mean?
        // return try _DBusDecoder(userInfo: self.userInfo, msgIter: self.msgIter)
    }
}


