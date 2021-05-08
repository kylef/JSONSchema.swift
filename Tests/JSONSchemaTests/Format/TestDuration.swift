import Spectre
@testable import JSONSchema


public let testDurationFormat: ((ContextType) -> Void) = {
  $0.describe("dur-date") {
    $0.it("allows day duration") {
      try expect(isValidDuration("P3D")).to.beTrue()
    }

    $0.it("allows month duration") {
      try expect(isValidDuration("P2M")).to.beTrue()
    }

    $0.it("allows month and day duration") {
      try expect(isValidDuration("P2M1D")).to.beTrue()
    }

    $0.it("allows year duration") {
      try expect(isValidDuration("P5Y")).to.beTrue()
    }

    $0.it("allows year and month duration") {
      try expect(isValidDuration("P5Y2M")).to.beTrue()
    }

    $0.it("allows year, month and day duration") {
      try expect(isValidDuration("P5Y2M1D")).to.beTrue()
    }
  }

  $0.describe("dur-time") {
    $0.it("allows hour duration") {
      try expect(isValidDuration("PT1H")).to.beTrue()
    }

    $0.it("allows hour duration with minutes") {
      try expect(isValidDuration("PT1H5M")).to.beTrue()
    }

    $0.it("allows hour duration with minutes and seconds") {
      try expect(isValidDuration("PT1H5M20S")).to.beTrue()
    }

    $0.it("allows minute duration") {
      try expect(isValidDuration("PT1M")).to.beTrue()
    }

    $0.it("allows minute duration with seconds") {
      try expect(isValidDuration("PT5M10S")).to.beTrue()
    }

    $0.it("allows second duration") {
      try expect(isValidDuration("PT1S")).to.beTrue()
    }
  }

  $0.describe("dur-week") {
    $0.it("allows weeb duration") {
      try expect(isValidDuration("P1W")).to.beTrue()
    }
  }

  $0.it("allows date and time duration") {
    try expect(isValidDuration("P1DT5M")).to.beTrue()
  }

  $0.it("fails validation without duration") {
    try expect(isValidDuration("P")).to.beFalse()
  }

  $0.it("fails validation with empty time") {
    try expect(isValidDuration("PT")).to.beFalse()
  }
}
