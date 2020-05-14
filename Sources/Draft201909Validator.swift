import Foundation

public class Draft201909Validator: Validator {
  let schema: [String: Any]
  static let metaSchema: [String: Any] = DRAFT_2019_09_META_SCHEMA
  let resolver: RefResolver

  typealias Validation = (Validator, Any, Any, [String: Any]) -> (ValidationResult)
  let validations: [String: Validation] = [
    "dependentRequired": dependentRequired,
    "pattern": pattern,
    "multipleOf": multipleOf,
    "contains": contains,
    "uniqueItems": uniqueItems,
    "enum": `enum`,
    "const": const,
    "dependencies": dependencies,
    "dependentSchemas": dependentSchemas,
    "minLength": minLength,
    "maxLength": maxLength,
    "minimum": minimum,
    "maximum": maximum,
    "exclusiveMinimum": exclusiveMinimum,
    "exclusiveMaximum": exclusiveMaximum,
    "minItems": minItems,
    "maxItems": maxItems,
    "minProperties": minProperties,
    "maxProperties": maxProperties,
    "items": items,
    "additionalItems": additionalItems,
    "patternProperties": patternProperties,
    "additionalProperties": additionalProperties,
  ]

  let sequenceValidations: [String: SequenceValidation] = [
    "$ref": ref,
    "not": not,
    "allOf": allOf,
    "oneOf": oneOf,
    "anyOf": anyOf,
    "type": type,
    "required": required,
    "propertyNames":  propertyNames,
    "properties": properties,
    "format": format,
    "if": `if`,
  ]

  let formats: [String: (String) -> (AnySequence<ValidationError>)] = [
    "ipv4": validateIPv4,
    "ipv6": validateIPv6,
    "uri": validateURI,
  ]

  public required init(schema: Bool) {
    if schema {
      self.schema = [:]
    } else {
      self.schema = ["not": [:]]
    }

    self.resolver = RefResolver(schema: self.schema)
  }

  public required init(schema: [String: Any]) {
    self.schema = schema
    self.resolver = RefResolver(schema: self.schema)
  }
}

let DRAFT_2019_09_META_SCHEMA: [String: Any] = {
  let string = """
  {
      "$schema": "https://json-schema.org/draft/2019-09/schema",
      "$id": "https://json-schema.org/draft/2019-09/schema",
      "$vocabulary": {
          "https://json-schema.org/draft/2019-09/vocab/core": true,
          "https://json-schema.org/draft/2019-09/vocab/applicator": true,
          "https://json-schema.org/draft/2019-09/vocab/validation": true,
          "https://json-schema.org/draft/2019-09/vocab/meta-data": true,
          "https://json-schema.org/draft/2019-09/vocab/format": false,
          "https://json-schema.org/draft/2019-09/vocab/content": true
      },
      "$recursiveAnchor": true,

      "title": "Core and Validation specifications meta-schema",
      "allOf": [
          {"$ref": "meta/core"},
          {"$ref": "meta/applicator"},
          {"$ref": "meta/validation"},
          {"$ref": "meta/meta-data"},
          {"$ref": "meta/format"},
          {"$ref": "meta/content"}
      ],
      "type": ["object", "boolean"],
      "properties": {
          "definitions": {
              "$comment": "While no longer an official keyword as it is replaced by $defs, this keyword is retained in the meta-schema to prevent incompatible extensions as it remains in common use.",
              "type": "object",
              "additionalProperties": { "$recursiveRef": "#" },
              "default": {}
          },
          "dependencies": {
              "$comment": "\\"dependencies\\" is no longer a keyword, but schema authors should avoid redefining it to facilitate a smooth transition to \\"dependentSchemas\\" and \\"dependentRequired\\"",
              "type": "object",
              "additionalProperties": {
                  "anyOf": [
                      { "$recursiveRef": "#" },
                      { "$ref": "meta/validation#/$defs/stringArray" }
                  ]
              }
          }
      }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()
