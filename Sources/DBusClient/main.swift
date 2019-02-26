import Foundation
import DBus

do {
    let conn = try DBusConnection(busType: .session)
    print(conn)
    let message = try DBusMessage(destination: "com.racepointenergy.DBus.EchoServer",
                                  path: "/com/racepointenergy/DBus/EchoServer",
                                  iface: "com.racepointenergy.DBus.EchoServer",
                                  method: "s")
    try message.append(contentsOf: [.string("Test String")])
    try conn.send(message: message)
    conn.flush()
} catch {
    print("\(error)")
    exit(1)
}
