import XCTest
import Spectre


class JSONSchemaTests: XCTestCase {
  func testJSONSchema() {
    describe("JSONPointer", testJSONPointer)
    describe("ValidationError", testValidationError)
    describe("ValidationResult", testValidationResult)
    describe("Schema", testSchema)
    describe("Schema detection", testSchemaDetection)
    describe("Schema Validation Keywords", testValidation)
    describe("JSON Schema Cases", testSchemaCases)
  }
}
