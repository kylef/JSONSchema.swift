func not(context: Context, not: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard context.descend(instance: instance, subschema: not).isValid else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(["'\(instance)' does not match 'not' validation."])
}

