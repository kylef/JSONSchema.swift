public class ValidationError {
  public let description: String

  init(_ value: String, instanceLocation: JSONPointer) {
    self.description = value
    self.instanceLocation = instanceLocation
  }

  public let instanceLocation: JSONPointer
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
