import Foundation
import Spectre
@testable import JSONSchema


public let testValidationError: ((ContextType) -> Void) = {
  $0.it("can be converted to JSON") {
    let error = ValidationError(
      "example description",
      instanceLocation: JSONPointer(path: "/test/1"),
      keywordLocation: JSONPointer(path: "#/example")
    )

    let jsonData = try JSONEncoder().encode(error)
    let json = try! JSONSerialization.jsonObject(with: jsonData) as! NSDictionary

    try expect(json) == [
      "error": "example description",
      "instanceLocation": "/test/1",
      "keywordLocation": "#/example",
    ]
  }
}
