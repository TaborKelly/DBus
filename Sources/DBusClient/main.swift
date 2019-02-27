import Foundation
import DBus

do {
    let manager = try DBusManager.getManager()
    print(manager)

    let message = try DBusMessage(destination: "com.racepointenergy.DBus.EchoServer",
                                  path: "/com/racepointenergy/DBus/EchoServer",
                                  iface: "com.racepointenergy.DBus.EchoServer",
                                  method: "s")
    try message.append(contentsOf: [.string("Test String")])
    // try manager.connection.send(message: message)
    let r = try manager.connection.sendWithReply(message: message)
    print("\(String(describing: r))")
    RunLoop.main.run() //(until: Date(timeIntervalSinceNow: 0.1))
} catch {
    print("\(error)")
    exit(1)
}
