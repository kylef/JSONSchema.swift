func additionalItems(context: Context, additionalItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any], let items = schema["items"] as? [Any], instance.count > items.count else {
    return AnySequence(EmptyCollection())
  }

  if let additionalItems = additionalItems as? [String: Any] {
    return AnySequence(instance[items.count...].map { context.descend(instance: $0, subschema: additionalItems) }.joined())
  }

  if let additionalItems = additionalItems as? Bool, !additionalItems {
    return invalidValidation("Additional results are not permitted in this array.")(instance)
  }

  return AnySequence(EmptyCollection())
}
