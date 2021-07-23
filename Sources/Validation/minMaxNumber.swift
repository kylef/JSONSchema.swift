import Foundation


func validateNumericLength(_ context: Context, _ length: Double, comparitor: @escaping ((Double, Double) -> (Bool)), exclusiveComparitor: @escaping ((Double, Double) -> (Bool)), exclusive: Bool?, error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? Double {
      if exclusive ?? false {
        if !exclusiveComparitor(value, length) {
          return AnySequence([
            ValidationError(
              error,
              instanceLocation: context.instanceLocation,
              keywordLocation: context.keywordLocation
            )
          ])
        }
      }

      if !comparitor(value, length) {
        return AnySequence([
          ValidationError(
            error,
            instanceLocation: context.instanceLocation,
            keywordLocation: context.keywordLocation
          )
        ])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minimumDraft4(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value is lower than minimum value of %@", comment: ""), "\(minimum)")
  return validateNumericLength(context, minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: message)(instance)
}


func maximumDraft4(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value exceeds maximum value of %@", comment: ""), "\(maximum)")
  return validateNumericLength(context, maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: message)(instance)
}


func minimum(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value is lower than minimum value of %@", comment: ""), "\(minimum)")
  return validateNumericLength(context, minimum, comparitor: >=, exclusiveComparitor: >, exclusive: false, error: message)(instance)
}


func maximum(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value exceeds maximum value of %@", comment: ""), "\(maximum)")
  return validateNumericLength(context, maximum, comparitor: <=, exclusiveComparitor: <, exclusive: false, error: message)(instance)
}


func exclusiveMinimum(context: Context, minimum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minimum = minimum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value is lower than exclusive minimum value of %@", comment: ""), "\(minimum)")
  return validateNumericLength(context, minimum, comparitor: >=, exclusiveComparitor: >, exclusive: true, error: message)(instance)
}


func exclusiveMaximum(context: Context, maximum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maximum = maximum as? Double else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Value exceeds exclusive maximum value of %@", comment: ""), "\(maximum)")
  return validateNumericLength(context, maximum, comparitor: <=, exclusiveComparitor: <, exclusive: true, error: message)(instance)
}
