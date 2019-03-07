import Foundation
import CDBus
import LoggerAPI

/**
 An object that encodes instances of a data type as DBus objects.
 */
final public class DBusEncoder {
    public init() {
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
    public func encode(_ value: Encodable, to: DBusMessage) throws {
        Log.entry("")
        let encoder = try _DBusEncoder(to: to)
        encoder.userInfo = self.userInfo

        try value.encode(to: encoder)

        return
    }
}

protocol _DBusEncodingContainer {
}

class _DBusEncoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var firstContainer = true
    fileprivate var container: _DBusEncodingContainer?
    let iter: DBusMessageIter

    init(to: DBusMessage) throws {
        Log.entry("")
        iter = DBusMessageIter(appending: to)
    }

    init(iter: DBusMessageIter) throws {
        Log.entry("")
        self.iter = iter
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

        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo, iter: iter)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        Log.entry("")
        assertCanCreateContainer()

        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo, iter: iter)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        Log.entry("")
        assertCanCreateContainer()

        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo, iter: iter)
        self.container = container

        return container
    }
}
