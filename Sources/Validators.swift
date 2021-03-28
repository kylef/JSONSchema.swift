import CoreFoundation
import Foundation

/// Creates a Validator which always returns an valid result
func validValidation(_ value: Any) -> AnySequence<ValidationError> {
  return AnySequence(EmptyCollection())
}

/// Creates a Validator which always returns an invalid result with the given error
func invalidValidation(_ context: Context, _ error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    return AnySequence([
      ValidationError(
        error,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }
}

// MARK: Shared

func type(context: Context, type: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  func ensureArray(_ value: Any) -> [String]? {
    if let value = value as? [String] {
      return value
    }

    if let value = value as? String {
      return [value]
    }

    return nil
  }

  guard let type = ensureArray(type) else {
    return AnySequence(EmptyCollection())
  }

  if type.contains(where :{ isType($0, instance) }) {
    return AnySequence(EmptyCollection())
  }

  let types = type.map { "'\($0)'" }.joined(separator: ", ")
  return AnySequence([
    ValidationError(
      "'\(instance)' is not of type \(types)",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}

func isInteger(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
#if os(Linux)
  return CFGetTypeID(number) != CFBooleanGetTypeID() && NSNumber(value: number.intValue) == number
#else
  return CFGetTypeID(number) != CFBooleanGetTypeID() && (!CFNumberIsFloatType(number) || NSNumber(value: number.intValue) == number)
#endif
}

func isNumber(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
  return CFGetTypeID(number) != CFBooleanGetTypeID()
}

func isObject(_ instance: Any) -> Bool {
  return instance is String
}

func isDictionary(_ instance: Any) -> Bool {
  return instance is NSDictionary
}

func isArray(_ instance: Any) -> Bool {
  return instance is NSArray
}

func isBoolean(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
  return CFGetTypeID(number) == CFBooleanGetTypeID()
}

func isNull(_ instance: Any) -> Bool {
  return instance is NSNull
}

/// Validate the given value is of the given type
func isType(_ type: String, _ instance: Any) -> Bool {
  switch type {
  case "integer":
    return isInteger(instance)
  case "number":
    return isNumber(instance)
  case "string":
    return isObject(instance)
  case "object":
    return isDictionary(instance)
  case "array":
    return isArray(instance)
  case "boolean":
    return isBoolean(instance)
  case "null":
    return isNull(instance)
  default:
    return false
  }
}

func isEqual(_ lhs: NSObject, _ rhs: NSObject) -> Bool {
  if let lhs = lhs as? NSNumber, let rhs = rhs as? NSNumber, CFGetTypeID(lhs) != CFGetTypeID(rhs) {
    return false
  }

  if let lhs = lhs as? NSArray, let rhs = rhs as? NSArray {
    guard lhs.count == rhs.count else {
      return false
    }

    return !zip(lhs, rhs).contains(where: {
      !isEqual($0.0 as! NSObject, $0.1 as! NSObject)
    })
  }

  if let lhs = lhs as? NSDictionary, let rhs = rhs as? NSDictionary {
    guard lhs.count == rhs.count else {
      return false
    }

    for (key, lhsValue) in lhs {
      guard let rhsValue = rhs[key] else {
        return false
      }

      if !isEqual(lhsValue as! NSObject, rhsValue as! NSObject) {
        return false
      }
    }

    return true
  }

  return lhs == rhs
}


extension Sequence where Iterator.Element == ValidationError {
  func validationResult() -> ValidationResult {
    let errors = Array(self)
    if errors.isEmpty {
      return .valid
    }

    return .invalid(errors)
  }

  var isValid: Bool {
    return self.first(where: { _ in true }) == nil
  }
}


func unsupported(_ keyword: String) -> (_ context: Context, _ value: Any, _ instance: Any, _ schema: [String: Any]) -> AnySequence<ValidationError> {
  return { (context, _, _, _) in
    return AnySequence([
      ValidationError(
        "'\(keyword)' is not supported.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      ),
    ])
  }
}
