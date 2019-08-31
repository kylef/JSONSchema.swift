import Foundation

class Draft4Validator {
  let schema: [String: Any]

  typealias Validation = (Draft4Validator, Any, Any, [String: Any]) -> (ValidationResult)
  let validations: [String: Validation] = [
    "$ref": ref,
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
    "items": items,
    "additionalItems": additionalItems,
    "properties": properties,
    "patternProperties": patternProperties,
    "additionalProperties": additionalProperties,
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
    return validate(instance: instance, schema: schema)
  }

  func validate(instance: Any, schema: Any) -> ValidationResult {
    if let schema = schema as? Bool {
      if schema == true {
        return .valid
      }

      return .invalid(["Falsy schema"])
    }

    guard let schema = schema as? [String: Any] else {
      return .valid
    }

    var validators = [Validator]()

    if let ref = schema["$ref"] as? String {
      let validation = validations["$ref"]!
      validators.append(validatorCurry(validation)(self, ref, schema))
    } else {
      for (key, validation) in validations {
        if let value = schema[key] {
          validators.append(validatorCurry(validation)(self, value, schema))
        }
      }
    }

    return flatten(validators.map { $0(instance) })
  }

  func resolve(ref: String) -> Validator {
    return validatorForReference(ref)
  }

  func validatorForReference(_ reference: String) -> Validator {
    // TODO: Rewrite this whole block: https://github.com/kylef/JSONSchema.swift/issues/12

    if let reference = reference.stringByRemovingPrefix("#") {  // Document relative
      if let tmp = reference.stringByRemovingPrefix("/"), let reference = (tmp as NSString).removingPercentEncoding {
        var components = reference.components(separatedBy: "/")
        var schema = self.schema
        while let component = components.first {
          components.remove(at: components.startIndex)

          if let subschema = schema[component] as? [String:Any] {
            schema = subschema
            continue
          } else if let schemas = schema[component] as? [[String:Any]] {
            if let component = components.first, let index = Int(component) {
              components.remove(at: components.startIndex)

              if schemas.count > index {
                schema = schemas[index]
                continue
              }
            }
          }

          return invalidValidation("Reference not found '\(component)' in '\(reference)'")
        }

        return { self.descend(instance: $0, subschema: schema) }
      } else if reference == "" {
        return { self.descend(instance: $0, subschema: self.schema) }
      }
    }

    return invalidValidation("Remote $ref '\(reference)' is not yet supported")
  }

  func descend(instance: Any, subschema: Any) -> ValidationResult {
    return validate(instance: instance, schema: subschema)
  }
}
