
//
//  SignatureTests.swift
//  DBusTests
//
//  Created by Alsey Coleman Miller on 10/22/18.
//

import Foundation
import XCTest
@testable import DBus
import HeliumLogger
import LoggerAPI

final class CodableTests: XCTestCase {
    var encoder: DBusEncoder!
    var decoder: DBusDecoder!

    override func setUp() {
        HeliumLogger.use(.entry)
        self.encoder = DBusEncoder()
        self.decoder = DBusDecoder()
    }

    static let allTests = [
        ("testY", testY),
        ("testB", testB),
        ("testN", testN),
        ("testQ", testQ),
        ("testI", testI),
        ("testU", testU),
        ("testX", testX),
        ("testT", testT),
        ("testD", testD),
        ("testH", testH),
        ("testS", testS),
        ("testO", testO),
        ("testG", testG),
        ("testArray", testArray),
        ("testMap", testMap),
    ]

    // BYTE y (121)
    func testY() {
        do {
            let uint8 = UInt8.max

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(uint8, to: dbusMessage, signature: "y")
            let decoded = try decoder.decode(UInt8.self, from: dbusMessage)

            XCTAssertEqual(uint8, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // BOOLEAN b (98)
    func testB() {
        do {
            let boolean = true

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(boolean, to: dbusMessage, signature: "b")
            let decoded = try decoder.decode(Bool.self, from: dbusMessage)

            XCTAssertEqual(boolean, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // INT16 n (110)
    func testN() {
        do {
            let int16 = Int16.min

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(int16, to: dbusMessage, signature: "n")
            let decoded = try decoder.decode(Int16.self, from: dbusMessage)

            XCTAssertEqual(int16, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // UINT16 q (113)
    func testQ() {
        do {
            let uint16 = UInt16.max

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(uint16, to: dbusMessage, signature: "q")
            let decoded = try decoder.decode(UInt16.self, from: dbusMessage)

            XCTAssertEqual(uint16, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // INT32 i (105)
    func testI() {
        do {
            let int32 = Int32.min

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(int32, to: dbusMessage, signature: "i")
            let decoded = try decoder.decode(Int32.self, from: dbusMessage)

            XCTAssertEqual(int32, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // UINT32 u (117)
    func testU() {
        do {
            let uint32 = UInt32.max

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(uint32, to: dbusMessage, signature: "u")
            let decoded = try decoder.decode(UInt32.self, from: dbusMessage)

            XCTAssertEqual(uint32, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // INT64 x (120)
    func testX() {
        do {
            let int64 = Int64.min

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(int64, to: dbusMessage, signature: "x")
            let decoded = try decoder.decode(Int64.self, from: dbusMessage)

            XCTAssertEqual(int64, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // UINT64 t (116)
    func testT() {
        do {
            let uint64 = UInt64.max

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(uint64, to: dbusMessage, signature: "t")
            let decoded = try decoder.decode(UInt64.self, from: dbusMessage)

            XCTAssertEqual(uint64, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // DOUBLE d (100)
    func testD() {
        do {
            let double = Double(6.0221409e+23)
            let float = Float(double)

            // Try as Double
            var dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(double, to: dbusMessage, signature: "d")
            let decodedDouble = try decoder.decode(Double.self, from: dbusMessage)
            XCTAssertEqual(double, decodedDouble)

            // Try as Float
            dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(float, to: dbusMessage, signature: "d")
            let decodedFloat = try decoder.decode(Float.self, from: dbusMessage)
            XCTAssertEqual(float, decodedFloat)
        } catch {
            XCTFail("\(error)")
        }
    }

    // UNIX_FD h (104)
    func testH() {
        do {
            let fd = UInt32(32)

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(fd, to: dbusMessage, signature: "h")
            let decoded = try decoder.decode(UInt32.self, from: dbusMessage)

            XCTAssertEqual(fd, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // STRING s (115)
    func testS() {
        do {
            let string = "Hello World!"

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(string, to: dbusMessage, signature: "s")
            let decoded = try decoder.decode(String.self, from: dbusMessage)

            XCTAssertEqual(string, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // OBJECT_PATH o (111)
    func testO() {
        do {
            let objectPath = "/Hello/World"

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(objectPath, to: dbusMessage, signature: "o")
            let decoded = try decoder.decode(String.self, from: dbusMessage)

            XCTAssertEqual(objectPath, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    // SIGNATURE g (103)
    func testG() {
        do {
            let signature = "a{sv}"

            let dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(signature, to: dbusMessage, signature: "g")
            let decoded = try decoder.decode(String.self, from: dbusMessage)

            XCTAssertEqual(signature, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testArray() {
        do {
            let input = [1, 2, 3, 4]

            // Test as a DBus Array
            var dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(input, to: dbusMessage, signature: "ai")
            var decoded = try decoder.decode([Int].self, from: dbusMessage)
            XCTAssertEqual(input, decoded)

            // While we are at it, try encoding as a DBus Struct
            dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(input, to: dbusMessage, signature: "(iiii)")
            decoded = try decoder.decode([Int].self, from: dbusMessage)
            XCTAssertEqual(input, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMap() {
        do {
            let inputSI: [String: Int] = [ "zero": 0, "one": 1, "two": 2, "three": 3 ]
            // Test as a DBus Array
            var dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(inputSI, to: dbusMessage, signature: "a{si}")
            let decodedSI = try decoder.decode([String: Int].self, from: dbusMessage)
            XCTAssertEqual(inputSI, decodedSI)

            let inputIS: [Int: String] = [ 0: "zero", 1: "one", 2: "two", 3: "three" ]
            // Test as a DBus Array
            dbusMessage = try DBusMessage(type: .methodCall) // type doesn't really matter
            try encoder.encode(inputIS, to: dbusMessage, signature: "a{is}")
            let decodedIS = try decoder.decode([Int: String].self, from: dbusMessage)
            XCTAssertEqual(inputIS, decodedIS)
        } catch {
            XCTFail("\(error)")
        }
    }
}
