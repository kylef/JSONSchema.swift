//
//  JSONSchemaCases.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import PathKit

import JSONSchema

func JSONFixture(_ path: Path) throws -> [[String:Any]] {
  let object = try JSONSerialization.jsonObject(with: try! path.read(), options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [[String:Any]]
}

class JSONSchemaCases: XCTestCase {
  func testEverything() throws {
    let filePath = #file
    let path = Path(filePath) + ".." + ".." + "Cases" + "tests" + "draft4"

    let testCases = try path
      .recursiveChildren()
      .filter { $0.extension == "json" }
      .filter {
        let blacklist = [
          "ref.json",
          "refRemote.json",
          "definitions.json",

          // Optionals
          "bignum.json",
        ]

        return !blacklist.contains($0.lastComponent)
      }

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
  let description:String
  let data:Any
  let value:Bool

  init(description:String, data:Any, value:Bool) {
    self.description = description
    self.data = data
    self.value = value
  }
}

func makeTest(_ object:[String:Any]) -> Test {
  return Test(description: object["description"] as! String, data: object["data"] as Any!, value: object["valid"] as! Bool)
}

struct Case {
  let description:String
  let schema:[String:Any]
  let tests:[Test]

  init(description:String, schema:[String:Any], tests:[Test]) {
    self.description = description
    self.schema = schema
    self.tests = tests
  }
}

func makeCase(_ filename: String) -> (_ object: [String:Any]) -> Case {
  return { object in
    let description = object["description"] as! String
    let schema = object["schema"] as! [String:Any]
    let tests = (object["tests"] as! [[String: Any]]).map(makeTest)
    let caseName = (filename as NSString).deletingPathExtension
    return Case(description: "\(caseName) \(description)", schema: schema, tests: tests)
  }
}

typealias Assertion = (String, () -> ())

func makeAssertions(_ c:Case) -> ([Assertion]) {
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
