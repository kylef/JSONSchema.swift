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
    try XCTAssertTrue(schema.validate([String: Any]()).valid)
  }

  func testUnsuccessfulValidation() {
    try XCTAssertFalse(schema.validate([String]()).valid)
  }

  func testReadme() throws {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    try XCTAssertTrue(schema.validate(["name": "Eggs", "price": 34.99]).valid)
    try XCTAssertFalse(schema.validate(["price": 34.99]).valid)
  }

  func testIterableInterface() throws {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    var counter = 0
    for error in try schema.validate(["price": 34.99]) {
      XCTAssertEqual(error.description, "Required property 'name' is missing")
      counter += 1
    }

    XCTAssertEqual(counter, 1)

    let result = try Array(schema.validate(["price": 34.99]))

    XCTAssertEqual(result.map(\.description), [
      "Required property 'name' is missing"
    ])
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

    try XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    try XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
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

    try XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    try XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
  }

  func testDraft6ValidatorIsAvailable() {
    let result = validator(for: ["$schema": "http://json-schema.org/draft-06/schema#"])
    XCTAssertTrue(result is Draft6Validator, "Unexpected type of validator \(result)")
  }

  func testValidateDraft7() throws {
    let schema: [String: Any]  = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ]

    try XCTAssertTrue(validate(["name": "Eggs", "price": 34.99], schema: schema).valid)
    try XCTAssertFalse(validate(["price": 34.99], schema: schema).valid)
  }

  func testValidatesRequired() throws {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["one", "two", "three"],
    ]

    let result = try validate(["one": true, "three": true], schema: schema)

    switch result {
    case .valid:
      XCTFail("Validation should fail")
    case .invalid(let errors):
      XCTAssertEqual(errors.map(\.description), [
        "Required property 'two' is missing",
      ])
    }
  }

  func testRequiredValidationLocation() throws {
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
      XCTAssertEqual(error.instanceLocation?.path, "/0")
    }
  }

  func testReferenceNotFound() {
    let schema: [String: Any] = [
      "$ref": "#/unknown",
    ]

    do {
      _ = try validate("anything", schema: schema)
    } catch {
      return
    }

    XCTFail("Validation did not throw error")
  }
}
