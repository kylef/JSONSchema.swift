func `if`(context: Context, `if`: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  if try context.validate(instance: instance, schema: `if`).isValid {
    if let then = schema["then"] {
      return try context.descend(instance: instance, subschema: then)
    }
  } else if let `else` = schema["else"] {
    return try context.descend(instance: instance, subschema: `else`)
  }

  return AnySequence(EmptyCollection())
}
