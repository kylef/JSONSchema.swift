func dependentSchemas(context: Context, dependentRequired: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let dependentRequired = dependentRequired as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(dependentRequired.compactMap({ (key, subschema) -> AnySequence<ValidationError> in
    if instance.keys.contains(key) {
      return context.descend(instance: instance, subschema: subschema)
    }

    return AnySequence(EmptyCollection())
  }).joined())
}
