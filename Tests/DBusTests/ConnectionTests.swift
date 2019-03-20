//
//  ConnectionTests.swift
//  DBus
//
//  Created by Tabor Kelly on 1/28/19.
//

import Foundation
import XCTest
@testable import DBus

final class ConnectionTests: XCTestCase {
    static let allTests = [
        ("testNewConnection", testNewConnection),
    ]

    func testNewConnection() {
        #if (Xcode)
        print("Skipping test, please run in SPM.")
        #else
        do {
            let conn = try DBusConnection(busType: .session)
            print(conn)
        } catch {
            XCTFail("\(error)")
        }
        #endif
    }
}
