func dependentSchemas(context: Context, dependentRequired: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let dependentRequired = dependentRequired as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return try AnySequence(dependentRequired.compactMap({ (key, subschema) throws -> AnySequence<ValidationError> in
    if instance.keys.contains(key) {
      return try context.descend(instance: instance, subschema: subschema)
    }

    return AnySequence(EmptyCollection())
  }).joined())
}
