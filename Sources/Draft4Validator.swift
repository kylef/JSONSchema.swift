class Draft4Validator {
  let schema: [String: Any]

  typealias Validation = (Draft4Validator, Any, Any, Schema) -> (ValidationResult)
  let validations: [String: Validation] = [
    "type": type,
    "required": required,
    "propertyNames": propertyNames,
    "not": not,
    "pattern": pattern,
    "multipleOf": multipleOf,
    "contains": contains,
    "uniqueItems": uniqueItems,
    "enum": `enum`,
    "const": const,
    "format": format,
    "dependencies": dependencies,
    "allOf": allOf,
    "oneOf": oneOf,
    "anyOf": anyOf,
    "minLength": minLength,
    "maxLength": maxLength,
    "minimum": minimum,
    "maximum": maximum,
    "minItems": minItems,
    "maxItems": maxItems,
    "minProperties": minProperties,
    "maxProperties": maxProperties,
  ]

  let formats: [String: Validator] = [
    "ipv4": validateIPv4,
    "ipv6": validateIPv6,
    "uri": validateURI,
  ]

  required init(schema: Bool) {
    if schema {
      self.schema = [:]
    } else {
      self.schema = ["not": [:]]
    }
  }

  required init(schema: [String: Any]) {
    self.schema = schema
  }

  func validate(instance: Any) -> ValidationResult {
    return .valid
  }
}
