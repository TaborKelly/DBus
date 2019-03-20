import Foundation
import LoggerAPI

/**
 An object that decodes instances of a data type from DBus messages (DBusMessage).
 */
final public class DBusDecoder {
    public init() {}

    /// A dictionary you use to customize the decoding process by providing contextual information.
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     Returns a value of the type you specify, decoded from a DBusMessage.

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
     Returns a value of the type you specify, decoded from a DBusMessageIter.

     - Parameters:
         - type: The type of the value to decode from the supplied DBusMessageIter.
         - from: The DBusMessageIter to decode from.
     - Throws: An appropriate DecodingError if the data is not valid DBus.
     */
    public func decode<T>(_ type: T.Type, from messageIter: DBusMessageIter) throws -> T where T : Decodable {
        Log.entry("")

        let decoder = _DBusDecoder(userInfo: self.userInfo, msgIter: messageIter)
        try decoder.dbusDecode()

        return try T(from: decoder)
    }

    // For iternal use
    func decode<T>(_ type: T.Type, decodingContainer: DBusDecodingContainer) throws -> T where T : Decodable {
        Log.entry("")

        let decoder = _DBusDecoder(userInfo: self.userInfo, decodingContainer: decodingContainer)

        return try T(from: decoder)
    }
}

final class _DBusDecoder {
    var codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any]

    // The outermost _DBusDecoder decodes from the DBusMessageIter, but _DBusDecoder can be instantiated recusively in
    // which case the children will use DBusDecodingContainer.
    var container: DBusDecodingContainer?
    private var msgIter: DBusMessageIter?

    init(userInfo: [CodingUserInfoKey : Any], msgIter: DBusMessageIter) {
        Log.entry("")

        self.userInfo = userInfo
        self.msgIter = msgIter
    }

    init(userInfo: [CodingUserInfoKey : Any], decodingContainer: DBusDecodingContainer) {
        Log.entry("")

        self.userInfo = userInfo
        self.container = decodingContainer
     }

    func dbusDecode() throws {
        guard let msgIter = self.msgIter else {
            throw RuntimeError.logicError("_DBusDecoder.dbusDecode(): self.msgIter is nil!")
        }

        self.container = try decodeValue(codingPath: self.codingPath, userInfo: self.userInfo, msgIter: msgIter)
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

        // The simple case where self.container is a DBusSingleValueContainer
        if let container = self.container as? DBusSingleValueContainer {
            guard let storage = container.storage else {
                let debugDescription = "Cannot get single value decoding container: storage nil!"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.valueNotFound(DBusSingleValueContainer.self, context)
            }

            return _DBusDecoder.SingleValueContainer(codingPath: container.codingPath,
                                                     userInfo: container.userInfo,
                                                     storage: storage)
        // The complex case where we are decoding a complex value (like a Map) into a single value.
        } else {
            guard let container = self.container else {
                // This should never happen
                let debugDescription = "self.container was nil!"
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
                throw DecodingError.valueNotFound(DBusSingleValueContainer.self, context)
            }

            let storage = SingleValueDecoderStorage.container(container)
            return _DBusDecoder.SingleValueContainer(codingPath: container.codingPath,
                                                     userInfo: container.userInfo,
                                                     storage: storage)
        }
    }
}

protocol DBusDecodingContainer: class {
    var codingPath: [CodingKey] { get /*set*/ }
    var userInfo: [CodingUserInfoKey : Any] { get }

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
        container = _DBusDecoder.DBusSingleValueContainer(codingPath: codingPath, userInfo: userInfo,
                                                          msgIter: msgIter)

    case .array:
        let arrayContentsType = try msgIter.getElementType()
        if arrayContentsType == .dictionaryEntry {
            container = try _DBusDecoder.DBusKeyedContainer(codingPath: codingPath, userInfo: userInfo,
                                                            msgIter: msgIter)
        } else {
            container = _DBusDecoder.DBusUnkeyedContainer(codingPath: codingPath, userInfo: userInfo, msgIter: msgIter)
        }

    case .struct:
        container = _DBusDecoder.DBusUnkeyedContainer(codingPath: codingPath, userInfo: userInfo,
                                                      msgIter: msgIter)

    default:
        let debugDescription = "decodeValue(): does not understand this data."
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: debugDescription)
        throw DecodingError.dataCorrupted(context)
    }

    try container.dbusDecode()
    return container
}
