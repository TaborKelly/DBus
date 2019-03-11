import Foundation
import CDBus
import LoggerAPI

extension _DBusEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        private var storage: [AnyCodingKey: _DBusEncodingContainer] = [:]

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            Log.entry("")
            return self.codingPath + [key]
        }

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

extension _DBusEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        Log.entry("")

        // We can't enocde a nil value in DBus, but we might get them for keyed containers. Go ahead and return without
        // encoding the value as that is the best that we can do.
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        Log.entry("")

        let container = _DBusEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                          userInfo: self.userInfo)
        self.storage[AnyCodingKey(key)] = container

        try container.encode(value)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        Log.entry("")
        let container = _DBusEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(forKey: key),
                                                      userInfo: self.userInfo)
        self.storage[AnyCodingKey(key)] = container

        return container
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")

        let container = _DBusEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key),
                                                               userInfo: self.userInfo)
        self.storage[AnyCodingKey(key)] = container

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
    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        // First do some house cleaning and type checking
        let sigArrayIter = try sigIter.recurse()
        let t = try sigIter.getCurrentType()
        switch t {
        case .array:
            break
        default:
            throw RuntimeError.generic("_DBusEncoder.KeyedContainer.dbusEncode() can't encode \(t) for path \(codingPath)")
        }
        // subT needs to contain a dict
        let subT = try sigArrayIter.getCurrentType()
        switch subT {
        case .dictionaryEntry:
            break
        default:
            throw RuntimeError.generic("_DBusEncoder.KeyedContainer.dbusEncode() can't encode \(t) for path \(codingPath)")
        }
        let sigDictIter = try sigArrayIter.recurse()
        let sigValueIter = try sigArrayIter.recurse()
        if sigValueIter.next() == false {
            throw RuntimeError.generic("_DBusEncoder.KeyedContainer.dbusEncode() failed to deduce value type for path \(codingPath)")
        }

        // Then actually open the array
        let msgArrayIter = try msgIter.openContainer(containerType: .array, containedSignature: sigArrayIter.getSignature())

        for c in storage {
            // Then open a dict
            let msgDictIter = try msgArrayIter.openContainer(containerType: .dictionaryEntry,
                                                             containedSignature: nil)

            try encodeKey(msgIter: msgDictIter, sigIter: sigDictIter, c.key)
            try encodeValue(msgIter: msgDictIter, sigIter: sigValueIter, c.value)

            // Close the dict
            let b = Bool(dbus_message_iter_close_container(&msgArrayIter.iter, &msgDictIter.iter))
            if b == false {
                throw RuntimeError.generic("dbus_message_iter_close_container() failed in _DBusEncoder.KeyedContainer.dbusEncode()")
            }
        }

        // Finally, close the array
        let b = Bool(dbus_message_iter_close_container(&msgIter.iter, &msgArrayIter.iter))
        if b == false {
            throw RuntimeError.generic("dbus_message_iter_close_container() failed in _DBusEncoder.KeyedContainer.dbusEncode()")
        }
    }

    func encodeKey(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ key: AnyCodingKey) throws {
        try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                              codingPath: codingPath, key.stringValue)
    }

    func encodeValue(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: _DBusEncodingContainer) throws {
        try value.dbusEncode(msgIter: msgIter, sigIter: sigIter)
    }
}
