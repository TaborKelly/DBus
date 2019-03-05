import Foundation
import DBus

func fooSignal(message: DBusMessage) {
    print("fooSignal")

    for m in message {
        print(m)
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

    let message = try DBusMessage(destination: "com.racepointenergy.DBus.EchoServer",
                                  path: "/com/racepointenergy/DBus/EchoServer",
                                  iface: "com.racepointenergy.DBus.EchoServer",
                                  method: "s")
    try message.append(contentsOf: [.string("Test String")])
    // try manager.connection.send(message: message)
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
    RunLoop.main.run() //(until: Date(timeIntervalSinceNow: 0.1))
} catch {
    print("\(error)")
    exit(1)
}
