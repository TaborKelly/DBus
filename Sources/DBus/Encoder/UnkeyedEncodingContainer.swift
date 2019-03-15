import Foundation
import CDBus
import LoggerAPI

extension _DBusEncoder {
    //
    // The Apple Codeable framework calls this class. It is split into two extensions (see below).
    //
    final class UnkeyedContainer {
        private var storage: [_DBusEncodingContainer] = []

        var count: Int {
            Log.entry("")
            return storage.count
        }

        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            Log.entry("")
            return self.codingPath + [AnyCodingKey(intValue: self.count)]
        }

        var userInfo: [CodingUserInfoKey: Any]

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

//
// This is the code that the Apple Codeable framework calls. We really just save the data that we ware about for later
// use (in storage).
//
extension _DBusEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        Log.entry("")

        let context = EncodingError.Context(codingPath: self.codingPath,
                                            debugDescription: "DBus can not encode nil values")
        let value: Any? = nil
        throw EncodingError.invalidValue(value as Any, context)
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        Log.entry("")

        var container = self.nestedSingleValueContainer()
        try container.encode(value)
    }

    // just a private helper function for encodeNil() and encode<T>(_ value: T)
    private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        Log.entry("")

        let container = _DBusEncoder.SingleValueContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)

        return container
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")

        let container = _DBusEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath,
                                                               userInfo: self.userInfo)
        self.storage.append(container)

        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        Log.entry("")

        let container = _DBusEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo)
        self.storage.append(container)

        return container
    }

    func superEncoder() -> Encoder {
        Log.entry("")
        fatalError("Unimplemented") // FIXME
    }
}

//
// The actualy DBus encoding happens here
//
extension _DBusEncoder.UnkeyedContainer: _DBusEncodingContainer {
    func dbusEncode(msgIter msgIterIn: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        Log.entry("")

        // This is a little tricky, but it is here to deal with the variant case
        let msgIter: DBusMessageIter
        let sigSubIter: DBusSignatureIter
        let t = try sigIter.getCurrentType()
        let unkeyedType: DBusType
        if t == .variant {
            msgIter = try msgIterIn.openContainer(containerType: .variant,
                                                  containedSignature: "av")
            sigSubIter = try DBusSignatureIter("v")
            unkeyedType = .array
        } else {
            msgIter = msgIterIn
            sigSubIter = try sigIter.recurse()
            switch t {
            case .array:
                unkeyedType = .array
            case .struct:
                unkeyedType = .struct
                break
            default:
                throw RuntimeError.generic("_DBusEncoder.UnkeyedContainer.dbusEncode() can't encode \(t) for path \(codingPath)")
            }
        }

        // Then actually open the array (or DBus struct). But we open it slightly different for the struct, so
        // calculate the containedSignature.
        var containedSignature: String? = nil
        if unkeyedType == .array {
            containedSignature = sigSubIter.getSignature()
        }
        let msgSubIter = try msgIter.openContainer(containerType: unkeyedType, containedSignature: containedSignature)

        // Now append all the elements
        for c in storage {
            try c.dbusEncode(msgIter: msgSubIter, sigIter: sigSubIter)
        }

        // Finally close the container
        let b = Bool(dbus_message_iter_close_container(&msgIter.iter, &msgSubIter.iter))
        if b == false {
            throw RuntimeError.generic("dbus_message_iter_close_container() failed in _DBusEncoder.UnkeyedContainer.dbusEncode()")
        }

        if t == .variant {
            // Close the variant
            let b = Bool(dbus_message_iter_close_container(&msgIterIn.iter, &msgIter.iter))
            if b == false {
                throw RuntimeError.generic("dbus_message_iter_close_container() failed in _DBusEncoder.UnkeyedContainer.dbusEncode()")
            }
        }
    }
}
