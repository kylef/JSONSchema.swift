func dependencies(context: Context, dependencies: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let dependencies = dependencies as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  var results: [AnySequence<ValidationError>] = []

  for (property, dependency) in dependencies where instance.keys.contains(property) {
    if let dependency = dependency as? [String] {
      for key in dependency {
        if !instance.keys.contains(key) {
          results.append(AnySequence([
            ValidationError(
              "'\(key)' is a dependency for '\(property)'",
              instanceLocation: context.instanceLocation,
              keywordLocation: context.keywordLocation
            ),
          ]))
        }
      }
    } else {
      results.append(try context.descend(instance: instance, subschema: dependency))
    }
  }

  return AnySequence(results.joined())
}
