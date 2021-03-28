import XCTest
@testable import JSONSchema


class EnumTests: XCTestCase {
  func testEnumValidationFailure() throws {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "enum": ["one"],
    ]

    let result = try validate(["two"], schema: schema)

    switch result {
    case .valid:
      XCTFail("Validation should fail")
    case .invalid(let errors):
      XCTAssertEqual(errors.count, 1)
      let error = errors[0]

      //XCTAssertEqual(error.description, "is not a valid enumeration value of '[\"one\"]'")
      XCTAssertEqual(error.instanceLocation.path, "")
      XCTAssertEqual(error.keywordLocation?.path, "#/enum")
    }
  }
}
