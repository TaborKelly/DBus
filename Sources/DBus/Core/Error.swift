//
//  Error.swift
//  DBus
//
//  Created by Alsey Coleman Miller on 2/25/16.
//

import Foundation
import CDBus

/// An error type to describe errors that do not originate from DBus or Swift's Codable framework.
public enum RuntimeError: Error {
    /// A catch all error for if libdbus does something that we did not expect.
    case generic(String)
    /// We encountered an error case that we never expected. Probably due to a bug in the code.
    case logicError(String)
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
    }
}

// Given a swift string, make a copy of the C string (const char *) and return a pointer to it
func swiftStringToConstCharStar(_ s: String) throws -> UnsafePointer<Int8> {
    let unsafeMutablePointer = try swiftStringToCharStar(s)
    // UnsafePointer<Int8>
    return UnsafePointer(unsafeMutablePointer)
}

/**
 * A class that represents a DBus error.
 */
public class DBusError: Error, Equatable, CustomStringConvertible {
    internal var cError = CDBus.DBusError()

    init() {
        dbus_error_init(&cError);
    }

    /**
     Initialize a new DBusError.

     ex: DBusError(name: DBusError.Name.invalidArguments, message: "Your arguments were wrong.")

     - Parameters:
         - name: The error name (must be a valid DBus Error name).
         - message: A message to send along.
     */
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

    var isSet: Bool {
        let dbusBool = dbus_error_is_set(&cError)
        return Bool(dbusBool)
    }

    /// The name of the errror.
    public var name: String {
        return String(cString: cError.name)
    }

    /// The error message.
    public var message: String {
        return String(cString: cError.message)
    }

    /// You can compare errors if you really want to.
    public static func == (lhs: DBusError, rhs: DBusError) -> Bool {
        let lhsName = String(cString: lhs.cError.name)
        let rhsName = String(cString: rhs.cError.name)
        let lhsMessage = String(cString: lhs.cError.message)
        let rhsMessage = String(cString: rhs.cError.message)
        return (lhsName == rhsName &&
                lhsMessage == rhsMessage)
    }

    /// Error discription.
    public var description: String {
        return "DBusError(name: '\(name)', message: '\(message)') "
    }
}

public extension DBusError {

    /// This lets you easily create errors with common names.
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
