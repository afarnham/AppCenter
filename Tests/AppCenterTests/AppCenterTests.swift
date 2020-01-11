import XCTest
@testable import AppCenter

final class AppCenterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AppCenter().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
