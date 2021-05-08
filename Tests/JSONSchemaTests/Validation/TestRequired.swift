import Spectre
@testable import JSONSchema


public let testRequired: ((ContextType) -> Void) = {
  $0.it("returns error with object missing required key") {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "items": [
        "required": ["test"],
      ]
    ]

    let result = try validate([[:]], schema: schema)

    switch result {
    case .valid:
      throw failure("Validation should fail")
    case .invalid(let errors):
      try expect(errors.count) == 1
      let error = errors[0]

      try expect(error.description) == "Required property 'test' is missing"
      try expect(error.instanceLocation.path) == "/0"
      try expect(error.keywordLocation.path) == "#/items/required"
    }
  }
}
