func items(context: Context, items: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if let items = items as? [String: Any] {
    return AnySequence(Array(instance.enumerated()).map { (index, instance) -> AnySequence<ValidationError> in
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      return context.descend(instance: instance, subschema: items)
    }.joined())
  }

  if let items = items as? Bool {
    return AnySequence(Array(instance.enumerated()).map { (index, instance) -> AnySequence<ValidationError> in
      context.instanceLocation.push(index.description)
      defer { context.instanceLocation.pop() }
      return context.descend(instance: instance, subschema: items)
    }.joined())
  }

  if let items = items as? [Any] {
    var results = [AnySequence<ValidationError>]()

    for (index, item) in instance.enumerated() where index < items.count {
      context.instanceLocation.push(index.description)
      results.append(context.descend(instance: item, subschema: items[index]))
      context.instanceLocation.pop()
    }

    return AnySequence(results.joined())
  }

  return AnySequence(EmptyCollection())
}
