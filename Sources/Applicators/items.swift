func items(context: Context, items: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  let instances: [(Int, Any)]
  if let prefixItems = schema["prefixItems"] as? [Any] {
    guard instance.count > prefixItems.count else {
      return AnySequence(EmptyCollection())
    }
    instances = Array(Array(instance.enumerated())[prefixItems.count...])
  } else {
    instances = Array(instance.enumerated())
  }

  if let items = items as? [String: Any] {
    return try AnySequence(instances.map { (index, instance) throws -> AnySequence<ValidationError> in
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      return try context.descend(instance: instance, subschema: items)
    }.joined())
  }

  if let items = items as? Bool {
    return try AnySequence(instances.map { (index, instance) throws -> AnySequence<ValidationError> in
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      return try context.descend(instance: instance, subschema: items)
    }.joined())
  }

  if let items = items as? [Any] {
    var results = [AnySequence<ValidationError>]()

    for (index, item) in instances where index < items.count {
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      results.append(try context.descend(instance: item, subschema: items[index]))
    }

    return AnySequence(results.joined())
  }

  return AnySequence(EmptyCollection())
}
