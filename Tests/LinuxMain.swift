import XCTest
@testable import DBusTests

XCTMain([
    testCase(CodableTests.allTests),
    testCase(ConnectionTests.allTests),
    testCase(DBusSignatureIterTests.allTests),
    testCase(ErrorTests.allTests),
    testCase(RoundTripTests.allTests),
    ])
