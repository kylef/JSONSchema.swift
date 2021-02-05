import Foundation


func validatePropertiesLength(_ length: Int, comparitor: @escaping ((Int, Int) -> (Bool)), error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? [String: Any] {
      if !comparitor(length, value.count) {
        return AnySequence([ValidationError(error)])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minProperties(validator: Validator, minProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minProperties = minProperties as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validatePropertiesLength(minProperties, comparitor: <=, error: "Amount of properties is less than the required amount")(instance)
}


func maxProperties(validator: Validator, maxProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxProperties = maxProperties as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validatePropertiesLength(maxProperties, comparitor: >=, error: "Amount of properties is greater than maximum permitted")(instance)
}


func required(validator: Validator, required: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let required = required as? [String] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(required.compactMap { key -> ValidationError? in
    guard !instance.keys.contains(key) else { return nil }
    return "Required property '\(key)' is missing"
  })
}


func dependentRequired(validator: Validator, dependentRequired: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let dependentRequired = dependentRequired as? [String: [String]] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(dependentRequired.compactMap({ (key, required) -> AnySequence<ValidationError> in
    if instance.keys.contains(key) {
      return JSONSchema.required(validator: validator, required: required, instance: instance, schema: schema)
    }

    return AnySequence(EmptyCollection())
  }).joined())
}


func dependentSchemas(validator: Validator, dependentRequired: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let dependentRequired = dependentRequired as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(dependentRequired.compactMap({ (key, subschema) -> AnySequence<ValidationError> in
    if instance.keys.contains(key) {
      return validator.descend(instance: instance, subschema: subschema)
    }

    return AnySequence(EmptyCollection())
  }).joined())
}


func propertyNames(validator: Validator, propertyNames: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(instance.keys.map { validator.descend(instance: $0, subschema: propertyNames) }.joined())
}


func properties(validator: Validator, properties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let properties = properties as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(instance.map { (key, value) -> AnySequence<ValidationError> in
    if let schema = properties[key] {
      return validator.descend(instance: value, subschema: schema)
    }

    return AnySequence(EmptyCollection())
  }.joined())
}


func patternProperties(validator: Validator, patternProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
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
        results.append(validator.descend(instance: instance[key]!, subschema: schema))
      }
    } catch {
      return AnySequence(["[Schema] '\(pattern)' is not a valid regex pattern for patternProperties"])
    }
  }

  return AnySequence(results.joined())
}


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


func additionalProperties(validator: Validator, additionalProperties: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  let extras = findAdditionalProperties(instance: instance, schema: schema)

  if let additionalProperties = additionalProperties as? [String: Any] {
    return AnySequence(extras.map { validator.descend(instance: instance[$0]!, subschema: additionalProperties) }.joined())
  }

  if let additionalProperties = additionalProperties as? Bool, !additionalProperties && !extras.isEmpty {
    return invalidValidation("Additional properties are not permitted in this object.")(instance)
  }

  return AnySequence(EmptyCollection())
}


func dependencies(validator: Validator, dependencies: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
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
          results.append(AnySequence(["'\(key)' is a dependency for '\(property)'"]))
        }
      }
    } else {
      results.append(validator.descend(instance: instance, subschema: dependency))
    }
  }

  return AnySequence(results.joined())
}
