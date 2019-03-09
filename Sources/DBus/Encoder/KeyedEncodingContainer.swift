import Foundation
import CDBus
import LoggerAPI

class DummyKeyedEncodingContainer<Key> where Key: CodingKey {
    var codingPath: [CodingKey]
    var count: Int = 0
    let problem: String

    init(codingPath: [CodingKey], problem: String) {
        Log.entry("")
        self.codingPath = codingPath
        self.problem = problem
    }

    func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        Log.entry("")
        return self.codingPath + [key]
    }
}

extension DummyKeyedEncodingContainer: KeyedEncodingContainerProtocol {
    func _throw() throws {
        let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: problem)
        let value: Any? = nil
        throw EncodingError.invalidValue(value as Any, context)
    }

    func encodeNil(forKey key: Key) throws {
        try _throw()
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        try _throw()
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = DummyKeyedEncodingContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key),
                                                               problem: self.problem)
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return DummyUnkeyedEncodingContainer(codingPath: self.codingPath, problem: self.problem)
    }

    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME
    }

    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Unimplemented") // FIXME
    }

}

extension _DBusEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        // private var storage: [AnyCodingKey: _DBusEncodingContainer] = [:]

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        let sigIter: DBusSignatureIter

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            Log.entry("")
            return self.codingPath + [key]
        }

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter, sigIter: DBusSignatureIter) {
            Log.entry("")
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = sigIter
        }

        deinit {
            Log.entry("")
        }
    }
}

extension _DBusEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        Log.entry("")
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        Log.entry("")
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }

    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        Log.entry("")
        let container = _DBusEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                          userInfo: self.userInfo, msgIter: msgIter, sigIter: sigIter)
        // self.storage[AnyCodingKey(key)] = container
        return container
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        Log.entry("")
        let container = _DBusEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                      userInfo: self.userInfo, msgIter: msgIter, sigIter: sigIter)
        // self.storage[AnyCodingKey(key)] = container

        return container
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")
        let container = _DBusEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key),
                                                               userInfo: self.userInfo, msgIter: msgIter, sigIter: sigIter)
        // self.storage[AnyCodingKey(key)] = container

        return KeyedEncodingContainer(container)
    }

    func superEncoder() -> Encoder {
        Log.entry("")
        fatalError("Unimplemented") // FIXME
    }

    func superEncoder(forKey key: Key) -> Encoder {
        Log.entry("")
        fatalError("Unimplemented") // FIXME
    }
}

extension _DBusEncoder.KeyedContainer: _DBusEncodingContainer {
}
