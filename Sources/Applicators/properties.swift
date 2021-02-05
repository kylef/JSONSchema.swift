func properties(context: Context, properties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let properties = properties as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(instance.map { (key, value) -> AnySequence<ValidationError> in
    if let schema = properties[key] {
      return context.descend(instance: value, subschema: schema)
    }

    return AnySequence(EmptyCollection())
  }.joined())
}
