import Foundation
import Spectre
import PathKit

@testable import JSONSchema


public let testSchemaCases: ((ContextType) -> Void) = {
  $0.describe("draft4") { context in
    try! buildTests("draft4", excluding: [
      "refRemote.json",

      // optional
      "bignum.json",
      "ecmascript-regex.json",
      "zeroTerminatedFloats.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional formats
      "email.json",
      "hostname.json",
    ] + additionalExclusions, in: context, with: draft4Validator)
  }

  $0.describe("draft6") { context in
    try! buildTests("draft6", excluding: [
      "refRemote.json",
      "unknownKeyword.json",

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
    ] + additionalExclusions, in: context, with: draft6Validator)
  }

  $0.describe("draft7") { context in
    try! buildTests("draft7", excluding: [
      "refRemote.json",
      "unknownKeyword.json",

      // optional
      "bignum.json",
      "content.json",
      "ecmascript-regex.json",
      "float-overflow.json",
      "infinite-loop-detection.json",

      // optional, format
      "date-time.json",
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions, in: context, with: draft7Validator)
  }

  $0.describe("draft 2019-09") { context in
    try! buildTests("draft2019-09", excluding: [
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
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions, in: context, with: draft201909Validator)
  }

  $0.describe("draft 2020-12") { context in
    try! buildTests("draft2020-12", excluding: [
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
      "email.json",
      "hostname.json",
      "idn-email.json",
      "idn-hostname.json",
      "iri-reference.json",
      "iri.json",
      "relative-json-pointer.json",
      "uri-reference.json",
      "uri-template.json",
    ] + additionalExclusions, in: context, with: draft202012Validator)
  }
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


func buildTests(_ name: String, excluding: [String], in context: ContextType, with validator: @escaping ((_ schema: Any, _ instance: Any) throws -> (ValidationResult))) throws {
  let filePath = #file
  let path = Path(filePath) + ".." + ".." + "Cases" + "tests" + name

  let testCases = try path
    .recursiveChildren()
    .filter { $0.extension == "json" }

  for file in testCases {
    let (contentData, suite) = try JSONFixture(file)
    let content = String(data: contentData, encoding: .utf8)!
    let f = file.absolute().string

    context.describe(file.lastComponentWithoutExtension) {
      let cases = suite.map(makeCase(file.lastComponent))

      for `case` in cases {
        $0.describe(`case`.description) {
          for test in `case`.tests {
            $0.it(test.description, file: f, line: 1) {
              if excluding.contains(file.lastComponent) {
                throw skip()
              }

              if test.description == "leading zeroes should be rejected, as they are treated as octals" {
                // SKIP see discussion in https://github.com/json-schema-org/JSON-Schema-Test-Suite/pull/469
                throw skip()
              }

              let result: ValidationResult

              if let schema = `case`.schema as? [String: Any] {
                result = try validator(schema, test.data)
              } else if let schema = `case`.schema as? Bool {
                result = try validator(schema, test.data)
              } else {
                throw failure("schema is not object or bool", file: f)
              }

              // vaugly find the relevant source line for source maps in tests
              var l = 1
              if let range = content.range(of: test.description) {
                let part = content.prefix(upTo: range.lowerBound)
                l = part.filter { $0 == "\n" }.count + 2
              }

              if result.valid != test.value {
                switch result {
                case .valid:
                  try expect(result.valid, file: f, line: l) == test.value
                case .invalid(let errors):
                  let error = errors.map { "  " + $0.description }.joined(separator: "\n")
                  throw failure("encountered unexpected errors:\n\n\(error)", file: f, line: l)
                }
              }
            }
          }
        }
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


func JSONFixture(_ path: Path) throws -> (content: Data, fixture: [[String: Any]]) {
  let content: Data = try path.read()
  let object = try JSONSerialization.jsonObject(with: content, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return (content, object as! [[String: Any]])
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
