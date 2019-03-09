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
/*
    try send(manager: manager, method: "y", UInt8(8))
    try send(manager: manager, method: "b", true)
    try send(manager: manager, method: "n", Int16(-16))
    try send(manager: manager, method: "i", Int32(-32))
    try send(manager: manager, method: "u", UInt32(32))
    try send(manager: manager, method: "x", Int64(-64))
    try send(manager: manager, method: "t", UInt64(64))
    try send(manager: manager, method: "s", "Hello World!")
    try send(manager: manager, method: "d", Double(6.0221409e+23)) */
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
    try send(manager: manager, method: "array_s", ["Foo", "Bar", "Baz"], signature: "as")

    RunLoop.main.run() //(until: Date(timeIntervalSinceNow: 0.1))
} catch {
    print("\(error)")
    exit(1)
}
