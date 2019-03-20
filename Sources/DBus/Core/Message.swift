//
//  Message.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 2/25/16.
//

import CDBus
import AnyCodable

/// Message to be sent or received over a `DBusConnection`.
///
/// A `DBusMessage` is the most basic unit of communication over a `DBusConnection`.
/// A `DBusConnection` represents a stream of messages received from a remote application,
/// and a stream of messages sent to a remote application.
///
/// A message has header fields such as the sender, destination, method or signal name, and so forth.
///
public final class DBusMessage {

    // MARK: - Internal Properties

    internal let internalPointer: OpaquePointer

    // MARK: - Initialization

    deinit {

        dbus_message_unref(internalPointer)
    }

    internal init(_ internalPointer: OpaquePointer) {

        dbus_message_ref(internalPointer)
        self.internalPointer = internalPointer
    }

    /// Constructs a new message of the given message type.
    public init(type: DBusMessageType) throws {

        guard let internalPointer = dbus_message_new(type.rawValue)
            else { throw RuntimeError.generic("dbus_message_new() failed") }

        self.internalPointer = internalPointer
    }

    /// Constructs a new message to invoke a method on a remote object.
    ///
    /// - Note: Destination, path, interface, and method name can't contain any invalid characters (see the D-Bus specification).
    public init(destination: String?,
                path: String,
                iface: String?,
                method: String) throws {
        // Returns NULL if memory can't be allocated for the message.
        guard let internalPointer = dbus_message_new_method_call(destination,
                                                                 path,
                                                                 iface,
                                                                 method) else {
            throw RuntimeError.generic("dbus_message_new_method_call() failed")
        }

        self.internalPointer = internalPointer
    }

    /// Constructs a new message to send a signal
    ///
    /// - Note: Path, interface, and method name can't contain any invalid characters (see the D-Bus specification).
    public init(path: String, iface: String?, name: String) throws {
        // Returns NULL if memory can't be allocated for the message.
        guard let internalPointer = dbus_message_new_signal(path, iface, name) else {
            throw RuntimeError.generic("dbus_message_new_signal() failed")
        }

        self.internalPointer = internalPointer
    }

    /// Constructs a message that is a reply to a method call.
    public init(replyTo: DBusMessage) throws {

        guard let internalPointer = dbus_message_new_method_return(replyTo.internalPointer)
            else { throw RuntimeError.generic("dbus_message_new_method_return() failed") }

        self.internalPointer = internalPointer
    }

    /// Constructs a message that is an error reply to a method call.
    public init(replyTo: DBusMessage, errorName: String, errorMessage: String) throws {

        guard let internalPointer = dbus_message_new_error(replyTo.internalPointer, errorName, errorMessage)
            else { throw RuntimeError.generic("dbus_message_new_method_return() failed") }

        self.internalPointer = internalPointer
    }

    /// The message type.
    public lazy var type: DBusMessageType = {

        let rawValue = dbus_message_get_type(internalPointer)

        guard let type = DBusMessageType(rawValue: rawValue)
            else { fatalError("Invalid DBus Message type: \(rawValue)") }

        return type
    }()

    /// Checks whether a message contains Unix file descriptors.
    public var containsFileDescriptors: Bool {

        return Bool(dbus_message_contains_unix_fds(internalPointer))
    }

    /// The serial of a message or `0` if none has been specified.
    ///
    /// The message's serial number is provided by the application sending the message and
    /// is used to identify replies to this message.
    ///
    /// - Note: All messages received on a connection will have a serial provided by the remote application.
    ///
    /// For messages you're sending, `DBusConnection.send()` will assign a serial and return it to you.
    public var serial: UInt32 {

        get { return dbus_message_get_serial(internalPointer) }

        set { dbus_message_set_serial(internalPointer, newValue) }
    }

    /// The reply serial of a message (the serial of the message this is a reply to).
    public var replySerial: UInt32 {

        return dbus_message_get_reply_serial(internalPointer)
    }

    /// Sets the reply serial of a message (the serial of the message this is a reply to).
    public func setReplySerial(_ newValue: UInt32) throws {

        guard Bool(dbus_message_set_reply_serial(internalPointer, newValue))
            else { throw RuntimeError.generic("dbus_message_set_reply_serial() failed") }
    }

    /// Flag indicating that the caller of the method is prepared to wait for interactive authorization to take place
    /// (for instance via Polkit) before the actual method is processed.
    ///
    /// The flag is `false` by default;
    /// that is, by default the other end is expected to make any authorization decisions non-interactively and promptly.
    public var allowInteractiveAuthorization: Bool {

        get { return Bool(dbus_message_get_allow_interactive_authorization(internalPointer)) }

        set { dbus_message_set_allow_interactive_authorization(internalPointer, dbus_bool_t(newValue)) }
    }

    /// Sets a flag indicating that an owner for the destination name will be automatically started before the message is delivered.
    ///
    /// When this flag is set, the message is held until a name owner finishes starting up,
    /// or fails to start up. In case of failure, the reply will be an error.
    ///
    /// The flag is set to `true` by default, i.e. auto starting is the default.
    public var autoStart: Bool {

        get { return Bool(dbus_message_get_auto_start(internalPointer)) }

        set { dbus_message_set_auto_start(internalPointer, dbus_bool_t(newValue)) }
    }

    /// Flag indicating that the message does not want a reply;
    /// if this flag is set, the other end of the connection may (but is not required to)
    /// optimize by not sending method return or error replies.
    ///
    /// The flag is `false` by default, that is by default the other end is required to reply.
    ///
    /// - Note: If this flag is set, there is no way to know whether the message successfully arrived at the remote end.
    /// Normally you know a message was received when you receive the reply to it.
    public var noReply: Bool {

        get { return Bool(dbus_message_get_no_reply(internalPointer)) }

        set { dbus_message_set_no_reply(internalPointer, dbus_bool_t(newValue)) }
    }

    /// The destination is the name of another connection on the bus
    /// and may be either the unique name assigned by the bus to each connection,
    /// or a well-known name specified in advance.
    ///
    /// The destination name must contain only valid characters as defined in the D-Bus specification.
    public var destination: String? {

        guard let string = getString(dbus_message_get_destination)
            else { return nil }

        return string
    }

    /// Sets the message's destination.
    public func setDestination(_ newValue: String?) throws {

        try setString(dbus_message_set_destination, newValue)
    }

    /// The name of the error (for `Error` message type).
    ///
    /// The name is fully-qualified (namespaced).
    /// The error name must contain only valid characters as defined in the D-Bus specification.
    public var errorName: String? {

        guard let string = getString(dbus_message_get_error_name)
            else { return nil }

        return string
    }

    /// Sets the name of the error (DBUS_MESSAGE_TYPE_ERROR).
    /// The name is fully-qualified (namespaced).
    /// The error name must contain only valid characters as defined in the D-Bus specification.
    public func setErrorName(_ newValue: String?) throws {

        try setString(dbus_message_set_error_name, newValue)
    }

    /// The interface this message is being sent to (for method call type)
    /// or the interface a signal is being emitted from (for signal call type).
    ///
    /// The interface name must contain only valid characters as defined in the D-Bus specification.
    public var interface: String? {

        guard let string = getString(dbus_message_get_interface)
            else { return nil }

        return string
    }

    /// Sets the interface this message is being sent to (for `DBusMessageType.MethodCall`)
    /// or the interface a signal is being emitted from (for `DBusMessageType.Signal`).
    public func setInterface(_ newValue: String?) throws {

        try setString(dbus_message_set_interface, newValue)
    }

    /// The object path this message is being sent to (for method call type)
    /// or the one a signal is being emitted from (for signal call type).
    ///
    /// The path must contain only valid characters as defined in the D-Bus specification.
    public var path: String? {

        guard let string = getString(dbus_message_get_path)
            else { return nil }

        return string
    }

    /// Sets the object path this message is being sent to (for `DBusMessageType.MethodCall`)
    /// or the one a signal is being emitted from (for `DBusMessageType.Signal`).
    public func setPath(_ newValue: String?) throws {

        try setString(dbus_message_set_path, newValue)
    }

    /// The interface member being invoked (for method call type) or emitted (for signal type).
    ///
    /// The member name must contain only valid characters as defined in the D-Bus specification.
    public var member: String? {

        guard let string = getString(dbus_message_get_member)
            else { return nil }

        return string
    }

    func getMember() -> String {
        return String(cString: dbus_message_get_member(self.internalPointer))
    }

    /// Sets the interface member being invoked (`DBusMessageType.MethodCall`)
    /// or emitted (`DBusMessageType.Signal`).
    ///
    /// The member name must contain only valid characters as defined in the D-Bus specification.
    public func setMember(_ newValue: String?) throws {

        try setString(dbus_message_set_member, newValue)
    }

    /// The message sender.
    ///
    /// The sender must be a valid bus name as defined in the D-Bus specification.
    ///
    /// - Note: Usually you don't want to call this.
    /// The message bus daemon will call it to set the origin of each message.
    /// If you aren't implementing a message bus daemon you shouldn't need to set the sender.
    public var sender: String? {

        guard let string = getString(dbus_message_get_sender)
            else { return nil }

        return string
    }

    /// Sets the message sender.
    ///
    /// The sender must be a valid bus name as defined in the D-Bus specification.
    ///
    /// - Note: Usually you don't want to call this.
    /// The message bus daemon will call it to set the origin of each message.
    /// If you aren't implementing a message bus daemon you shouldn't need to set the sender.
    public func setSender(_ newValue: String?) throws {

        try setString(dbus_message_set_sender, newValue)
    }

    // MARK: - Private Methods

    private func getString(_ function: (OpaquePointer?) -> (UnsafePointer<Int8>?)) -> String? {

        // should not be free
        guard let cString = function(internalPointer)
            else { return nil }

        return String(cString: cString)
    }

    private func setString(_ function: (OpaquePointer?, UnsafePointer<Int8>?) -> (dbus_bool_t), _ newValue: String?) throws {

        if let newValue = newValue {

            guard Bool(newValue.withCString({ function(internalPointer, $0) }))
                else { throw RuntimeError.generic("newValue.withCString({ function(internalPointer, $0) failed") }

        } else {

            guard Bool(function(internalPointer, nil))
                else { throw RuntimeError.generic("setString failed") }
        }
    }
}

extension DBusMessage: CustomStringConvertible {
    public var description: String {
        if self.isEmpty {
            return "DBusMessage: empty"
        }
        do {

            let decoder = DBusDecoder()
            let decoded = try decoder.decode(AnyDecodable.self, from: self)
            return "DBusMessage: \(decoded)"
        } catch {
            return "DBusMessage: ERROR \(error)"
        }
    }
}

public extension DBusMessage {
    /// Is this DBusMessage empty? This is the same as having a signture of `""`.
    public var isEmpty: Bool {
        let iter = DBusMessageIter(iterating: self)
        return (iter.getSignature() == "")
    }
}

// MARK: - Copying

public extension DBusMessage {

    /**
     Creates a new message that is an exact replica of the message specified, except that its refcount is set to 1, its message serial is reset to 0, and if the original message was "locked" (in the outgoing message queue and thus not modifiable) the new message will not be locked.
    */
    public func copy() throws -> DBusMessage {

        guard let copyPointer = dbus_message_copy(internalPointer)
            else { throw RuntimeError.generic("dbus_message_copy() failed") }

        let copyMessage = DBusMessage(copyPointer)

        return copyMessage
    }
}
