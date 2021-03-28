import XCTest
import Foundation
@testable import JSONSchema


class ValidationResultsTests: XCTestCase {
  func testValidEncodableAsJSON() throws {
    let result = ValidationResult.valid

    let jsonData = try JSONEncoder().encode(result)
    let json = try! JSONSerialization.jsonObject(with: jsonData)

    XCTAssertEqual(json as! NSDictionary, [
      "valid": true,
    ])
  }

  func testInvalidEncodableAsJSON() throws {
    let error = ValidationError(
      "example description",
      instanceLocation: JSONPointer(path: "/test/1"),
      keywordLocation: JSONPointer(path: "#/example")
    )
    let result = ValidationResult.invalid([error])

    let jsonData = try JSONEncoder().encode(result)
    let json = try! JSONSerialization.jsonObject(with: jsonData)

    XCTAssertEqual(json as! NSDictionary, [
      "valid": false,
      "errors": [
        [
          "error": "example description",
          "instanceLocation": "/test/1",
          "keywordLocation": "#/example",
        ],
      ],
    ])
  }
}
