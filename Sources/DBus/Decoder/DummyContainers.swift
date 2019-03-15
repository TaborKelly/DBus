import Foundation
import LoggerAPI

/*
final class DummySingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let error: Error

    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], signature: String) {
        Log.entry("")

        self.codingPath = codingPath
        self.userInfo = userInfo

        var debugDescription = "DummySingleValueDecodingContainer in use. "
        debugDescription += "Your decodable data type does not match your message \(signature)."
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
        self.error = DecodingError.typeMismatch(Any.self, context)
    }

    func decodeNil() -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        throw self.error
    }

    func decode(_ type: String.Type) throws -> String {
        throw self.error
    }

    func decode(_ type: Double.Type) throws -> Double {
        throw self.error
    }

    func decode(_ type: Float.Type) throws -> Float {
        throw self.error
    }

    func decode(_ type: Int.Type) throws -> Int {
        throw self.error
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        throw self.error
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        throw self.error
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        throw self.error
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        throw self.error
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        throw self.error
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw self.error
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw self.error
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw self.error
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw self.error
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        throw self.error
    }
}
*/
final class DummyUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let error: Error
    var count: Int? = 1
    var currentIndex: Int = 0
    var isAtEnd: Bool = false

    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], signature: String) {
        Log.entry("")

        self.codingPath = codingPath
        self.userInfo = userInfo

        var debugDescription = "DummyUnkeyedDecodingContainer in use. "
        debugDescription += "Your decodable data type does not match your message \(signature)."
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
        self.error = DecodingError.typeMismatch(Any.self, context)
    }

    func decodeNil() throws -> Bool {
        throw self.error
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        throw self.error
    }

    func decode(_ type: String.Type) throws -> String {
        throw self.error
    }

    func decode(_ type: Double.Type) throws -> Double {
        throw self.error
    }

    func decode(_ type: Float.Type) throws -> Float {
        throw self.error
    }

    func decode(_ type: Int.Type) throws -> Int {
        throw self.error
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        throw self.error
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        throw self.error
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        throw self.error
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        throw self.error
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        throw self.error
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw self.error
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw self.error
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw self.error
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw self.error
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        throw self.error
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw self.error
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw self.error
    }

    func superDecoder() throws -> Decoder {
        throw self.error
    }
}

final class DummyKeyedDecodingContainer<Key> where Key: CodingKey {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let error: Error

    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], signature: String) {
        Log.entry("")

        self.codingPath = codingPath
        self.userInfo = userInfo

        var debugDescription = "DummyKeyedDecodingContainer in use. "
        debugDescription += "Your decodable data type does not match your message \(signature)."
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: debugDescription)
        self.error = DecodingError.typeMismatch(Any.self, context)
    }
}

extension DummyKeyedDecodingContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return [Key(stringValue: "Foo")!]
    }

    func contains(_ key: Key) -> Bool {
        return false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        throw self.error
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        throw self.error
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        throw self.error
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        throw self.error
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        throw self.error
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        throw self.error
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw self.error
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw self.error
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        throw self.error
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        throw self.error
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        throw self.error
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw self.error
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw self.error
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        throw self.error
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        throw self.error
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        throw self.error
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw self.error
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw self.error
    }

    func superDecoder() throws -> Decoder {
        throw self.error
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw self.error
    }
}
