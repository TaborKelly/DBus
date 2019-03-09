import Foundation
import CDBus
import LoggerAPI

final class DummyUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    var count: Int = 0
    let problem: String

    init(codingPath: [CodingKey], problem: String) {
        Log.entry("")
        self.codingPath = codingPath
        self.problem = problem
    }

    var nestedCodingPath: [CodingKey] {
        Log.entry("")
        return self.codingPath + [AnyCodingKey(intValue: self.count)!]
    }
    
    func _throw() throws {
        let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: problem)
        let value: Any? = nil
        throw EncodingError.invalidValue(value as Any, context)
    }

    func encodeNil() throws {
        try _throw()
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        try _throw()
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = DummyKeyedEncodingContainer<NestedKey>(codingPath: self.nestedCodingPath, problem: "Foo")
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return DummyUnkeyedEncodingContainer(codingPath: self.nestedCodingPath, problem: "Foo")
    }

    func superEncoder() -> Encoder {
        Log.entry("")
        fatalError("Unimplemented") // FIXME
    }
}

extension _DBusEncoder {
    final class UnkeyedContainer {
        // private var storage: [_DBusEncodingContainer] = []
        private var _count = 0

        var count: Int {
            Log.entry("")
            return _count // storage.count
        }

        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            Log.entry("")
            return self.codingPath + [AnyCodingKey(intValue: self.count)!]
        }

        var userInfo: [CodingUserInfoKey: Any]
        let msgIter: DBusMessageIter
        var msgSubIter: DBusMessageIter? = nil
        let sigIter: DBusSignatureIter
        var sigSubIter: DBusSignatureIter? = nil

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter, sigIter: DBusSignatureIter) {
            Log.entry("")
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.msgIter = msgIter
            self.sigIter = sigIter
            // This is complicated because we can't throw
            self.sigSubIter = try? self.sigIter.recurse()
            if let sub = self.sigSubIter { // if we have a sigSubIter, then we really can recurse into this type
                if let t = try? sigIter.getCurrentType() { // this should always succeed
                    self.msgSubIter = try? self.msgIter.openContainer(containerType: t, containedSignature: sub.getSignature())
                }
            }
        }

        deinit {
            Log.entry("")
            if let sub = msgSubIter {
                let b = Bool(dbus_message_iter_close_container(&msgIter.iter, &sub.iter))
                if b == false {
                    Log.error("dbus_message_iter_close_container() failed!")
                }
            }
        }

        private func checkCanEncode(value: Any?) throws {
            Log.entry("")
            if self.sigSubIter == nil {
                let t = try sigIter.getCurrentType()
                let debugDescription = "UnkeyedContainer could not create a sigSubIter for \(t) in \(sigIter.getSignature())"
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw EncodingError.invalidValue(value as Any, context)
            }
            if self.msgSubIter == nil {
                let t = try sigIter.getCurrentType()
                let debugDescription = "UnkeyedContainer could not create a msgSubIter for \(t) in \(sigIter.getSignature())"
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw EncodingError.invalidValue(value as Any, context)
            }

        }
    }
}

extension _DBusEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        Log.entry("")
        var container = self.nestedSingleValueContainer()
        try container.encodeNil() // This will fail, DBus does not support Nil values
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        Log.entry("")
        try checkCanEncode(value: nil)
        var container = self.nestedSingleValueContainer()
        try container.encode(value)
    }

    // just a private helper function for encodeNil() and encode<T>(_ value: T)
    private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        Log.entry("")
        guard let msg = msgSubIter else {
            return DummySingleValueEncodingContainer(codingPath: self.nestedCodingPath, problem: "Foo")
        }
        guard let sig = sigSubIter else {
            return DummySingleValueEncodingContainer(codingPath: self.nestedCodingPath, problem: "Foo")
        }
        let container = _DBusEncoder.SingleValueContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo,
                                                          msgIter: msg, sigIter: sig)
        // self.storage.append(container)
        _count += 1

        return container
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        Log.entry("")
        guard let msg = msgSubIter else {
            let container = DummyKeyedEncodingContainer<NestedKey>(codingPath: self.nestedCodingPath, problem: "Foo")
            return KeyedEncodingContainer(container)
        }
        guard let sig = sigSubIter else {
            let container = DummyKeyedEncodingContainer<NestedKey>(codingPath: self.nestedCodingPath, problem: "Foo")
            return KeyedEncodingContainer(container)
        }

        let container = _DBusEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath,
                                                               userInfo: self.userInfo, msgIter: msg, sigIter: sig)
        // self.storage.append(container)
        _count += 1

        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        Log.entry("")
        guard let msg = msgSubIter else {
            return DummyUnkeyedEncodingContainer(codingPath: self.nestedCodingPath, problem: "Foo")
        }
        guard let sig = sigSubIter else {
            return DummyUnkeyedEncodingContainer(codingPath: self.nestedCodingPath, problem: "Foo")
        }

        let container = _DBusEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath, userInfo: self.userInfo,
                                                      msgIter: msg, sigIter: sig)
        // self.storage.append(container)
        _count += 1

        return container
    }

    func superEncoder() -> Encoder {
        Log.entry("")
        fatalError("Unimplemented") // FIXME
    }
}

extension _DBusEncoder.UnkeyedContainer: _DBusEncodingContainer {
}
