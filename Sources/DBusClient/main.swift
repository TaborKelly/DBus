import Foundation
import DBus
import AnyCodable
import HeliumLogger
import LoggerAPI

HeliumLogger.use(.info)

func fooSignal(message: DBusMessage) {
    print("fooSignal")
}

func send<T: Encodable>(manager: DBusManager, method: String, _ toSend: T, signature: String) throws {
    Log.entry("")

    let message = try DBusMessage(destination: "com.racepointenergy.DBus.EchoServer",
                                  path: "/com/racepointenergy/DBus/EchoServer",
                                  iface: "com.racepointenergy.DBus.EchoServer",
                                  method: method)
    let encoder = DBusEncoder()
    try encoder.encode(toSend, to: message, signature: signature)

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
    if let error = m.errorName {
        print("ERROR: \(error)")
    }
}

do {
    let manager = try DBusManager.getManager()
    print(manager)
    try manager.addSignalFilter(interface: "com.racepointenergy.DBus.EchoServer", signal: "foo", fn: fooSignal)

    // get a property
    guard let pm = try manager.getProperty(destination: "com.racepointenergy.DBus.EchoServer",
                                           objectPath: "/com/racepointenergy/DBus/EchoServer",
                                           interface: "com.racepointenergy.DBus.EchoServer",
                                           property: "propertyS") else {
        print("manager.getProperty failed!")
        exit(1)
    }
    print("propertyS: \(pm)")

    // Simple types
    try send(manager: manager, method: "b", true, signature: "b")
    try send(manager: manager, method: "s", "Hello World!", signature: "s")
    try send(manager: manager, method: "y", 8, signature: "y")
    try send(manager: manager, method: "n", -16, signature: "n")
    try send(manager: manager, method: "i", -32, signature: "i")
    try send(manager: manager, method: "u", 32, signature: "u")
    try send(manager: manager, method: "x", -64, signature: "x")
    try send(manager: manager, method: "t", 64, signature: "t")
    try send(manager: manager, method: "d", Double(6.0221409e+23), signature: "d")

    // Simple variant case
    try send(manager: manager, method: "v", 32, signature: "v")

    // Arrays
    try send(manager: manager, method: "ay", [8, 6, 7, 5, 3, 0, 9], signature: "ay")
    try send(manager: manager, method: "array_s", ["Foo", "Bar", "Baz"], signature: "as")
    try send(manager: manager, method: "v", [8, 6, 7, 5, 3, 0, 9], signature: "v")
    let arrayOfArrays = AnyEncodable([[0, 1, 2], ["a", "b", "c"]])
    try send(manager: manager, method: "v", arrayOfArrays, signature: "v")

    // Dictionaries
    let asi: [String: Int] = [ "zero": 0, "one": 1, "two": 2, "three": 3 ]
    try send(manager: manager, method: "asi", asi, signature: "a{si}")
    let ass: [String: String] = [ "Lorem": "ipsum", "dolor": "sit", "amet,": "consectetur", "adipiscing": "elit,"]
    try send(manager: manager, method: "ass", ass, signature: "a{ss}")
    try send(manager: manager, method: "av", arrayOfArrays, signature: "av")
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
    try send(manager: manager, method: "asv", dictionary, signature: "a{sv}")

    print("fin")

    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
} catch {
    print("\(error)")
    exit(1)
}
