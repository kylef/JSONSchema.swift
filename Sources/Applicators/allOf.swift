func allOf(context: Context, allOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let allOf = allOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(allOf.map({ context.descend(instance: instance, subschema: $0) }).joined())
}
