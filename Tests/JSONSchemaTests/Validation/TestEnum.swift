import Spectre
@testable import JSONSchema


public let testEnum: ((ContextType) -> Void) = {
  $0.it("returns error when validating value not found in enum") {
    let schema: [String: Any] = [
      "$schema": "http://json-schema.org/draft-07/schema#",
      "enum": ["one"],
    ]

    let result = try validate(["two"], schema: schema)

    switch result {
    case .valid:
      throw failure("Validation should fail")
    case .invalid(let errors):
      try expect(errors.count) == 1
      let error = errors[0]

      // FIXME try expect(error.description) == ""
      try expect(error.instanceLocation.path) == ""
      try expect(error.keywordLocation.path) == "#/enum"
    }
  }
}
