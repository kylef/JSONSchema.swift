func items(context: Context, items: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if let items = items as? [String: Any] {
    return AnySequence(instance.map { context.descend(instance: $0, subschema: items) }.joined())
  }

  if let items = items as? Bool {
    return AnySequence(instance.map { context.descend(instance: $0, subschema: items) }.joined())
  }

  if let items = items as? [Any] {
    var results = [AnySequence<ValidationError>]()

    for (index, item) in instance.enumerated() where index < items.count {
      results.append(context.descend(instance: item, subschema: items[index]))
    }

    return AnySequence(results.joined())
  }

  return AnySequence(EmptyCollection())
}
