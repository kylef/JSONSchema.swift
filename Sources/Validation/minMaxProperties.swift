import Foundation


func validatePropertiesLength(_ context: Context, _ length: Int, comparitor: @escaping ((Int, Int) -> (Bool)), error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? [String: Any] {
      if !comparitor(length, value.count) {
        return AnySequence([
          ValidationError(
            error,
            instanceLocation: context.instanceLocation,
            keywordLocation: context.keywordLocation
          ),
        ])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minProperties(context: Context, minProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minProperties = minProperties as? Int else {
    return AnySequence(EmptyCollection())
  }
  
  let message = NSLocalizedString("Amount of properties is less than the required amount", comment: "")
  return validatePropertiesLength(context, minProperties, comparitor: <=, error: message)(instance)
}


func maxProperties(context: Context, maxProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxProperties = maxProperties as? Int else {
    return AnySequence(EmptyCollection())
  }

  let message = NSLocalizedString("Amount of properties is greater than maximum permitted", comment: "")
  return validatePropertiesLength(context, maxProperties, comparitor: >=, error: message)(instance)
}
