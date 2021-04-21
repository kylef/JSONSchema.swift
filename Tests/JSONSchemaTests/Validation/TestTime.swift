import XCTest
@testable import JSONSchema


class TimeFormatTests: XCTestCase {
  func testTimeWithoutSecondFraction() throws {
    let schema: [String: Any] = [
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "format": "time",
    ]

    let result = try validate("23:59:50Z", schema: schema)

    XCTAssertTrue(result.valid)
  }
}
