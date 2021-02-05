func propertyNames(context: Context, propertyNames: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(instance.keys.map { context.descend(instance: $0, subschema: propertyNames) }.joined())
}
