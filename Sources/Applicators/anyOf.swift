func anyOf(context: Context, anyOf: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let anyOf = anyOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if !anyOf.contains(where: { context.descend(instance: instance, subschema: $0).isValid }) {
    return AnySequence([
      ValidationError(
        "\(instance) does not meet anyOf validation rules.",
        instanceLocation: context.instanceLocation
      ),
    ])
  }

  return AnySequence(EmptyCollection())
}
