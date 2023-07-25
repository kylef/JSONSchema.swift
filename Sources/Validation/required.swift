func required(context: Context, required: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let required = required as? [String] else {
    return AnySequence(EmptyCollection())
  }


  return AnySequence(required.compactMap { key -> ValidationError? in
    guard !instance.keys.contains(key) else { return nil }
    context.instanceLocation.push(key)
    defer { context.instanceLocation.pop() }
    return ValidationError(
      "Required property '\(key)' is missing",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  })
}
