import Foundation
import Spectre
@testable import JSONSchema


// Defined from https://tools.ietf.org/html/rfc6901#section-5
fileprivate let document: [String: Any] = [
  "foo": ["bar", "baz"],
  "": 0,
  "a/b": 1,
  "c%d": 2,
  "e^f": 3,
  "g|h": 4,
  "i\\j": 5,
  "k\"l": 6,
  " ": 7,
  "m~n": 8
]


public let testJSONPointer: ((ContextType) -> Void) = {
  // Resolution (https://tools.ietf.org/html/rfc6901#section-5)

  $0.it("can resoleve entire document") {
    let pointer = JSONPointer(path: "")

    try expect(pointer.resolve(document: document) as? NSDictionary) == document as NSDictionary
  }

  $0.it("can resolve object value") {
    let pointer = JSONPointer(path: "/foo")

    try expect(pointer.resolve(document: document) as? [String]) == ["bar", "baz"]
  }

  $0.it("can resolve array index") {
    let pointer = JSONPointer(path: "/foo/0")

    try expect(pointer.resolve(document: document) as? String) == "bar"

    let pointer1 = JSONPointer(path: "/foo/1")

    try expect(pointer1.resolve(document: document) as? String) == "baz"
  }

  $0.it("can resolve object value via empty key") {
    let pointer = JSONPointer(path: "/")

    try expect(pointer.resolve(document: document) as? Int) == 0
  }

  $0.it("can resolve object value with escaped slash in key") {
    let pointer = JSONPointer(path: "/a~1b")

    try expect(pointer.resolve(document: document) as? Int) == 1
  }

  $0.it("can resolve object value with percent in key") {
    let pointer = JSONPointer(path: "/c%d")

    try expect(pointer.resolve(document: document) as? Int) == 2
  }

  $0.it("can resolve object value with carot in key") {
    let pointer = JSONPointer(path: "/e^f")

    try expect(pointer.resolve(document: document) as? Int) == 3
  }

  $0.it("can resolve object value with pipe in key") {
    let pointer = JSONPointer(path: "/g|h")

    try expect(pointer.resolve(document: document) as? Int) == 4
  }

  $0.it("can resolve object value with backslash in key") {
    let pointer = JSONPointer(path: "/i\\j")

    try expect(pointer.resolve(document: document) as? Int) == 5
  }

  $0.it("can resolve object value with double quote in key") {
    let pointer = JSONPointer(path: "/k\"l")

    try expect(pointer.resolve(document: document) as? Int) == 6
  }

  $0.it("can resolve object value with double space in key") {
    let pointer = JSONPointer(path: "/ ")

    try expect(pointer.resolve(document: document) as? Int) == 7
  }

  $0.it("can resolve object value with escaped tilde in key") {
    let pointer = JSONPointer(path: "/m~0n")

    try expect(pointer.resolve(document: document) as? Int) == 8
  }

  // Resolve (negative cases)

  $0.it("can resolve out of bounds array index") {
    let pointer = JSONPointer(path: "/foo/2")

    try expect(pointer.resolve(document: document)).to.beNil()
  }

  $0.it("can resolve negative array index") {
    let pointer = JSONPointer(path: "/foo/-1")

    try expect(pointer.resolve(document: document)).to.beNil()
  }

  $0.it("can resolve missing key in object") {
    let pointer = JSONPointer(path: "/test")

    try expect(pointer.resolve(document: document)).to.beNil()
  }

  // MARK: - #path

  $0.describe("#path") {
    $0.it("returns a string representation of path") {
      let pointer = JSONPointer(path: "/foo")
      try expect(pointer.path) == "/foo"
    }

    $0.it("returns a string representation of path escaping slashes") {
      let pointer = JSONPointer(path: "/a~1b")
      try expect(pointer.path) == "/a~1b"
    }
  }
}
