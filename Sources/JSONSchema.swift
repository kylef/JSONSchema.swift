//
//  JSONSchema.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

public enum Type: Swift.String {
  case Object = "object"
  case Array = "array"
  case String = "string"
  case Integer = "integer"
  case Number = "number"
  case Boolean = "boolean"
  case Null = "null"
}

extension String {
  func stringByRemovingPrefix(_ prefix:String) -> String? {
    if hasPrefix(prefix) {
      let index = characters.index(startIndex, offsetBy: prefix.characters.count)
      return substring(from: index)
    }

    return nil
  }
}

public struct Schema {
  public let title:String?
  public let description:String?

  public let type:[Type]?

  /// validation formats, currently private. If anyone wants to add custom please make a PR to make this public ;)
  let formats:[String:Validator]

  let schema:[String:Any]

  public init(_ schema:[String:Any]) {
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

    formats = [
      "ipv4": validateIPv4,
      "ipv6": validateIPv6,
    ]
  }

  public func validate(_ data:Any) -> ValidationResult {
    let validator = allOf(validators(self)(schema))
    let result = validator(data)
    return result
  }

  func validatorForReference(_ reference:String) -> Validator {
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

        return allOf(JSONSchema.validators(self)(schema))
      } else if reference == "" {
        return { value in
          let validators = JSONSchema.validators(self)(self.schema)
          return allOf(validators)(value)
        }
      }
    }

    return invalidValidation("Remote $ref '\(reference)' is not yet supported")
  }
}

/// Returns a set of validators for a schema and document
func validators(_ root: Schema) -> (_ schema: [String:Any]) -> [Validator] {
  return { schema in
    var validators = [Validator]()

    if let ref = schema["$ref"] as? String {
      validators.append(root.validatorForReference(ref))
    }

    if let type = schema["type"] {
      // Rewrite this and most of the validator to use the `type` property, see https://github.com/kylef/JSONSchema.swift/issues/12
      validators.append(validateType(type))
    }

    if let allOf = schema["allOf"] as? [[String:Any]] {
      validators += allOf.map(JSONSchema.validators(root)).reduce([], +)
    }

    if let anyOfSchemas = schema["anyOf"] as? [[String:Any]] {
      let anyOfValidators = anyOfSchemas.map(JSONSchema.validators(root)).map(allOf) as [Validator]
      validators.append(anyOf(anyOfValidators))
    }

    if let oneOfSchemas = schema["oneOf"] as? [[String:Any]] {
      let oneOfValidators = oneOfSchemas.map(JSONSchema.validators(root)).map(allOf) as [Validator]
      validators.append(oneOf(oneOfValidators))
    }

    if let notSchema = schema["not"] as? [String:Any] {
      let notValidator = allOf(JSONSchema.validators(root)(notSchema))
      validators.append(not(notValidator))
    }

    if let enumValues = schema["enum"] as? [Any] {
      validators.append(validateEnum(enumValues))
    }

    // String

    if let maxLength = schema["maxLength"] as? Int {
      validators.append(validateLength(<=, length: maxLength, error: "Length of string is larger than max length \(maxLength)"))
    }

    if let minLength = schema["minLength"] as? Int {
      validators.append(validateLength(>=, length: minLength, error: "Length of string is smaller than minimum length \(minLength)"))
    }

    if let pattern = schema["pattern"] as? String {
      validators.append(validatePattern(pattern))
    }

    // Numerical

    if let multipleOf = schema["multipleOf"] as? Double {
      validators.append(validateMultipleOf(multipleOf))
    }

    if let minimum = schema["minimum"] as? Double {
      validators.append(validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: "Value is lower than minimum value of \(minimum)"))
    }

    if let maximum = schema["maximum"] as? Double {
      validators.append(validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: "Value exceeds maximum value of \(maximum)"))
    }

    // Array

    if let minItems = schema["minItems"] as? Int {
      validators.append(validateArrayLength(minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)"))
    }

    if let maxItems = schema["maxItems"] as? Int {
      validators.append(validateArrayLength(maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)"))
    }

    if let uniqueItems = schema["uniqueItems"] as? Bool {
      if uniqueItems {
        validators.append(validateUniqueItems)
      }
    }

    if let items = schema["items"] as? [String:Any] {
      let itemsValidators = allOf(JSONSchema.validators(root)(items))

      func validateItems(_ document:Any) -> ValidationResult {
        if let document = document as? [Any] {
          return flatten(document.map(itemsValidators))
        }

        return .valid
      }

      validators.append(validateItems)
    } else if let items = schema["items"] as? [[String:Any]] {
      func createAdditionalItemsValidator(_ additionalItems:Any?) -> Validator {
        if let additionalItems = additionalItems as? [String:Any] {
          return allOf(JSONSchema.validators(root)(additionalItems))
        }

        let additionalItems = additionalItems as? Bool ?? true
        if additionalItems {
          return validValidation
        }

        return invalidValidation("Additional results are not permitted in this array.")
      }

      let additionalItemsValidator = createAdditionalItemsValidator(schema["additionalItems"])
      let itemValidators = items.map(JSONSchema.validators(root))

      func validateItems(_ value:Any) -> ValidationResult {
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

    if let maxProperties = schema["maxProperties"] as? Int {
      validators.append(validatePropertiesLength(maxProperties, comparitor: >=, error: "Amount of properties is greater than maximum permitted"))
    }

    if let minProperties = schema["minProperties"] as? Int {
      validators.append(validatePropertiesLength(minProperties, comparitor: <=, error: "Amount of properties is less than the required amount"))
    }

    if let required = schema["required"] as? [String] {
      validators.append(validateRequired(required))
    }

    if (schema["properties"] != nil) || (schema["patternProperties"] != nil) || (schema["additionalProperties"] != nil) {
      func createAdditionalPropertiesValidator(_ additionalProperties:Any?) -> Validator {
        if let additionalProperties = additionalProperties as? [String:Any] {
          return allOf(JSONSchema.validators(root)(additionalProperties))
        }

        let additionalProperties = additionalProperties as? Bool ?? true
        if additionalProperties {
          return validValidation
        }

        return invalidValidation("Additional properties are not permitted in this object.")
      }

      func createPropertiesValidators(_ properties:[String:[String:Any]]?) -> [String:Validator]? {
        if let properties = properties {
          return Dictionary(properties.keys.map {
            key in (key, allOf(JSONSchema.validators(root)(properties[key]!)))
          })
        }

        return nil
      }

      let additionalPropertyValidator = createAdditionalPropertiesValidator(schema["additionalProperties"])
      let properties = createPropertiesValidators(schema["properties"] as? [String:[String:Any]])
      let patternProperties = createPropertiesValidators(schema["patternProperties"] as? [String:[String:Any]])
      validators.append(validateProperties(properties, patternProperties: patternProperties, additionalProperties: additionalPropertyValidator))
    }

    func validateDependency(_ key: String, validator: @escaping Validator) -> (_ value: Any) -> ValidationResult {
      return { value in
        if let value = value as? [String:Any] {
          if (value[key] != nil) {
            return validator(value)
          }
        }

        return .valid
      }
    }

    func validateDependencies(_ key: String, dependencies: [String]) -> (_ value: Any) -> ValidationResult {
      return { value in
        if let value = value as? [String:Any] {
          if (value[key] != nil) {
            return flatten(dependencies.map { dependency in
              if value[dependency] == nil {
                return .invalid(["'\(key)' is missing it's dependency of '\(dependency)'"])
              }
              return .valid
            })
          }
        }

        return .valid
      }
    }

    if let dependencies = schema["dependencies"] as? [String:Any] {
      for (key, dependencies) in dependencies {
        if let dependencies = dependencies as? [String: Any] {
          let schema = allOf(JSONSchema.validators(root)(dependencies))
          validators.append(validateDependency(key, validator: schema))
        } else if let dependencies = dependencies as? [String] {
          validators.append(validateDependencies(key, dependencies: dependencies))
        }
      }
    }

    if let format = schema["format"] as? String {
      if let validator = root.formats[format] {
        validators.append(validator)
      } else {
        validators.append(invalidValidation("'format' validation of '\(format)' is not yet supported."))
      }
    }

    return validators
  }
}

public func validate(_ value:Any, schema:[String:Any]) -> ValidationResult {
  let root = Schema(schema)
  let validator = allOf(validators(root)(schema))
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
