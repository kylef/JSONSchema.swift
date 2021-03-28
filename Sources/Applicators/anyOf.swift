func anyOf(context: Context, anyOf: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let anyOf = anyOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if try !anyOf.contains(where: { try context.descend(instance: instance, subschema: $0).isValid }) {
    return AnySequence([
      ValidationError(
        "\(instance) does not meet anyOf validation rules.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      ),
    ])
  }

  return AnySequence(EmptyCollection())
}
