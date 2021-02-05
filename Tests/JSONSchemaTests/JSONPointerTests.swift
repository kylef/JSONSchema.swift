import XCTest
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


class JSONPointerTests: XCTestCase {
  // Resolution (https://tools.ietf.org/html/rfc6901#section-5)

  func testResolveWholeDocument() {
    let pointer = JSONPointer(path: "")

    XCTAssertEqual(pointer.resolve(document: document) as? NSDictionary, document as NSDictionary)
  }

  func testResolveObjectValue() {
    let pointer = JSONPointer(path: "/foo")

    XCTAssertEqual(pointer.resolve(document: document) as? [String], ["bar", "baz"])
  }

  func testResolveArrayIndex() {
    let pointer = JSONPointer(path: "/foo/0")

    XCTAssertEqual(pointer.resolve(document: document) as? String, "bar")

    let pointer1 = JSONPointer(path: "/foo/1")

    XCTAssertEqual(pointer1.resolve(document: document) as? String, "baz")
  }

  func testResolveObjectValueKeyEmptyString() {
    let pointer = JSONPointer(path: "/")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 0)
  }

  func testResolveObjectValueKeyEscapedForwardSlash() {
    let pointer = JSONPointer(path: "/a~1b")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 1)
  }

  func testResolveObjectValueKeyPercent() {
    let pointer = JSONPointer(path: "/c%d")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 2)
  }

  func testResolveObjectValueKeyCarot() {
    let pointer = JSONPointer(path: "/e^f")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 3)
  }

  func testResolveObjectValueKeyPipe() {
    let pointer = JSONPointer(path: "/g|h")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 4)
  }

  func testResolveObjectValueBackslace() {
    let pointer = JSONPointer(path: "/i\\j")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 5)
  }

  func testResolveObjectValueDoubleQuote() {
    let pointer = JSONPointer(path: "/k\"l")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 6)
  }

  func testResolveObjectValueSpace() {
    let pointer = JSONPointer(path: "/ ")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 7)
  }

  func testResolveObjectValueEscapedTilde() {
    let pointer = JSONPointer(path: "/m~0n")

    XCTAssertEqual(pointer.resolve(document: document) as? Int, 8)
  }

  // Resolve (negative cases)

  func testResolveArrayIndexOutOfBounds() {
    let pointer = JSONPointer(path: "/foo/2")

    XCTAssertNil(pointer.resolve(document: document))
  }

  func testResolveArrayIndexNegative() {
    let pointer = JSONPointer(path: "/foo/-1")

    XCTAssertNil(pointer.resolve(document: document))
  }

  func testResolveObjectMissingKey() {
    let pointer = JSONPointer(path: "/test")

    XCTAssertNil(pointer.resolve(document: document))
  }
}
