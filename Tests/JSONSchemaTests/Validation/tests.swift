import Spectre


public let testValidation: ((ContextType) -> Void) = {
  $0.describe("#ref", closure: testRef)
  $0.describe("#enum", closure: testEnum)
  $0.describe("#required", closure: testRequired)

  $0.describe("#format") {
    $0.describe("duration", closure: testDurationFormat)
  }
}
