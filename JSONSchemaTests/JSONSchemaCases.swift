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

func fixture(named:String, forObject:AnyObject) -> NSData {
  let bundle = NSBundle(forClass:object_getClass(forObject))
  let path = bundle.URLForResource(named, withExtension: nil)!
  let data = NSData(contentsOfURL: path)!
  return data
}

func JSONFixture(named:String, forObject:AnyObject) -> [[String:AnyObject]] {
  let data = fixture(named, forObject)
  var error:NSError?
  let object: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error)
  assert(error == nil)
  return object as! [[String:AnyObject]]
}

class JSONSchemaCases: XCTestCase {
  override class func testInvocations() -> [AnyObject] {
    let bundle = NSBundle(forClass: self)
    let fileManager = NSFileManager.defaultManager()
    let files = fileManager.enumeratorAtPath(bundle.resourcePath!)!.allObjects as! [String]
    let suites = filter(files) { (path) -> Bool in
      let blacklist = [
        "ref.json",
        "refRemote.json",
        "definitions.json",

        // Optionals
        "bignum.json",
        "format.json",
      ]
      return path.hasSuffix(".json") && !contains(blacklist, path)
    }

    let cases = map(suites) { (file) -> [Case] in
      let suite = JSONFixture(file, self)
      return map(suite, makeCase(file))
    }

    let flatCases = reduce(cases, [Case](), +)
    return reduce(map(flatCases, addCase), [AnyObject](), +)
  }

  class func addCase(c:Case) -> [AnyObject] {
    return map(makeAssertions(c), addAssertion)
  }

  class func addAssertion(assertion:Assertion) -> AnyObject {
    return addTest(assertion.0, closure: assertion.1)
  }

  class func addTest(name:String, closure:() -> ()) -> AnyObject {
    let block : @objc_block (AnyObject!) -> () = { (instance : AnyObject!) -> () in
      closure()
    }

    let imp = imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
    let selectorName = name.stringByReplacingOccurrencesOfString(" ", withString: "_", options: NSStringCompareOptions(0), range: nil)
    let selector = Selector(selectorName)
    let method = class_getInstanceMethod(self, "example") // No @encode in swift, creating a dummy method to get encoding
    let types = method_getTypeEncoding(method)
    let added = class_addMethod(self, selector, imp, types)
    println(name)
    assert(added, "Failed to add `\(name)` as `\(selector)`")

    return self.testCaseWithSelector(selector).invocation
  }

  func example() { /* See addTest() */ }
}

struct Test {
  let description:String
  let data:AnyObject
  let value:Bool

  init(description:String, data:AnyObject, value:Bool) {
    self.description = description
    self.data = data
    self.value = value
  }
}

func makeTest(object:[String:AnyObject]) -> Test {
  return Test(description: object["description"] as! String, data: object["data"] as AnyObject!, value: object["valid"] as! Bool)
}

struct Case {
  let description:String
  let schema:[String:AnyObject]
  let tests:[Test]

  init(description:String, schema:[String:AnyObject], tests:[Test]) {
    self.description = description
    self.schema = schema
    self.tests = tests
  }
}

func makeCase(filename:String)(object:[String:AnyObject]) -> Case {
  let description = object["description"] as! String
  let schema = object["schema"] as! [String:AnyObject]
  let tests = map(object["tests"] as! [[String: AnyObject]], makeTest)
  let caseName = filename.stringByDeletingPathExtension
  return Case(description: "\(caseName) \(description)", schema: schema, tests: tests)
}

typealias Assertion = (String, () -> ())

func makeAssertions(c:Case) -> ([Assertion]) {
  return map(c.tests) { test -> Assertion in
    return ("\(c.description) \(test.description)", {
      let result = validate(test.data, c.schema)
      switch result {
      case .Valid:
        XCTAssertEqual(result.valid, test.value, "Result is valid")
      case .Invalid(let errors):
        XCTAssertEqual(result.valid, test.value, "Failed validation: \(errors)")
      }
    })
  }
}
