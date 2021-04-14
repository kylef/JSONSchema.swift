import XCTest
@testable import JSONSchema


class RefTests: XCTestCase {
  func testRefWithErrorInSubschema() throws {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "items": [
        "$ref": "#/definitions/name",
      ],
      "definitions": [
        "name": [
          "type": "string",
        ],
      ],
    ]

    let result = try validate([true], schema: schema)

    switch result {
    case .valid:
      XCTFail("Validation should fail")
    case .invalid(let errors):
      XCTAssertEqual(errors.count, 1)
      let error = errors[0]

      XCTAssertEqual(error.description, "'true' is not of type 'string'")
      XCTAssertEqual(error.instanceLocation.path, "/0")
      XCTAssertEqual(error.keywordLocation.path, "#/items/$ref/type")
    }
  }
}
