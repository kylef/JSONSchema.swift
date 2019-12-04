import Foundation
import XCTest
@testable import JSONSchema


class JSONSchemaTests: XCTestCase {
  var schema: Schema!

  override func setUp() {
    super.setUp()

    schema = Schema([
      "title": "Product",
      "description": "A product from Acme's catalog",
      "type": "object",
    ])
  }

  func testTitle() {
    XCTAssertEqual(schema.title, "Product")
  }

  func testDescription() {
    XCTAssertEqual(schema.description, "A product from Acme's catalog")
  }

  func testType() {
    XCTAssertEqual(schema.type, [Type.object])
  }

  func testSuccessfulValidation() {
    XCTAssertTrue(schema.validate([String: Any]()).valid)
  }

  func testUnsuccessfulValidation() {
    XCTAssertFalse(schema.validate([String]()).valid)
  }

  func testReadme() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    XCTAssertTrue(schema.validate(["name": "Eggs", "price": 34.99]).valid)
    XCTAssertFalse(schema.validate(["price": 34.99]).valid)
  }
}


class ValidateTests: XCTestCase {
  func testValidateDraft4() {
    let schema: [String: Any]  = [
      "$schema": "http://json-schema.org/draft-04/schema#",
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ]

    XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
  }

  func testValidateDraft6() {
    let schema: [String: Any]  = [
      "$schema": "http://json-schema.org/draft-06/schema#",
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ]

    XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
  }

  func testDraft6ValidatorIsAvailable() {
    let result = validator(for: ["$schema": "http://json-schema.org/draft-06/schema#"])
    XCTAssertTrue(result is Draft6Validator, "Unexpected type of validator \(result)")
  }

  func testValidateDraft7() {
    let schema: [String: Any]  = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ]

    XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
  }
}
