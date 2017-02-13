//
//  JSONSchemaCases.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import JSONSchema

func fixture(_ named:String, forObject:Any) -> Data {
  let bundle = Bundle(for:object_getClass(forObject))
  let path = bundle.url(forResource: named, withExtension: nil)!
  let data = try! Data(contentsOf: path)
  return data
}

func JSONFixture(_ named:String, forObject:Any) -> [[String:Any]] {
  let data = fixture(named, forObject: forObject)
  let object: Any?
  do {
    object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
  } catch {
    fatalError()
  }
  return object as! [[String:Any]]
}

class JSONSchemaCases: XCTestCase {
  func testEverything() {
    let bundle = Bundle(for: JSONSchemaCases.self)
    let fileManager = FileManager.default
    let files = fileManager.enumerator(atPath: bundle.resourcePath!)!.allObjects as! [String]
    let suites = files.filter { (path) -> Bool in
      let blacklist = [
        "ref.json",
        "refRemote.json",
        "definitions.json",

        // Optionals
        "bignum.json",
        "format.json",
      ]
      return path.hasSuffix(".json") && !blacklist.contains(path)
    }

    let cases = suites.map { (file) -> [Case] in
      let suite = JSONFixture(file, forObject: self)
      return suite.map(makeCase(file))
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
