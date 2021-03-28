import XCTest
@testable import JSONSchema


class RequiredTests: XCTestCase {
  func testRequiredValidationFailure() throws {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "items": [
        "required": ["test"],
      ]
    ]

    let result = try validate([[:]], schema: schema)

    switch result {
    case .valid:
      XCTFail("Validation should fail")
    case .invalid(let errors):
      XCTAssertEqual(errors.count, 1)
      let error = errors[0]

      XCTAssertEqual(error.description, "Required property 'test' is missing")
      XCTAssertEqual(error.instanceLocation.path, "/0")
      XCTAssertEqual(error.keywordLocation?.path, "#/items/required")
    }
  }
}
