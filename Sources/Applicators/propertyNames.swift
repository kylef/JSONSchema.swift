func propertyNames(context: Context, propertyNames: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return try AnySequence(instance.keys.map {
    try context.descend(instance: $0, subschema: propertyNames)
  }.joined())
}
