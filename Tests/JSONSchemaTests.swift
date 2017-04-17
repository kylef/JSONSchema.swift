//
//  JSONSchemaTests.swift
//  JSONSchemaTests
//
//  Created by Kyle Fuller on 23/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import JSONSchema

class JSONSchemaTests: XCTestCase {
  var schema:Schema!

  override func setUp() {
    super.setUp()

    schema = Schema([
      "title": "Product",
      "description": "A product from Acme's catalog",
      "type": "object",
    ])
  }

  func testTitle() {
    XCTAssertEqual(schema.title!, "Product")
  }

  func testDescription() {
    XCTAssertEqual(schema.description!, "A product from Acme's catalog")
  }

  func testType() {
    XCTAssertEqual(schema.type!, [Type.Object])
  }

  func testSuccessfulValidation() {
    XCTAssertTrue(schema.validate([String:Any]()).valid)
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

  /// Tests that the error output provides only the keys that were missing instead of all required keys.
  func testInvalidSchema_returnsErrorForMissingRequiredProperty() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
        "bar": ["type": "string"]
      ],
      "required": ["name", "price", "bar"],
    ])
    
    let result: ValidationResult = schema.validate(["name": "foo", "bar": "foo"])
    
    XCTAssertFalse(result.valid)
    XCTAssertNotNil(result.errors)
    XCTAssertEqual(result.errors![0], "Required properties are missing '[\"price\"]'")
    XCTAssertNotEqual(result.errors![0], "Required properties are missing '[\"name\", \"price\", \"bar\"]'")
  }
  
  func testInvalidSchema_returnsErrorForMissingRequiredProperties() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
        "bar": ["type": "string"]
      ],
      "required": ["name", "price", "bar"],
      ])
    
    let result: ValidationResult = schema.validate(["name": "foo"])
    
    XCTAssertFalse(result.valid)
    XCTAssertNotNil(result.errors)
    XCTAssertEqual(result.errors![0], "Required properties are missing '[\"price\", \"bar\"]'")
  }
}
