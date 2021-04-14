import Foundation


func findAdditionalProperties(instance: [String: Any], schema: [String: Any]) -> Set<String> {
  var keys: Set<String> = Set(instance.keys)

  if let properties = schema["properties"] as? [String: Any] {
    keys.subtract(properties.keys)
  }

  if let patternProperties = schema["patternProperties"] as? [String: Any] {
    let patterns = patternProperties.keys
      .compactMap { try? NSRegularExpression(pattern: $0, options: NSRegularExpression.Options(rawValue: 0)) }

    for pattern in patterns {
      for key in keys {
        if pattern.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.count)).count > 0 {
          keys.remove(key)
        }
      }
    }
  }

  return keys
}


func additionalProperties(context: Context, additionalProperties: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  let extras = findAdditionalProperties(instance: instance, schema: schema)

  if let additionalProperties = additionalProperties as? [String: Any] {
    return try AnySequence(extras.map {
      try context.descend(instance: instance[$0]!, subschema: additionalProperties)
    }.joined())
  }

  if let additionalProperties = additionalProperties as? Bool, !additionalProperties && !extras.isEmpty {
    return invalidValidation(context, "Additional properties are not permitted in this object.")(instance)
  }

  return AnySequence(EmptyCollection())
}


