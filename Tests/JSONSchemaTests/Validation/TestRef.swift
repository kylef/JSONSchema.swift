import Spectre
@testable import JSONSchema


public let testRef: ((ContextType) -> Void) = {
  $0.it("returns error for error in subschema") {
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
      throw failure("Validation should fail")
    case .invalid(let errors):
      try expect(errors.count) == 1
      let error = errors[0]

      try expect(error.description) == "'true' is not of type 'string'"
      try expect(error.instanceLocation.path) == "/0"
      try expect(error.keywordLocation.path) == "#/items/$ref/type"
    }
  }

  $0.it("throws an error when schema reference cannot be resolved") {
    let schema: [String: Any] = [
      "$ref": "#/unknown",
    ]

    try expect(try validate("anything", schema: schema)).toThrow()
  }
}
