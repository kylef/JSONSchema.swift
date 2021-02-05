import CoreFoundation
import Foundation

/// Creates a Validator which always returns an valid result
func validValidation(_ value: Any) -> AnySequence<ValidationError> {
  return AnySequence(EmptyCollection())
}

/// Creates a Validator which always returns an invalid result with the given error
func invalidValidation(_ error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    return AnySequence([error])
  }
}

// MARK: Shared

func ref(validator: Validator, reference: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let reference = reference as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let document = validator.resolve(ref: reference) else {
    return AnySequence(["Reference not found '\(reference)'"])
  }

  let id: String?
  if let document = document as? [String: Any],
     let idValue = document[validator.resolver.idField] as? String
  {
    id = urlNormalise(idValue)
  } else {
    id = nil
  }

  if let id = id {
    validator.resolver.stack.append(id)
  }
  defer {
    if let id = id {
      assert(validator.resolver.stack.removeLast() == id,
             "popping id mismatch - if this assertion is triggered, there's probably a bug in JSON Schema validator library")
    }
  }

  return validator.descend(instance: instance, subschema: document)
}

func type(validator: Validator, type: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
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
  return AnySequence(["'\(instance)' is not of type \(types)"])
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

func anyOf(validator: Validator, anyOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let anyOf = anyOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if !anyOf.contains(where: { validator.descend(instance: instance, subschema: $0).isValid }) {
    return AnySequence(["\(instance) does not meet anyOf validation rules."])
  }

  return AnySequence(EmptyCollection())
}

func oneOf(validator: Validator, oneOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let oneOf = oneOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if oneOf.filter({ validator.descend(instance: instance, subschema: $0).isValid }).count != 1 {
    return AnySequence(["Only one value from `oneOf` should be met"])
  }

  return AnySequence(EmptyCollection())
}

func not(validator: Validator, not: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard validator.descend(instance: instance, subschema: not).isValid else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(["'\(instance)' does not match 'not' validation."])
}

func `if`(validator: Validator, `if`: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  if validator.validate(instance: instance, schema: `if`).isValid {
    if let then = schema["then"] {
      return validator.descend(instance: instance, subschema: then)
    }
  } else if let `else` = schema["else"] {
    return validator.descend(instance: instance, subschema: `else`)
  }

  return AnySequence(EmptyCollection())
}

func allOf(validator: Validator, allOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let allOf = allOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(allOf.map({ validator.descend(instance: instance, subschema: $0) }).joined())
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

func `enum`(validator: Validator, enum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let `enum` = `enum` as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  let instance = instance as! NSObject
  if (`enum` as! [NSObject]).contains(where: { isEqual(instance, $0) }) {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(["'\(instance)' is not a valid enumeration value of '\(`enum`)'"])
}

func const(validator: Validator, const: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  if isEqual(instance as! NSObject, const as! NSObject) {
     return AnySequence(EmptyCollection())
  }

  return AnySequence(["'\(instance)' is not equal to const '\(const)'"])
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


func unsupported(_ keyword: String) -> (_ validator: Validator, _ value: Any, _ instance: Any, _ schema: [String: Any]) -> AnySequence<ValidationError> {
  return { (_, _, _, _) in
    return AnySequence(["'\(keyword)' is not supported."])
  }
}
