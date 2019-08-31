import Foundation


public enum Type: Swift.String {
  case object = "object"
  case array = "array"
  case string = "string"
  case integer = "integer"
  case jumber = "number"
  case boolean = "boolean"
  case null = "null"
}


extension String {
  func stringByRemovingPrefix(_ prefix: String) -> String? {
    if hasPrefix(prefix) {
      let index = self.index(startIndex, offsetBy: prefix.count)
      return String(self[index...])
    }

    return nil
  }
}


public struct Schema {
  public let title: String?
  public let description: String?

  public let type: [Type]?

  let schema: [String: Any]

  public init(_ schema: [String: Any]) {
    title = schema["title"] as? String
    description = schema["description"] as? String

    if let type = schema["type"] as? String {
      if let type = Type(rawValue: type) {
        self.type = [type]
      } else {
        self.type = []
      }
    } else if let types = schema["type"] as? [String] {
      self.type = types.map { Type(rawValue: $0) }.filter { $0 != nil }.map { $0! }
    } else {
      self.type = []
    }

    self.schema = schema
  }

  public func validate(_ data: Any) -> ValidationResult {
    let validator = allOf(validators(self.schema)(schema))
    let result = validator(data)
    return result
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

        return allOf(JSONSchema.validators(self.schema)(schema))
      } else if reference == "" {
        return { value in
          let validators = JSONSchema.validators(self.schema)(self.schema)
          return allOf(validators)(value)
        }
      }
    }

    return invalidValidation("Remote $ref '\(reference)' is not yet supported")
  }
}


func validators(_ root: [String: Any]) -> (_ schema: Any) -> [Validator] {
  return { schema in
    if let schema = schema as? Bool {
      return JSONSchema.validatorsBool(root)(schema)
    }

    if let schema = schema as? [String: Any] {
      return JSONSchema.validatorsDict(root)(schema)
    }

    return []
  }
}


func validatorsBool(_ root: [String: Any]) -> (_ schema: Bool) -> [Validator] {
  return { schema in
    if schema {
       return JSONSchema.validators(root)([:])
    } else {
       return JSONSchema.validators(root)(["not": [:]])
    }
  }
}


func validatorCurry(_ validator: @escaping (Draft4Validator, Any, Any, [String: Any]) -> ValidationResult) -> ((_ validator: Draft4Validator, _ value: Any, _ schema: [String: Any]) -> ((_ instance: Any) -> ValidationResult)) {
  return { (v, value, schema) in
    return { instance in
      return validator(v, value, instance, schema)
    }
  }
}


/// Returns a set of validators for a schema and document
func validatorsDict(_ root: [String: Any]) -> (_ schema: [String: Any]) -> [Validator] {
  return { schema in
    var validators = [Validator]()
    let root = Schema(root)

    if let ref = schema["$ref"] as? String {
      validators.append(root.validatorForReference(ref))
    }

    let draftValidator = Draft4Validator(schema: root.schema)

    for (key, v) in draftValidator.validations {
      if let value = schema[key] {
        validators.append(validatorCurry(v)(draftValidator, value, root.schema))
      }
    }

    // Array

    if let items = schema["items"] as? [String: Any] {
      let itemsValidators = allOf(JSONSchema.validators(root.schema)(items))

      func validateItems(_ document:Any) -> ValidationResult {
        if let document = document as? [Any] {
          return flatten(document.map(itemsValidators))
        }

        return .valid
      }

      validators.append(validateItems)
    } else if let items = schema["items"] as? Bool {
      let itemsValidators = allOf(JSONSchema.validators(root.schema)(items))

      func validateItems(_ document:Any) -> ValidationResult {
        if let document = document as? [Any] {
          return flatten(document.map(itemsValidators))
        }

        return .valid
      }

      validators.append(validateItems)
    } else if let items = schema["items"] as? [Any] {
      func createAdditionalItemsValidator(_ additionalItems: Any?) -> Validator {
        if let additionalItems = additionalItems {
          return allOf(JSONSchema.validators(root.schema)(additionalItems))
        }

        let additionalItems = additionalItems as? Bool ?? true
        if additionalItems {
          return validValidation
        }

        return invalidValidation("Additional results are not permitted in this array.")
      }

      let additionalItemsValidator = createAdditionalItemsValidator(schema["additionalItems"])
      let itemValidators = items.map(JSONSchema.validators(root.schema))

      func validateItems(_ value: Any) -> ValidationResult {
        if let value = value as? [Any] {
          var results = [ValidationResult]()

          for (index, element) in value.enumerated() {
            if index >= itemValidators.count {
              results.append(additionalItemsValidator(element))
            } else {
              let validators = allOf(itemValidators[index])
              results.append(validators(element))
            }
          }

          return flatten(results)
        }

        return .valid
      }

      validators.append(validateItems)
    }

    if (schema["properties"] != nil) || (schema["patternProperties"] != nil) || (schema["additionalProperties"] != nil) {
      func createAdditionalPropertiesValidator(_ additionalProperties: Any?) -> Validator {
        if let additionalProperties = additionalProperties {
          return allOf(JSONSchema.validators(root.schema)(additionalProperties))
        }

        let additionalProperties = additionalProperties as? Bool ?? true
        if additionalProperties {
          return validValidation
        }

        return invalidValidation("Additional properties are not permitted in this object.")
      }

      func createPropertiesValidators(_ properties: [String: Any]?) -> [String: Validator]? {
        if let properties = properties {
          return Dictionary(properties.keys.map {
            key in (key, allOf(JSONSchema.validators(root.schema)(properties[key]!)))
          })
        }

        return nil
      }

      let additionalPropertyValidator = createAdditionalPropertiesValidator(schema["additionalProperties"])
      let properties = createPropertiesValidators(schema["properties"] as? [String: Any])
      let patternProperties = createPropertiesValidators(schema["patternProperties"] as? [String: Any])
      validators.append(validateProperties(properties, patternProperties: patternProperties, additionalProperties: additionalPropertyValidator))
    }

    return validators
  }
}


public func validate(_ value: Any, schema: [String: Any]) -> ValidationResult {
  let root = Schema(schema)
  let validator = allOf(validators(root.schema)(schema))
  let result = validator(value)
  return result
}


public func validate(_ value: Any, schema: Bool) -> ValidationResult {
  let root = Schema([:])
  let validator = allOf(validators(root.schema)(schema))
  let result = validator(value)
  return result
}


/// Extension for dictionary providing initialization from array of elements
extension Dictionary {
  init(_ pairs: [Element]) {
    self.init()

    for (key, value) in pairs {
      self[key] = value
    }
  }
}
