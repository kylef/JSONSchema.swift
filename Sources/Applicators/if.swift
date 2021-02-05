func `if`(context: Context, `if`: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  if context.validate(instance: instance, schema: `if`).isValid {
    if let then = schema["then"] {
      return context.descend(instance: instance, subschema: then)
    }
  } else if let `else` = schema["else"] {
    return context.descend(instance: instance, subschema: `else`)
  }

  return AnySequence(EmptyCollection())
}
