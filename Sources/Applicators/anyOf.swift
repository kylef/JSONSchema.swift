func anyOf(context: Context, anyOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let anyOf = anyOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if !anyOf.contains(where: { context.descend(instance: instance, subschema: $0).isValid }) {
    return AnySequence(["\(instance) does not meet anyOf validation rules."])
  }

  return AnySequence(EmptyCollection())
}
