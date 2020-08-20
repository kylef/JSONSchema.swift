import Foundation
import XCTest
import PathKit

@testable import JSONSchema


func JSONFixture(_ path: Path) throws -> [[String: Any]] {
  let object = try JSONSerialization.jsonObject(with: try path.read(), options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [[String: Any]]
}


func draft4Validator(schema: Any, instance: Any) -> ValidationResult {
  if let schema = schema as? Bool {
    return Draft4Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return validate(instance, schema: schema)
  }

  fatalError()
}


func draft6Validator(schema: Any, instance: Any) -> ValidationResult {
  if let schema = schema as? Bool {
    return Draft6Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return Draft6Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft7Validator(schema: Any, instance: Any) -> ValidationResult {
  if let schema = schema as? Bool {
    return Draft7Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return Draft7Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft201909Validator(schema: Any, instance: Any) -> ValidationResult {
  if let schema = schema as? Bool {
    return Draft201909Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return Draft201909Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


class JSONSchemaCases: XCTestCase {
  func testJSONSchemaDraft4() throws {
    try test(name: "draft4", validator: draft4Validator, excluding: [
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "ecmascript-regex.json",
      "zeroTerminatedFloats.json",

      // optional formats
      "date-time.json",
      "email.json",
      "hostname.json",
    ])
  }

  func testJSONSchemaDraft6() throws {
    try test(name: "draft6", validator: draft6Validator, excluding: [
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "format.json",
      "ecmascript-regex.json",

      // optional formats
      "date-time.json",
      "email.json",
      "hostname.json",
      "json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ])
  }

  func testJSONSchemaDraft7() throws {
    try test(name: "draft7", validator: draft7Validator, excluding: [
      "ref.json",
      "refRemote.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",

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

  func testJSONSchemaDraft2019_09() throws {
    try test(name: "draft2019-09", validator: draft201909Validator, excluding: [
      "defs.json",
      "ref.json",
      "refRemote.json",
      "anchor.json",
      "unevaluatedProperties.json",
      "unevaluatedItems.json",
      "id.json",

      "minContains.json",
      "maxContains.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",
      "ecmascript-regex.json",

      // optional, format
      "date-time.json",
      "date.json",
      "duration.json",
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
      "uuid.json",
    ])
  }

  func test(name: String, validator: @escaping ((_ schema: Any, _ instance: Any) -> (ValidationResult)), excluding: [String]) throws {
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
          if let schema = $0.schema as? [String: Any] {
            let format = schema["format"] as! String
            return !["date-time", "email", "hostname"].contains(format)
          }

          return true
        }
      }

      return suite.map(makeCase(file.lastComponent))
    }

    let flatCases = cases.reduce([Case](), +)
    for c in flatCases {
      for (name, assertion) in makeAssertions(c, validator) {
        // TODO: Improve testing
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
  let schema: Any
  let tests: [Test]
}


func makeCase(_ filename: String) -> (_ object: [String: Any]) -> Case {
  return { object in
    let description = object["description"] as! String
    let schema = object["schema"]!
    let tests = (object["tests"] as! [[String: Any]]).map(makeTest)
    let caseName = (filename as NSString).deletingPathExtension
    return Case(description: "\(caseName) \(description)", schema: schema, tests: tests)
  }
}


typealias Assertion = (String, () -> ())


func makeAssertions(_ c: Case, _ validator: @escaping ((_ schema: Any, _ instance: Any) -> (ValidationResult))) -> ([Assertion]) {
  return c.tests.map { test -> Assertion in
    let label = "\(c.description) \(test.description)"
    return (label, {
      let result: ValidationResult

      if let schema = c.schema as? [String: Any] {
        result = validator(schema, test.data)
      } else if let schema = c.schema as? Bool {
        result = validator(schema, test.data)
      } else {
        fatalError()
      }

      switch result {
      case .valid:
        XCTAssertEqual(result.valid, test.value, "\(label) -- Result is valid")
      case .invalid(let errors):
        XCTAssertEqual(result.valid, test.value, "\(label) -- Failed validation: \(errors)")
      }
    })
  }
}
