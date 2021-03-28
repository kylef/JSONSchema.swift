import Foundation


func patternProperties(context: Context, patternProperties: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let patternProperties = patternProperties as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  var results: [AnySequence<ValidationError>] = []

  for (pattern, schema) in patternProperties {
    do {
      let expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
      let keys = instance.keys.filter {
        (key: String) in expression.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.count)).count > 0
      }

      for key in keys {
        context.instanceLocation.push(key)
        defer { context.instanceLocation.pop() }
        results.append(try context.descend(instance: instance[key]!, subschema: schema))
      }
    } catch {
      return AnySequence([
        ValidationError(
          "[Schema] '\(pattern)' is not a valid regex pattern for patternProperties",
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        ),
      ])
    }
  }

  return AnySequence(results.joined())
}
