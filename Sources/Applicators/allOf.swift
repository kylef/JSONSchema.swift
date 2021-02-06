func allOf(context: Context, allOf: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let allOf = allOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  return try AnySequence(allOf.map({
    try context.descend(instance: instance, subschema: $0)
  }).joined())
}
