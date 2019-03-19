//
//  Error.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 2/25/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import CDBus

/*
enum DBusErrorError: Error {
    case nameError
}
*/
/*
/// DBus type representing an exception.
public struct DBusError: Error, Equatable, Hashable {

    /// Error name field
    public let name: DBusError.Name

    /// Error message field
    public let message: String

    internal init(name: DBusError.Name, message: String) {

        self.name = name
        self.message = message
    }

    internal init(name: String, message: String) throws {
        if let n = DBusError.Name(rawValue: name) {
            self.name = n
        } else {
            throw DBusErrorError.nameError
        }
        self.message = message
    }
}
*/
// MARK: - Internal Reference

public enum RuntimeError: Error {
    case generic(String)
    case logicError(String) // we encountered an error case that we never expected. Probably due to a bug in the code.
}

// Given a swift string, make a copy of the C string (char *) and return a pointer to it
func swiftStringToCharStar(_ s: String) throws -> UnsafeMutablePointer<Int8> {
    return try s.withCString { (unsafePointer: UnsafePointer<Int8>) -> UnsafeMutablePointer<Int8> in
        // We need to copy the string to save a copy. unsafePointer is only valid in this closure
        // UnsafeMutableRawPointer
        let bufferLen = strlen(unsafePointer) + 1
        guard let unsafeMutableRawPointer = malloc(bufferLen) else {
            throw RuntimeError.generic("malloc() failed")
        }
        memcpy(unsafeMutableRawPointer, unsafePointer, bufferLen)
        // UnsafeMutablePointer<Int8>
        let unsafeMutablePointer = unsafeMutableRawPointer.assumingMemoryBound(to: Int8.self)
        return unsafeMutablePointer
        // UnsafePointer<Int8>
        // return UnsafePointer(unsafeMutablePointer)
    }
}

// Given a swift string, make a copy of the C string (const char *) and return a pointer to it
func swiftStringToConstCharStar(_ s: String) throws -> UnsafePointer<Int8> {
    let unsafeMutablePointer = try swiftStringToCharStar(s)
    // UnsafePointer<Int8>
    return UnsafePointer(unsafeMutablePointer)
}

public class DBusError: Error, Equatable, CustomStringConvertible /*, Hashable*/ {
    internal var cError = CDBus.DBusError()

    init() {
        dbus_error_init(&cError);
    }

    public convenience init(name: String, message: String = "") throws {
        self.init()

        let validationError = DBusError()
        let isValid = dbus_validate_error_name(name, &validationError.cError)
        if isValid == false {
            throw RuntimeError.generic("\(name) is not a valid DBus Error name.")
        }

        let cName = try swiftStringToConstCharStar(name)
        let cMessage = try swiftStringToConstCharStar(message)
        dbus_set_error_const(&cError, cName, cMessage)
    }

    deinit {
        dbus_error_free(&cError)
    }

    public var isSet: Bool {
        let dbusBool = dbus_error_is_set(&cError)
        return Bool(dbusBool)
    }

    public var name: String {
        return String(cString: cError.name)
    }

    public var message: String {
        return String(cString: cError.message)
    }

    public static func == (lhs: DBusError, rhs: DBusError) -> Bool {
        let lhsName = String(cString: lhs.cError.name)
        let rhsName = String(cString: rhs.cError.name)
        let lhsMessage = String(cString: lhs.cError.message)
        let rhsMessage = String(cString: rhs.cError.message)
        return (lhsName == rhsName &&
                lhsMessage == rhsMessage)
    }

    public var description: String {
        return "DBusError(name: '\(name)', message: '\(message)') "
    }
}



public extension DBusError {

    public struct Name {
        /// A generic error; "something went wrong" - see the error message for more.
        ///
        /// `org.freedesktop.DBus.Error.Failed`
        public static let failed = String(DBUS_ERROR_FAILED)

        /// No Memory
        ///
        /// `org.freedesktop.DBus.Error.NoMemory`
        public static let noMemory = String(DBUS_ERROR_NO_MEMORY)

        /// Existing file and the operation you're using does not silently overwrite.
        ///
        /// `org.freedesktop.DBus.Error.FileExists`
        public static let fileExists = String(DBUS_ERROR_FILE_EXISTS)

        /// Missing file.
        ///
        /// `org.freedesktop.DBus.Error.FileNotFound`
        public static let fileNotFound = String(DBUS_ERROR_FILE_NOT_FOUND)

        /// Invalid arguments
        ///
        /// `org.freedesktop.DBus.Error.InvalidArgs`
        public static let invalidArguments = String(DBUS_ERROR_INVALID_ARGS)

        /// Invalid signature
        ///
        /// `org.freedesktop.DBus.Error.InvalidSignature`
        public static let invalidSignature = String(DBUS_ERROR_INVALID_SIGNATURE)
    }
}

/*
internal extension DBusError {

    /// Internal class for working with the C DBus error API
    internal final class Reference {

        // MARK: - Internal Properties

        internal var internalValue: CDBus.DBusError

        // MARK: - Initialization

        deinit {

            dbus_error_free(&internalValue)
        }

        /// Creates New DBus Error instance.
        init() {

            var internalValue = CDBus.DBusError()
            dbus_error_init(&internalValue)
            self.internalValue = internalValue
        }

        // MARK: - Properties

        /// Checks whether an error occurred (the error is set).
        ///
        /// - Returns: `true` if the error is empty or `false` if the error is set.
        var isEmpty: Bool {

            return Bool(dbus_error_is_set(&internalValue)) == false
        }

        var name: String {

            return String(cString: internalValue.name)
        }

        var message: String {

            return String(cString: internalValue.message)
        }

        func hasName(_ name: String) -> Bool {

            return Bool(dbus_error_has_name(&internalValue, name))
        }
    }
}
*/
/*
internal extension DBusError {

    init?(_ reference: DBusError.Reference) {

        guard reference.isEmpty == false
            else { return nil }

        guard let name = DBusError.Name(rawValue: reference.name)
            else { fatalError("Invalid error \(reference.name)") }

        self.init(name: name,
                  message: reference.message)
    }
}
*/

// MARK: CustomNSError
/*
extension DBusError: CustomNSError {

    public enum UserInfoKey: String {

        /// DBus error name
        case name
    }

    /// The domain of the error.
    public static let errorDomain = "org.freedesktop.DBus.Error"

    /// The error code within the given domain.
    public var errorCode: Int {

        return hashValue
    }

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {

        return [
            UserInfoKey.name.rawValue: self.name.rawValue,
            NSLocalizedDescriptionKey: self.message
        ]
    }
}
*/
// MARK: Error Name

/*
public extension DBusError {

    public struct Name: Equatable, Hashable {

        public let rawValue: String

        public init?(rawValue: String) {

            // TODO: FIXME. This is calling the libdbus code for interface validation, not error validation
            // (dbus_validate_error_name())
            // validate from C, no parsing
            do { try DBusInterface.validate(rawValue) }
            catch { return nil }

            self.rawValue = rawValue
        }
    }
}

public extension DBusError.Name {

    public init(_ interface: DBusInterface) {

        // should be valid
        self.rawValue = interface.rawValue
    }
}

public extension DBusInterface {

    init(_ error: DBusError.Name) {

        self.init(rawValue: error.rawValue)!
    }
}
*/
