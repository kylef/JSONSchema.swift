import Foundation

class Draft4Validator {
  let schema: [String: Any]

  let metaSchema: [String: Any] = DRAFT_04_META_SCHEMA

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

  let formats: [String: (String) -> (ValidationResult)] = [
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

    if let ref = schema["$ref"] as? String {
      let validation = validations["$ref"]!
      return validation(self, ref, instance, schema)
    }

    var results = [ValidationResult]()
    for (key, validation) in validations {
      if let value = schema[key] {
        results.append(validation(self, value, instance, schema))
      }
    }

    return flatten(results)
  }

  func resolve(ref: String) -> Validator {
    return validatorForReference(ref)
  }

  func validatorForReference(_ reference: String) -> Validator {
    // TODO: Rewrite this whole block: https://github.com/kylef/JSONSchema.swift/issues/12

    if reference == "http://json-schema.org/draft-04/schema#" {
      return { Draft4Validator(schema: self.metaSchema).descend(instance: $0, subschema: self.metaSchema) }
    }

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

let DRAFT_04_META_SCHEMA: [String: Any] = {
  let string = """
  {
      "id": "http://json-schema.org/draft-04/schema#",
      "$schema": "http://json-schema.org/draft-04/schema#",
      "description": "Core schema meta-schema",
      "definitions": {
          "schemaArray": {
              "type": "array",
              "minItems": 1,
              "items": { "$ref": "#" }
          },
          "positiveInteger": {
              "type": "integer",
              "minimum": 0
          },
          "positiveIntegerDefault0": {
              "allOf": [ { "$ref": "#/definitions/positiveInteger" }, { "default": 0 } ]
          },
          "simpleTypes": {
              "enum": [ "array", "boolean", "integer", "null", "number", "object", "string" ]
          },
          "stringArray": {
              "type": "array",
              "items": { "type": "string" },
              "minItems": 1,
              "uniqueItems": true
          }
      },
      "type": "object",
      "properties": {
          "id": {
              "type": "string"
          },
          "$schema": {
              "type": "string"
          },
          "title": {
              "type": "string"
          },
          "description": {
              "type": "string"
          },
          "default": {},
          "multipleOf": {
              "type": "number",
              "minimum": 0,
              "exclusiveMinimum": true
          },
          "maximum": {
              "type": "number"
          },
          "exclusiveMaximum": {
              "type": "boolean",
              "default": false
          },
          "minimum": {
              "type": "number"
          },
          "exclusiveMinimum": {
              "type": "boolean",
              "default": false
          },
          "maxLength": { "$ref": "#/definitions/positiveInteger" },
          "minLength": { "$ref": "#/definitions/positiveIntegerDefault0" },
          "pattern": {
              "type": "string",
              "format": "regex"
          },
          "additionalItems": {
              "anyOf": [
                  { "type": "boolean" },
                  { "$ref": "#" }
              ],
              "default": {}
          },
          "items": {
              "anyOf": [
                  { "$ref": "#" },
                  { "$ref": "#/definitions/schemaArray" }
              ],
              "default": {}
          },
          "maxItems": { "$ref": "#/definitions/positiveInteger" },
          "minItems": { "$ref": "#/definitions/positiveIntegerDefault0" },
          "uniqueItems": {
              "type": "boolean",
              "default": false
          },
          "maxProperties": { "$ref": "#/definitions/positiveInteger" },
          "minProperties": { "$ref": "#/definitions/positiveIntegerDefault0" },
          "required": { "$ref": "#/definitions/stringArray" },
          "additionalProperties": {
              "anyOf": [
                  { "type": "boolean" },
                  { "$ref": "#" }
              ],
              "default": {}
          },
          "definitions": {
              "type": "object",
              "additionalProperties": { "$ref": "#" },
              "default": {}
          },
          "properties": {
              "type": "object",
              "additionalProperties": { "$ref": "#" },
              "default": {}
          },
          "patternProperties": {
              "type": "object",
              "additionalProperties": { "$ref": "#" },
              "default": {}
          },
          "dependencies": {
              "type": "object",
              "additionalProperties": {
                  "anyOf": [
                      { "$ref": "#" },
                      { "$ref": "#/definitions/stringArray" }
                  ]
              }
          },
          "enum": {
              "type": "array",
              "minItems": 1,
              "uniqueItems": true
          },
          "type": {
              "anyOf": [
                  { "$ref": "#/definitions/simpleTypes" },
                  {
                      "type": "array",
                      "items": { "$ref": "#/definitions/simpleTypes" },
                      "minItems": 1,
                      "uniqueItems": true
                  }
              ]
          },
          "format": { "type": "string" },
          "allOf": { "$ref": "#/definitions/schemaArray" },
          "anyOf": { "$ref": "#/definitions/schemaArray" },
          "oneOf": { "$ref": "#/definitions/schemaArray" },
          "not": { "$ref": "#" }
      },
      "dependencies": {
          "exclusiveMaximum": [ "maximum" ],
          "exclusiveMinimum": [ "minimum" ]
      },
      "default": {}
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()
