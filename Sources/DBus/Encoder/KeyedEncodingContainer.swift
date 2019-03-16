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
    func dbusEncode(msgIter msgIterIn: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        Log.entry("")

        // This is a little tricky, but it is here to deal with the variant case
        let msgIter: DBusMessageIter
        let tempIter: DBusSignatureIter
        var msgVariantIter: DBusMessageIter? = nil

        // First do some house cleaning and type checking
        let sigArrayIter: DBusSignatureIter
        let t = try sigIter.getCurrentType()
        switch t {
        // The normal case, where the user tells us our signature
        case .array: // a{si}, a{ss}, a{sv}, etc
            msgIter = msgIterIn
            sigArrayIter = try sigIter.recurse() // {si}, {ss}, {sv}, etc
        // The hard/weird case, where we are encocding into a "v"
        case .variant:
            // synthesize our own type
            // libdbus won't let us create an incomplete type (eg, {"sv}"), so we need the tempIter
            tempIter = try DBusSignatureIter("a{sv}")
            sigArrayIter = try tempIter.recurse()
            msgVariantIter = try msgIterIn.openContainer(containerType: .variant, containedSignature: tempIter.getSignature())
            msgIter = msgVariantIter!

        default:
            let debugDescription = "Swift doesn't know what to do with a key of type boolean!"
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            let any: Any? = nil
            throw EncodingError.invalidValue(any as Any, context)
        }

        // Just some signature checking
        // subType needs to contain a dict
        let subType = try sigArrayIter.getCurrentType()
        switch subType {
        case .dictionaryEntry:
            break
        default:
            let debugDescription = "_DBusEncoder.KeyedContainer.dbusEncode() can't encode \(t) for path \(codingPath)"
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            let any: Any? = nil
            throw EncodingError.invalidValue(any as Any, context)
        }

        let sigDictIter = try sigArrayIter.recurse()
        let sigValueIter = try sigArrayIter.recurse()
        if sigValueIter.next() == false {
            let debugDescription = "_DBusEncoder.KeyedContainer.dbusEncode() failed to deduce value type for path \(codingPath)"
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            let any: Any? = nil
            throw EncodingError.invalidValue(any as Any, context)
        }

        Log.debug("sigIter.getSignature() \(sigIter.getSignature())")
        Log.debug("sigArrayIter.getSignature() \(sigArrayIter.getSignature())")
        Log.debug("sigDictIter.getSignature() \(sigDictIter.getSignature())")
        Log.debug("sigValueIter.getSignature() \(sigValueIter.getSignature())")

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
                throw RuntimeError.logicError("dbus_message_iter_close_container() failed in _DBusEncoder.KeyedContainer.dbusEncode()")
            }
        }

        // Finally, close the array
        let b = Bool(dbus_message_iter_close_container(&msgIter.iter, &msgArrayIter.iter))
        if b == false {
            throw RuntimeError.logicError("dbus_message_iter_close_container() failed in _DBusEncoder.KeyedContainer.dbusEncode()")
        }

        // If necessary, close the variant
        if msgVariantIter != nil {
            let b = Bool(dbus_message_iter_close_container(&msgIterIn.iter, &msgIter.iter))
            if b == false {
                throw RuntimeError.logicError("dbus_message_iter_close_container() failed in _DBusEncoder.KeyedContainer.dbusEncode()")
            }
        }
    }

    func encodeKey(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ key: AnyCodingKey) throws {
        let t = try sigIter.getCurrentType()
        switch t {
        case .byte, .int16, .uint16, .int32, .uint32, .int64, .uint64, .fileDescriptor:
            guard let i = key.intValue else {
                let debugDescription = "_DBusEncoder.KeyedContainer(): Swift did not provide an integer key value!"
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                let any: Any? = nil
                throw EncodingError.invalidValue(any as Any, context)
            }
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, i)
        case .string, .objectPath, .signature:
            try _DBusEncoder.SingleValueContainer.dbusEncodeBasic(msgIter: msgIter, sigIter: sigIter,
                                                                  codingPath: codingPath, key.stringValue)

        default:
            let debugDescription = "_DBusEncoder.KeyedContainer(): Swift doesn't know how to encode a key type of \(t)."
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            let any: Any? = nil
            throw EncodingError.invalidValue(any as Any, context)
        }
    }

    func encodeValue(msgIter: DBusMessageIter, sigIter: DBusSignatureIter, _ value: _DBusEncodingContainer) throws {
        try value.dbusEncode(msgIter: msgIter, sigIter: sigIter)
    }
}
