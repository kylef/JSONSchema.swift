func validateArrayLength(_ context: Context, _ rhs: Int, comparitor: @escaping ((Int, Int) -> Bool), error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? [Any] {
      if !comparitor(value.count, rhs) {
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


func minItems(context: Context, minItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minItems = minItems as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateArrayLength(context, minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)")(instance)
}


func maxItems(context: Context, maxItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxItems = maxItems as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateArrayLength(context, maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)")(instance)
}
