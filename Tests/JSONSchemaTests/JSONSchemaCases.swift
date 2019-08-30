import Foundation
import XCTest
import PathKit

import JSONSchema


func JSONFixture(_ path: Path) throws -> [[String: Any]] {
  let object = try JSONSerialization.jsonObject(with: try path.read(), options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [[String: Any]]
}


class JSONSchemaCases: XCTestCase {
  func testJSONSchemaDraft4() throws {
    try test(name: "draft4", excluding: [
      "ref.json",
      "refRemote.json",
      "definitions.json",

      // optional
      "bignum.json",
    ])
  }

  func testJSONSchemaDraft6() throws {
    try test(name: "draft6", excluding: [
      "allOf.json",
      "anyOf.json",
      "boolean_schema.json",
      "const.json",
      "contains.json",
      "definitions.json",
      "dependencies.json",
      "exclusiveMaximum.json",
      "exclusiveMinimum.json",
      "items.json",
      "not.json",
      "oneOf.json",
      "patternProperties.json",
      "properties.json",
      "propertyNames.json",
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "format.json",
      "zeroTerminatedFloats.json",
    ])
  }

  func testJSONSchemaDraft7() throws {
    try test(name: "draft7", excluding: [
      "allOf.json",
      "anyOf.json",
      "boolean_schema.json",
      "const.json",
      "contains.json",
      "definitions.json",
      "dependencies.json",
      "exclusiveMaximum.json",
      "exclusiveMinimum.json",
      "if-then-else.json",
      "items.json",
      "not.json",
      "oneOf.json",
      "patternProperties.json",
      "properties.json",
      "propertyNames.json",
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "content.json",
      "zeroTerminatedFloats.json",

      // optional, format
      "date-time.json",
      "date.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "json-pointer.json",
      "regex.json",
      "relative-json-pointer.json",
      "time.json",
      "uri-reference.json",
      "uri-template.json",
    ])
  }

  func testJSONSchemaDraft2019_08() throws {
    try test(name: "draft2019-08", excluding: [
      "allOf.json",
      "anyOf.json",
      "boolean_schema.json",
      "const.json",
      "contains.json",
      "defs.json",
      "dependencies.json",
      "exclusiveMaximum.json",
      "exclusiveMinimum.json",
      "if-then-else.json",
      "items.json",
      "not.json",
      "oneOf.json",
      "patternProperties.json",
      "properties.json",
      "propertyNames.json",
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",
      "zeroTerminatedFloats.json",

      // optional, format
      "date-time.json",
      "date.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "json-pointer.json",
      "regex.json",
      "relative-json-pointer.json",
      "time.json",
      "uri-reference.json",
      "uri-template.json",
    ])
  }

  func test(name: String, excluding: [String]) throws {
    let filePath = #file
    let path = Path(filePath) + ".." + ".." + "Cases" + "tests" + name

    let testCases = try path
      .recursiveChildren()
      .filter { $0.extension == "json" }
      .filter { !excluding.contains($0.lastComponent) }

    let cases = try testCases.map { (file) -> [Case] in
      let suite = try JSONFixture(file)

      if file.lastComponent == "format.json" {
        let cases = suite.map(makeCase(file.lastComponent))
        return cases.filter {
          let format = $0.schema["format"] as! String
          return !["date-time", "email", "hostname"].contains(format)
        }
      }

      return suite.map(makeCase(file.lastComponent))
    }

    let flatCases = cases.reduce([Case](), +)
    for c in flatCases {
      for (name, assertion) in makeAssertions(c) {
        // TODO: Improve testing
        print(name)
        assertion()
      }
    }
  }
}


struct Test {
  let description: String
  let data: Any
  let value: Bool
}

func makeTest(_ object: [String: Any]) -> Test {
  return Test(description: object["description"] as! String, data: object["data"] as Any, value: object["valid"] as! Bool)
}


struct Case {
  let description: String
  let schema: [String: Any]
  let tests: [Test]
}


func makeCase(_ filename: String) -> (_ object: [String: Any]) -> Case {
  return { object in
    let description = object["description"] as! String
    let schema = object["schema"] as! [String: Any]
    let tests = (object["tests"] as! [[String: Any]]).map(makeTest)
    let caseName = (filename as NSString).deletingPathExtension
    return Case(description: "\(caseName) \(description)", schema: schema, tests: tests)
  }
}


typealias Assertion = (String, () -> ())


func makeAssertions(_ c: Case) -> ([Assertion]) {
  return c.tests.map { test -> Assertion in
    return ("\(c.description) \(test.description)", {
      let result = validate(test.data, schema: c.schema)
      switch result {
      case .valid:
        XCTAssertEqual(result.valid, test.value, "Result is valid")
      case .invalid(let errors):
        XCTAssertEqual(result.valid, test.value, "Failed validation: \(errors)")
      }
    })
  }
}
