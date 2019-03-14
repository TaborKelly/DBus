import Foundation
import LoggerAPI

/**
 An object that decodes instances of a data type fromDBus objects.
 */
final public class DBusDecoder {
    public init() {}

    /**
     A dictionary you use to customize the decoding process
     by providing contextual information.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns a value of the type you specify,
     decoded from a DBusMessage.

     - Parameters:
        - type: The type of the value to decode from the suppliedDBus object.
        - from: The DBusMessage to decode.
     - Throws: An appropriate DecodingError
     */
    public func decode<T>(_ type: T.Type, from message: DBusMessage) throws -> T where T : Decodable {
        Log.entry("")

        let messageIter = DBusMessageIter(iterating: message)
        return try self.decode(type, from: messageIter)
    }

    /**
     Returns a value of the type you specify,
     decoded from a DBusMessageIter.

     - Parameters:
     - type: The type of the value to decode from the supplied DBusMessageIter.
     - from: The DBusMessageIter to decode from.
     - Throws: An appropriate DecodingError
     if the data is not validDBus.
     */
    public func decode<T>(_ type: T.Type, from messageIter: DBusMessageIter) throws -> T where T : Decodable {
        Log.entry("")

        let decoder = try _DBusDecoder(userInfo: self.userInfo, msgIter: messageIter)
        try decoder.dbusDecode()

        return try T(from: decoder)
    }

    // For iternal use
    func decode<T>(_ type: T.Type, decodingContainer: DBusDecodingContainer) throws -> T where T : Decodable {
        Log.entry("")

        let decoder = try _DBusDecoder(userInfo: self.userInfo, decodingContainer: decodingContainer)

        return try T(from: decoder)
    }
}

final class _DBusDecoder {
    var codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any]
    var container: DBusDecodingContainer?
    private var msgIter: DBusMessageIter
    private var sigIter: DBusSignatureIter

    init(userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) throws {
        Log.entry("")

        self.userInfo = userInfo
        self.msgIter = msgIter
        self.sigIter = try DBusSignatureIter(msgIter.getSignature())
    }

    init(userInfo: [CodingUserInfoKey : Any], decodingContainer: DBusDecodingContainer) throws {
        Log.entry("")

        self.userInfo = userInfo
        self.container = decodingContainer

        // dummy values, we won't need them
        self.msgIter = DBusMessageIter()
        self.sigIter = try DBusSignatureIter("")
    }

    // TODO: variant case
    func dbusDecode() throws {
        let t = try self.sigIter.getCurrentType()
        switch t {
        case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor, .string,
             .objectPath, .signature:
            container = try _DBusDecoder.SingleValueContainer(codingPath: codingPath, userInfo: userInfo, msgIter: msgIter)
        case .array:
            container = try _DBusDecoder.UnkeyedContainer(codingPath: codingPath, userInfo: userInfo, msgIter: msgIter)
        case .struct:
            container = try _DBusDecoder.UnkeyedContainer(codingPath: codingPath, userInfo: userInfo, msgIter: msgIter)
        case .dictionaryEntry:
            let debugDescription = "_DBusDecoder.dbusDecode(): encountered a naked dictionary."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.dataCorrupted(context)
        default:
            throw RuntimeError.generic("Unhandeled case in _DBusDecoder.dbusDecode() for t: \(t)")
        }

        guard let c = container else {
            throw RuntimeError.generic("Logic error in _DBusDecoder.dbusDecode()")
        }
        try c.dbusDecode()
    }
}

extension _DBusDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        Log.entry("")
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        Log.entry("")
        /*
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(dbusMessage: self.dbusMessage, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedDecodingContainer(container)
 */
        let container = DummyKeyedDecodingContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo,
                                                         signature: msgIter.getSignature())
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        Log.entry("")

        // we never expect this to fail
        guard let c = container else {
            let signature = "_DBusDecoder.unkeyedContainer(): container is nil, DBus decoding failed?"
            return DummyUnkeyedDecodingContainer(codingPath: self.codingPath, userInfo: self.userInfo,
                                                 signature: signature)
        }

        if c is UnkeyedDecodingContainer {
            return c as! UnkeyedDecodingContainer
        } else {
            return DummyUnkeyedDecodingContainer(codingPath: self.codingPath, userInfo: self.userInfo,
                                                 signature: msgIter.getSignature())
        }
    }

    func singleValueContainer() -> SingleValueDecodingContainer {
        Log.entry("")

        // we never expect this to fail
        guard let c = container else {
            let signature = "_DBusDecoder.singleValueContainer(): container is nil, DBus decoding failed?"
            return DummySingleValueDecodingContainer(codingPath: self.codingPath, userInfo: self.userInfo,
                                                     signature: signature)
        }

        if c is SingleValueDecodingContainer {
            return c as! SingleValueDecodingContainer
        } else {
            return DummySingleValueDecodingContainer(codingPath: self.codingPath, userInfo: self.userInfo,
                                                     signature: msgIter.getSignature())
        }
    }
}

protocol DBusDecodingContainer: class {
    var codingPath: [CodingKey] { get /*set*/ }
    var userInfo: [CodingUserInfoKey : Any] { get }
    var msgIter: DBusMessageIter { get /*set*/ } // TODO: remove.

    // Decode the DBus values, but DO NOT ADVANCE THE (outermost) ITERATOR
    func dbusDecode() throws
}
