//
//  RoundTripTests.swift
//  DBus
//
//  Created by Tabor Kelly on 3/18/19.
//

import Foundation
import XCTest
import DBus
import AnyCodable
import HeliumLogger
import LoggerAPI

func echoS(message: DBusMessage) -> DBusMessage? {
    Log.debug("message: \(message)")

    do {
        let decoder = DBusDecoder()
        let decoded = try decoder.decode(String.self, from: message)

        let reply = try DBusMessage(replyTo: message)
        let encoder = DBusEncoder()
        try encoder.encode(decoded, to: reply, signature: "s")
        return reply
    } catch {
        let error = try? DBusMessage(replyTo: message, errorName: DBusError.Name.invalidSignature, errorMessage: "String")
        return error
    }
}

final class RoundTripTests: XCTestCase {
    var manager: DBusManager!

    override func setUp() {
        HeliumLogger.use(.entry)
        do {
            self.manager = try DBusManager.getManager()
        } catch {
            XCTFail("\(error)")
        }
    }

    static let allTests = [
        ("testEchoS", testEchoS),
    ]

    func testEchoS() {
        do {
            try manager.connection.requestName("Bar.Foo")
            let adaptor = try Adaptor(connection: manager.connection, objectPath: "/Foo/Bar")
            adaptor.addMethod(interfaceName: "Bar.Foo", memberName: "echoS", fn: echoS)

            let message = try DBusMessage(destination: "Bar.Foo",
                                          path: "/Foo/Bar",
                                          iface: "Bar.Foo",
                                          method: "echoS")
            let helloWorld = "Hello World!"
            let encoder = DBusEncoder()
            try encoder.encode("Hello World!", to: message, signature: "s")
            guard let r = try manager.connection.sendWithReply(message: message) else {
                throw RuntimeError.generic("No reply!")
            }
            manager.connection.flush()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
            XCTAssertTrue(r.completed)
            guard let reply = r.replyMessage else {
                throw RuntimeError.generic("No reply!")
            }

            let decoder = DBusDecoder()
            let decoded = try decoder.decode(String.self, from: reply)
            print(decoded)
            XCTAssertEqual(helloWorld, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }
}
