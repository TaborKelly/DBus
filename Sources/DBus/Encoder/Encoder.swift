import Foundation
import CDBus
import LoggerAPI

/**
 An object that encodes instances of a data type as DBus objects.

 NOTE: Today, we encode in place. That is, we call value.encode(to: _DBusEncoder) and the Codeable framework calls us
       back a bunch of times. At the same time we construct the DBusMessage. However, this choice may not be optimal?
       We could instead let the Codeable framework calls us to describe the data we are to encode, then construct the
       message right before we return. We could probably cut down on our error handling that way?
 */
final public class DBusEncoder {
    public init() {
        Log.entry("")
    }

    deinit {
        Log.entry("")
    }

    /**
     A dictionary you use to customize the encoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns a DBus-encoded representation of the value you supply.

     - Parameters:
        - value: The value to encode as DBus.
     - Throws: `EncodingError.invalidValue(_:_:)`
                if the value can't be encoded as a DBus object.
     */
    public func encode(_ value: Encodable, to: DBusMessage, signature: String) throws {
        Log.entry("")

        let encoder = _DBusEncoder()
        encoder.userInfo = self.userInfo

        try value.encode(to: encoder)

        let msgIter = DBusMessageIter(appending: to)
        let sigIter = try DBusSignatureIter(signature)
        try encoder.dbusEncode(msgIter: msgIter, sigIter: sigIter)

        return
    }
}

protocol _DBusEncodingContainer {
    // This is where the actual DBus encoding takes place.
    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter) throws
}

class _DBusEncoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    fileprivate var container: _DBusEncodingContainer?

    func dbusEncode(msgIter: DBusMessageIter, sigIter: DBusSignatureIter) throws {
        try container?.dbusEncode(msgIter: msgIter, sigIter: sigIter)

    }
}

extension _DBusEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        Log.entry("")
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        Log.entry("")
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        Log.entry("")
        assertCanCreateContainer()

        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        Log.entry("")
        assertCanCreateContainer()

        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }
}
