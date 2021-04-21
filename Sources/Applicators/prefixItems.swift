func prefixItems(context: Context, prefixItems: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard
    let instance = instance as? [Any],
    let prefixItems = prefixItems as? [Any]
  else {
    return AnySequence(EmptyCollection())
  }

  return try AnySequence(zip(prefixItems, instance).enumerated().map { index, zip throws -> AnySequence<ValidationError> in
    let subschema = zip.0
    let instance = zip.1

    context.instanceLocation.push(index.description)
    defer { context.instanceLocation.pop() }
    return try context.descend(instance: instance, subschema: subschema)
  }.joined())
}
