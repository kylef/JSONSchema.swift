import Spectre
import XCTest
@testable import JSONSchema


public let testSchema: ((ContextType) -> Void) = {
  var schema: Schema!

  $0.before {
    schema = Schema([
      "title": "Product",
      "description": "A product from Acme's catalog",
      "type": "object",
    ])
  }

  $0.it("contains title accessor") {
    try expect(schema.title) == "Product"
  }

  $0.it("contains description accessor") {
    try expect(schema.description) == "A product from Acme's catalog"
  }

  $0.it("contains type accessor") {
    try expect(schema.type) == [Type.object]
  }

  $0.it("can validate with matching value") {
    try expect(try schema.validate([String: Any]()).valid).to.beTrue()
  }

  $0.it("can validate with mismatching value") {
    try expect(try schema.validate([String]()).valid).to.beFalse()
  }

  $0.it("can be validated with iterable interface") {
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
      try expect(error.description) == "Required property 'name' is missing"
      counter += 1
    }

    try expect(counter) == 1

    let result = try Array(schema.validate(["price": 34.99]))

    try expect(result.map(\.description)) == [
      "Required property 'name' is missing"
    ]
  }

  $0.it("tests the readme example") {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    try expect(schema.validate(["name": "Eggs", "price": 34.99]).valid).to.beTrue()
    try expect(schema.validate(["price": 34.99]).valid).to.beFalse()
  }
}


public let testSchemaDetection: ((ContextType) -> Void) = {
  $0.it("uses draft 2020-12 by default") {
    let result = try validator(for: [:])
    try expect(result).beOfType(Draft202012Validator.self)
  }

  $0.it("throws an error for an unknown metaschema") {
    try expect(try validator(for: ["$schema": "https://example.com/schema"])).toThrow()
  }

  $0.describe("draft-04 detection") {
    $0.it("detects metaschema with fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-04/schema#"])
      try expect(result).beOfType(Draft4Validator.self)
    }

    $0.it("detects metaschema without fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-04/schema"])
      try expect(result).beOfType(Draft4Validator.self)
    }
  }

  $0.describe("draft-06 detection") {
    $0.it("detects metaschema with fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-06/schema#"])
      try expect(result).beOfType(Draft6Validator.self)
    }

    $0.it("detects metaschema without fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-06/schema"])
      try expect(result).beOfType(Draft6Validator.self)
    }
  }

  $0.describe("draft-07 detection") {
    $0.it("detects metaschema with fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-07/schema#"])
      try expect(result).beOfType(Draft7Validator.self)
    }

    $0.it("detects metaschema without fragment") {
      let result = try validator(for: ["$schema": "http://json-schema.org/draft-07/schema"])
      try expect(result).beOfType(Draft7Validator.self)
    }
  }

  $0.describe("draft 2019-09 detection") {
    $0.it("detects metaschema with fragment") {
      let result = try validator(for: ["$schema": "https://json-schema.org/draft/2019-09/schema#"])
      try expect(result).beOfType(Draft201909Validator.self)
    }

    $0.it("detects metaschema without fragment") {
      let result = try validator(for: ["$schema": "https://json-schema.org/draft/2019-09/schema"])
      try expect(result).beOfType(Draft201909Validator.self)
    }
  }

  $0.describe("draft 2020-12 detection") {
    $0.it("detects metaschema with fragment") {
      let result = try validator(for: ["$schema": "https://json-schema.org/draft/2020-12/schema#"])
      try expect(result).beOfType(Draft202012Validator.self)
    }

    $0.it("detects metaschema without fragment") {
      let result = try validator(for: ["$schema": "https://json-schema.org/draft/2020-12/schema"])
      try expect(result).beOfType(Draft202012Validator.self)
    }
  }
}
