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

let signalSem = DispatchSemaphore(value: 0)
var signalValue = ""
func signalS(message: DBusMessage) {
    Log.entry("message: \(message)")

    let decoder = DBusDecoder()
    signalValue = try! decoder.decode(String.self, from: message)

    signalSem.signal()
}

func echoS(message: DBusMessage, connection: DBusConnection) -> DBusMessage? {
    Log.entry("message: \(message)")

    do {
        let decoder = DBusDecoder()
        let decoded = try decoder.decode(String.self, from: message)

        // Send a signal
        let signal = try! DBusMessage(path: "/Foo/Bar", iface: "Bar.Foo", name: "signalS")
        let encoder = DBusEncoder()
        try encoder.encode(decoded, to: signal, signature: "s")
        try! connection.send(message: signal)

        // Send a reply
        let reply = try DBusMessage(replyTo: message)
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
            let adaptor = try manager.newAdaptor(objectPath: "/Foo/Bar")
            adaptor.addMethod(interface: "Bar.Foo", member: "echoS", fn: echoS)
            let sf = SignalFilter(interface: "Bar.Foo",
                                  signalName: "signalS",
                                  fn: signalS)
            try manager.filter.addFilter(sf)

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
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
            XCTAssertTrue(r.completed)
            guard let reply = r.replyMessage else {
                throw RuntimeError.generic("No reply!")
            }

            signalSem.wait()
            XCTAssertEqual(helloWorld, signalValue)

            let decoder = DBusDecoder()
            let decoded = try decoder.decode(String.self, from: reply)
            print(decoded)
            XCTAssertEqual(helloWorld, decoded)
        } catch {
            XCTFail("\(error)")
        }
    }
}
