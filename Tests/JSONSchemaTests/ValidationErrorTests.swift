import XCTest
import Foundation
@testable import JSONSchema


class ValidationErrorTests: XCTestCase {
  func testEncodableAsJSON() throws {
    let error = ValidationError(
      "example description",
      instanceLocation: JSONPointer(path: "/test/1")
    )

    let jsonData = try JSONEncoder().encode(error)
    let json = try! JSONSerialization.jsonObject(with: jsonData)

    XCTAssertEqual(json as! NSDictionary, [
      "error": "example description",
      "instanceLocation": "/test/1",
    ])
  }
}
