//
//  ErrorTests.swift
//  DBus
//
//  Created by Tabor Kelly on 1/28/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation
import XCTest
@testable import DBus

final class ErrorTests: XCTestCase {

    static let allTests = [
        ("testNewError", testNewError),
    ]

    func testNewError() {
        do {
            let name = "org.freedesktop.DBus.Error.InvalidArgs"
            let message = "Foo!"
            let e = try DBusError(name: name, message: message)
            print("\(name), \(e.name)")
            print("\(message), \(e.message)")
            XCTAssertEqual(name, e.name)
            XCTAssertEqual(message, e.message)
            // let r = e.Reference()
        } catch {
            XCTFail("\(error)")
        }
    }
}
