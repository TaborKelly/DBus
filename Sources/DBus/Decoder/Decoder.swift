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
        self.msgIter = msgIter // TODO: make optional
        self.sigIter = try DBusSignatureIter(msgIter.getSignature()) // TODO: remove
    }

    init(userInfo: [CodingUserInfoKey : Any], decodingContainer: DBusDecodingContainer) throws {
        Log.entry("")

        self.userInfo = userInfo
        self.container = decodingContainer

        // dummy values, we won't need them
        self.msgIter = DBusMessageIter()
        self.sigIter = try DBusSignatureIter("")
    }

    func dbusDecode() throws {
        self.container = try decodeValue(codingPath: self.codingPath, userInfo: self.userInfo, msgIter: self.msgIter)
    }
}

extension _DBusDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        Log.entry("")
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        Log.entry("")

        guard let container = self.container as? DBusKeyedContainer else {
            let debugDescription = "Cannot get keyed decoding container."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(KeyedContainer<Key>.self, context)
        }

        let c = _DBusDecoder.KeyedContainer<Key>(codingPath: self.codingPath,
                                                 userInfo: self.userInfo,
                                                 storage: container.storage)
        return KeyedDecodingContainer(c)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        Log.entry("")

        guard let container = self.container as? DBusUnkeyedContainer else {
            let debugDescription = "Cannot get unkeyed decoding container."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(UnkeyedContainer.self, context)
        }

        return _DBusDecoder.UnkeyedContainer(codingPath: container.codingPath,
                                             userInfo: container.userInfo,
                                             storage: container.storage)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        Log.entry("")

        // single value container with basic type
        if let dbusSingleValueContainer = container as? DBusSingleValueContainer {
            return _DBusDecoder.SingleValueContainer(codingPath: dbusSingleValueContainer.codingPath,
                                                     userInfo: dbusSingleValueContainer.userInfo,
                                                     storage: dbusSingleValueContainer.storage)
        // single value container with complex type
        } else if let container = self.container {
            return _DBusDecoder.SingleValueContainer(codingPath: container.codingPath,
                                                     userInfo: container.userInfo,
                                                     storage: .container(container))
        } else { // error case
            let debugDescription = "Cannot get single value decoding container."
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
            throw DecodingError.valueNotFound(SingleValueContainer.self, context)
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

func decodeValue(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any],
                 msgIter msgIterIn: DBusMessageIter) throws -> DBusDecodingContainer {
    Log.entry("")

    // This is slightly complicated but is here to deal with the variant case
    var valueType = try msgIterIn.getType()
    var msgIter: DBusMessageIter
    if valueType == .variant {
        msgIter = try msgIterIn.recurse()
        valueType = try msgIter.getType()
    } else {
        msgIter = msgIterIn
    }

    let container: DBusDecodingContainer
    switch valueType {
    case .byte, .boolean, .int16, .uint16, .int32, .uint32, .int64, .uint64, .double, .fileDescriptor,
         .string, .objectPath, .signature:
        container = try _DBusDecoder.DBusSingleValueContainer(codingPath: codingPath, userInfo: userInfo,
                                                              msgIter: msgIter)

    case .array:
        let arrayContentsType = try msgIter.getElementType()
        if arrayContentsType == .dictionaryEntry {
            container = try _DBusDecoder.DBusKeyedContainer(codingPath: codingPath, userInfo: userInfo,
                                                            msgIter: msgIter)
        } else {
            container = try _DBusDecoder.DBusUnkeyedContainer(codingPath: codingPath, userInfo: userInfo, msgIter: msgIter)
        }
    case .struct:
        container = try _DBusDecoder.DBusUnkeyedContainer(codingPath: codingPath, userInfo: userInfo,
                                                          msgIter: msgIter)

    default:
        throw RuntimeError.generic("Unhandeled case in decodeValue()")
    }

    try container.dbusDecode()
    return container
}
