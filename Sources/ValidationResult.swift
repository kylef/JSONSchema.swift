public class ValidationError: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  public let description: String

  init(_ value: String) {
    description = value
  }

  public required init(stringLiteral value: String) {
    description = value
  }

  public required init(stringInterpolation: DefaultStringInterpolation) {
    description = stringInterpolation.description
  }
}


public enum ValidationResult {
  case valid
  case invalid([ValidationError])

  public var valid: Bool {
    switch self {
    case .valid:
      return true
    case .invalid:
      return false
    }
  }

  public var errors: [ValidationError]? {
    switch self {
    case .valid:
      return nil
    case .invalid(let errors):
      return errors
    }
  }
}
