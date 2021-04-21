import XCTest
@testable import JSONSchema


class DurationTests: XCTestCase {
  // dur-date

  func testDay() {
    XCTAssertTrue(isValidDuration("P3D"))
  }

  func testMonth() {
    XCTAssertTrue(isValidDuration("P2M"))
  }

  func testMonthDay() {
    XCTAssertTrue(isValidDuration("P2M1D"))
  }

  func testYear() {
    XCTAssertTrue(isValidDuration("P5Y"))
  }

  func testYearMonth() {
    XCTAssertTrue(isValidDuration("P5Y2M"))
  }

  func testYearMonthDay() {
    XCTAssertTrue(isValidDuration("P5Y2M1D"))
  }

  func testDateTime() {
    XCTAssertTrue(isValidDuration("P1DT5M"))
  }

  // dur-time

  func testHour() {
    XCTAssertTrue(isValidDuration("PT1H"))
  }

  func testHourMinute() {
    XCTAssertTrue(isValidDuration("PT1H5M"))
  }

  func testHourMinuteSecond() {
    XCTAssertTrue(isValidDuration("PT1H5M20S"))
  }

  func testMinute() {
    XCTAssertTrue(isValidDuration("PT1M"))
  }

  func testMinuteSecond() {
    XCTAssertTrue(isValidDuration("PT5M10S"))
  }

  func testSecond() {
    XCTAssertTrue(isValidDuration("PT1S"))
  }

  // dur-week

  func testWeek() {
    XCTAssertTrue(isValidDuration("P1W"))
  }

  // Negative

  func testMissingDuration() {
    XCTAssertFalse(isValidDuration("P"))
  }

  func testMissingTime() {
    XCTAssertFalse(isValidDuration("PT"))
  }
}
