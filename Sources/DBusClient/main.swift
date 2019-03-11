import Foundation
import DBus
import AnyCodable
import HeliumLogger
import LoggerAPI

HeliumLogger.use(.entry)
/*
let logger = HeliumLogger()
Log.logger = logger
*/

func fooSignal(message: DBusMessage) {
    print("fooSignal")

    for m in message {
        print(m)
    }
}

// swapTwoValues<T>(_ a: inout T, _ b: inout T)
func send<T: Encodable>(manager: DBusManager, method: String, _ toSend: T, signature: String) throws {
    Log.entry("")

    let message = try DBusMessage(destination: "com.racepointenergy.DBus.EchoServer",
                                  path: "/com/racepointenergy/DBus/EchoServer",
                                  iface: "com.racepointenergy.DBus.EchoServer",
                                  method: method)
    // try message.append(contentsOf: [.string("Test String")])
    let encoder = DBusEncoder()
    // try encoder.encode("Test String", to: message)
    try encoder.encode(toSend, to: message, signature: signature)
    for mPrime in message {
        print(mPrime)
    }

    // TODO: FIXME. libdbus makes no promises about multithreading. We should be sending from the DBusManager
    // dispatch queue.
    guard let r = try manager.connection.sendWithReply(message: message) else {
        print("sendWithReply() failed!")
        exit(1)
    }
    print("\(String(describing: r))")
    r.block()
    guard let m = r.replyMessage else {
        print("replyMessage() was nil after r.block()!")
        exit(1)
    }
    print("\(String(describing: m))")
    for mPrime in m {
        print(mPrime)
    }
}

do {
    let manager = try DBusManager.getManager()
    print(manager)
    let sf = SignalFilter(interface: "com.racepointenergy.DBus.EchoServer",
                          signalName: "foo",
                          fn: fooSignal)
    try manager.filter.addFilter(sf)

    // get a property
    guard let pm = try manager.getProperty(destination: "com.racepointenergy.DBus.EchoServer",
                                           objectPath: "/com/racepointenergy/DBus/EchoServer",
                                           interfaceName: "com.racepointenergy.DBus.EchoServer",
                                           propertyName: "propertyS") else {
        print("manager.getProperty failed!")
        exit(1)
    }
    print(pm)
    for mPrime in pm {
        print(mPrime)
    }
    try send(manager: manager, method: "b", true, signature: "b")
    try send(manager: manager, method: "s", "Hello World!", signature: "s")
    try send(manager: manager, method: "y", 8, signature: "y")
    try send(manager: manager, method: "n", -16, signature: "n")
    try send(manager: manager, method: "i", -32, signature: "i")
    try send(manager: manager, method: "u", 32, signature: "u")
    try send(manager: manager, method: "x", -64, signature: "x")
    try send(manager: manager, method: "t", 64, signature: "t")
    try send(manager: manager, method: "d", Double(6.0221409e+23), signature: "d")
    try send(manager: manager, method: "ay", [8, 6, 7, 5, 3, 0, 9], signature: "ay")
    try send(manager: manager, method: "array_s", ["Foo", "Bar", "Baz"], signature: "as")
    /*
    let dictionary: [String: AnyEncodable] = [
        "boolean": true,
        "integer": 1,
        "double": 3.14159265358979323846,
        "string": "string",
        "array": [1, 2, 3],
        "nested": [
            "a": "alpha",
            "b": "bravo",
            "c": "charlie"
        ]
    ]
 */

    RunLoop.main.run() //(until: Date(timeIntervalSinceNow: 0.1))
} catch {
    print("\(error)")
    exit(1)
}
