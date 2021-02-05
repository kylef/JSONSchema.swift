import Foundation


func multipleOf(context: Context, multipleOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let multipleOf = multipleOf as? Double else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? Double, instance > 0.0 else {
    return AnySequence(EmptyCollection())
  }

  let result = instance / multipleOf
  if result != floor(result) {
    return AnySequence(["\(instance) is not a multiple of \(multipleOf)"])
  }

  return AnySequence(EmptyCollection())
}


func validateNumericLength(_ length: Double, comparitor: @escaping ((Double, Double) -> (Bool)), exclusiveComparitor: @escaping ((Double, Double) -> (Bool)), exclusive: Bool?, error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? Double {
      if exclusive ?? false {
        if !exclusiveComparitor(value, length) {
          return AnySequence([ValidationError(error)])
        }
      }

      if !comparitor(value, length) {
        return AnySequence([ValidationError(error)])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minimumDraft4(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: "Value is lower than minimum value of \(minimum)")(instance)
}


func maximumDraft4(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: "Value exceeds maximum value of \(maximum)")(instance)
}


func minimum(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: false, error: "Value is lower than minimum value of \(minimum)")(instance)
}


func maximum(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: false, error: "Value exceeds maximum value of \(maximum)")(instance)
}


func exclusiveMinimum(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: true, error: "Value is lower than exclusive minimum value of \(minimum)")(instance)
}


func exclusiveMaximum(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: true, error: "Value exceeds exclusive maximum value of \(maximum)")(instance)
}
