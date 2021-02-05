public class ValidationError: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  public let description: String

  init(_ value: String, instanceLocation: JSONPointer? = nil) {
    self.description = value
    self.instanceLocation = instanceLocation
  }

  public required init(stringLiteral value: String) {
    description = value
    instanceLocation = nil
  }

  public required init(stringInterpolation: DefaultStringInterpolation) {
    description = stringInterpolation.description
    instanceLocation = nil
  }

  // FIXME make this part of public interface
  let instanceLocation: JSONPointer?
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
