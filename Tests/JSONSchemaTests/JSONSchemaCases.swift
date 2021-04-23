import Foundation
import XCTest
import PathKit

@testable import JSONSchema


func JSONFixture(_ path: Path) throws -> [[String: Any]] {
  let object = try JSONSerialization.jsonObject(with: try path.read(), options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [[String: Any]]
}


func draft4Validator(schema: Any, instance: Any) throws -> ValidationResult {
  if let schema = schema as? Bool {
    return try Draft4Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return try Draft4Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft6Validator(schema: Any, instance: Any) throws -> ValidationResult {
  if let schema = schema as? Bool {
    return try Draft6Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return try Draft6Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft7Validator(schema: Any, instance: Any) throws -> ValidationResult {
  if let schema = schema as? Bool {
    return try Draft7Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return try Draft7Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft201909Validator(schema: Any, instance: Any) throws -> ValidationResult {
  if let schema = schema as? Bool {
    return try Draft201909Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return try Draft201909Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


func draft202012Validator(schema: Any, instance: Any) throws -> ValidationResult {
  if let schema = schema as? Bool {
    return try Draft202012Validator(schema: schema).validate(instance: instance)
  }

  if let schema = schema as? [String: Any] {
    return try Draft202012Validator(schema: schema).validate(instance: instance)
  }

  fatalError()
}


#if os(Linux)
  let additionalExclusions = [
    // optional
    "non-bmp-regex.json",
  ]
#else
  let additionalExclusions: [String] = []
#endif


class JSONSchemaCases: XCTestCase {
  func testJSONSchemaDraft4() throws {
    try test(name: "draft4", validator: draft4Validator, excluding: [
      "refRemote.json",

      // optional
      "bignum.json",
      "ecmascript-regex.json",
      "zeroTerminatedFloats.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional formats
      "date-time.json",
      "email.json",
      "hostname.json",
    ] + additionalExclusions)
  }

  func testJSONSchemaDraft6() throws {
    try test(name: "draft6", validator: draft6Validator, excluding: [
      "refRemote.json",

      // optional
      "bignum.json",
      "format.json",
      "ecmascript-regex.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional formats
      "date-time.json",
      "email.json",
      "hostname.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions)
  }

  func testJSONSchemaDraft7() throws {
    try test(name: "draft7", validator: draft7Validator, excluding: [
      "refRemote.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional, format
      "date-time.json",
      "date.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions)
  }

  func testJSONSchemaDraft2019_09() throws {
    try test(name: "draft2019-09", validator: draft201909Validator, excluding: [
      "defs.json",
      "refRemote.json",
      "id.json",
      "recursiveRef.json",

      // unsupported
      "unevaluatedProperties.json",
      "unevaluatedItems.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",
      "ecmascript-regex.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional, format
      "format.json",
      "date-time.json",
      "date.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions)
  }

  func testJSONSchemaDraft2020_12() throws {
    try test(name: "draft2020-12", validator: draft202012Validator, excluding: [
      "defs.json",
      "refRemote.json",
      "id.json",

      "ref.json",
      "dynamicRef.json",

      // unsupported
      "unevaluatedProperties.json",
      "unevaluatedItems.json",

      // optional
      "bignum.json",
      "ecmascript-regex.json",
      "float-overflow.json",

      // optional, format
      "format.json",
      "date-time.json",
      "date.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions)
  }

  func test(name: String, validator: @escaping ((_ schema: Any, _ instance: Any) throws -> (ValidationResult)), excluding: [String]) throws {
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
      for (_, assertion) in makeAssertions(c, validator) {
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


func makeAssertions(_ c: Case, _ validator: @escaping ((_ schema: Any, _ instance: Any) throws -> (ValidationResult))) -> ([Assertion]) {
  return c.tests.map { test -> Assertion in
    let label = "\(c.description) \(test.description)"
    return (label, {
      let result: ValidationResult

      if label == "ipv4 validation of IP addresses leading zeroes should be rejected, as they are treated as octals" {
        // SKIP see discussion in https://github.com/json-schema-org/JSON-Schema-Test-Suite/pull/469
        return
      }

      if let schema = c.schema as? [String: Any] {
        do {
          result = try validator(schema, test.data)
        } catch {
          XCTFail(error.localizedDescription)
          return
        }
      } else if let schema = c.schema as? Bool {
        do {
          result = try validator(schema, test.data)
        } catch {
          XCTFail(error.localizedDescription)
          return
        }
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
