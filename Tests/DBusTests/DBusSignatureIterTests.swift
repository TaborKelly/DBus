
//
//  DBusSignatureIterTests.swift
//  DBus
//
//  Created by Tabor Kelly on 3/7/19.
//  Copyright © 2019 Racepoint Energy LLC. All rights reserved.
//

import Foundation
import XCTest
@testable import DBus

final class DBusSignatureIterTests: XCTestCase {
    static let allTests = [
        ("testString", testString),
        ("testArray", testArray),
        ("testDictionary", testDictionary),
    ]

    func testString() {
        do {
            let i = try DBusSignatureIter("s")
            let t = try i.getCurrentType()
            XCTAssertEqual(t, DBusType.string)
            XCTAssertFalse(i.next())
        } catch {
            XCTFail("\(error)")
        }
    }

    func testArray() {
        do {
            let i = try DBusSignatureIter("as")
            var t = try i.getCurrentType()
            XCTAssertEqual(t, DBusType.array)
            let si = try i.recurse()
            t = try si.getCurrentType()
            XCTAssertEqual(t, DBusType.string)
            XCTAssertFalse(si.next())
            XCTAssertFalse(i.next())
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDictionary() {
        do {
            let i = try DBusSignatureIter("a{sv}")
            var t = try i.getCurrentType()
            XCTAssertEqual(t, DBusType.array)
            let si = try i.recurse()
            t = try si.getCurrentType()
            XCTAssertEqual(t, DBusType.dictionaryEntry)
            let ssi = try si.recurse()
            t = try ssi.getCurrentType()
            XCTAssertEqual(t, DBusType.string)
            XCTAssertTrue(ssi.next())
            t = try ssi.getCurrentType()
            XCTAssertEqual(t, DBusType.variant)
            XCTAssertFalse(ssi.next())
            XCTAssertFalse(si.next())
            XCTAssertFalse(i.next())
        } catch {
            XCTFail("\(error)")
        }
    }
}
