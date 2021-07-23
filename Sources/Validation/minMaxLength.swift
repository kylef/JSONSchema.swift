import Foundation


func validateLength(_ context: Context, _ comparitor: @escaping ((Int, Int) -> (Bool)), length: Int, error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? String {
      if !comparitor(value.count, length) {
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


func minLength(context: Context, minLength: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minLength = minLength as? Int else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Length of string is smaller than minimum length %@", comment: ""), "\(minLength)")
  return validateLength(context, >=, length: minLength, error: message)(instance)
}


func maxLength(context: Context, maxLength: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxLength = maxLength as? Int else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("Length of string is larger than max length %@", comment: ""), "\(maxLength)")
  return validateLength(context, <=, length: maxLength, error: message)(instance)
}
