func not(context: Context, not: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard try context.descend(instance: instance, subschema: not).isValid else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence([
    ValidationError(
      "'\(instance)' does not match 'not' validation.",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}

