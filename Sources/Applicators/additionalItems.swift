func additionalItems(context: Context, additionalItems: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any], let items = schema["items"] as? [Any], instance.count > items.count else {
    return AnySequence(EmptyCollection())
  }

  if let additionalItems = additionalItems as? [String: Any] {
    return try AnySequence(Array(instance.enumerated())[items.count...].map { (index, subinstance) throws -> AnySequence<ValidationError> in
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      return try context.descend(instance: subinstance, subschema: additionalItems)
    }.joined())
  }

  if let additionalItems = additionalItems as? Bool, !additionalItems {
    return invalidValidation(context, "Additional results are not permitted in this array.")(instance)
  }

  return AnySequence(EmptyCollection())
}
