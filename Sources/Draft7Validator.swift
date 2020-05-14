import Foundation

public class Draft7Validator: Validator {
  let schema: [String: Any]
  static let metaSchema: [String: Any] = DRAFT_07_META_SCHEMA
  let resolver: RefResolver

  typealias Validation = (Validator, Any, Any, [String: Any]) -> (ValidationResult)
  let validations: [String: Validation] = [
    "$ref": createSequence(validation: ref),
    "type": createSequence(validation: type),
    "required": createSequence(validation: required),
    "propertyNames": propertyNames,
    "not": not,
    "pattern": pattern,
    "multipleOf": multipleOf,
    "contains": contains,
    "uniqueItems": uniqueItems,
    "enum": `enum`,
    "const": const,
    "format": createSequence(validation: format),
    "dependencies": dependencies,
    "allOf": allOf,
    "oneOf": oneOf,
    "anyOf": anyOf,
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
    "properties": createSequence(validation: properties),
    "patternProperties": patternProperties,
    "additionalProperties": additionalProperties,
    "if": createSequence(validation: `if`),
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

let DRAFT_07_META_SCHEMA: [String: Any] = {
  let string = """
  {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "$id": "http://json-schema.org/draft-07/schema#",
      "title": "Core schema meta-schema",
      "definitions": {
          "schemaArray": {
              "type": "array",
              "minItems": 1,
              "items": { "$ref": "#" }
          },
          "nonNegativeInteger": {
              "type": "integer",
              "minimum": 0
          },
          "nonNegativeIntegerDefault0": {
              "allOf": [
                  { "$ref": "#/definitions/nonNegativeInteger" },
                  { "default": 0 }
              ]
          },
          "simpleTypes": {
              "enum": [
                  "array",
                  "boolean",
                  "integer",
                  "null",
                  "number",
                  "object",
                  "string"
              ]
          },
          "stringArray": {
              "type": "array",
              "items": { "type": "string" },
              "uniqueItems": true,
              "default": []
          }
      },
      "type": ["object", "boolean"],
      "properties": {
          "$id": {
              "type": "string",
              "format": "uri-reference"
          },
          "$schema": {
              "type": "string",
              "format": "uri"
          },
          "$ref": {
              "type": "string",
              "format": "uri-reference"
          },
          "$comment": {
              "type": "string"
          },
          "title": {
              "type": "string"
          },
          "description": {
              "type": "string"
          },
          "default": true,
          "readOnly": {
              "type": "boolean",
              "default": false
          },
          "examples": {
              "type": "array",
              "items": true
          },
          "multipleOf": {
              "type": "number",
              "exclusiveMinimum": 0
          },
          "maximum": {
              "type": "number"
          },
          "exclusiveMaximum": {
              "type": "number"
          },
          "minimum": {
              "type": "number"
          },
          "exclusiveMinimum": {
              "type": "number"
          },
          "maxLength": { "$ref": "#/definitions/nonNegativeInteger" },
          "minLength": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
          "pattern": {
              "type": "string",
              "format": "regex"
          },
          "additionalItems": { "$ref": "#" },
          "items": {
              "anyOf": [
                  { "$ref": "#" },
                  { "$ref": "#/definitions/schemaArray" }
              ],
              "default": true
          },
          "maxItems": { "$ref": "#/definitions/nonNegativeInteger" },
          "minItems": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
          "uniqueItems": {
              "type": "boolean",
              "default": false
          },
          "contains": { "$ref": "#" },
          "maxProperties": { "$ref": "#/definitions/nonNegativeInteger" },
          "minProperties": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
          "required": { "$ref": "#/definitions/stringArray" },
          "additionalProperties": { "$ref": "#" },
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
              "propertyNames": { "format": "regex" },
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
          "propertyNames": { "$ref": "#" },
          "const": true,
          "enum": {
              "type": "array",
              "items": true,
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
          "contentMediaType": { "type": "string" },
          "contentEncoding": { "type": "string" },
          "if": { "$ref": "#" },
          "then": { "$ref": "#" },
          "else": { "$ref": "#" },
          "allOf": { "$ref": "#/definitions/schemaArray" },
          "anyOf": { "$ref": "#/definitions/schemaArray" },
          "oneOf": { "$ref": "#/definitions/schemaArray" },
          "not": { "$ref": "#" }
      },
      "default": true
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()
