import Foundation

public class Draft4Validator: Validator {
  let schema: [String: Any]
  let resolver: RefResolver

  let metaschmas: [String : Any] = [
    "http://json-schema.org/draft-04/schema": DRAFT_04_META_SCHEMA,
  ]

  let validations: [String: Validation] = [
    "$ref": ref,
    "pattern": pattern,
    "multipleOf": multipleOf,
    "contains": contains,
    "uniqueItems": uniqueItems,
    "enum": `enum`,
    "const": const,
    "dependencies": dependencies,
    "minLength": minLength,
    "maxLength": maxLength,
    "minimum": minimumDraft4,
    "maximum": maximumDraft4,
    "minItems": minItems,
    "maxItems": maxItems,
    "minProperties": minProperties,
    "maxProperties": maxProperties,
    "items": items,
    "additionalItems": additionalItems,
    "patternProperties": patternProperties,
    "additionalProperties": additionalProperties,
    "not": not,
    "allOf": allOf,
    "oneOf": oneOf,
    "anyOf": anyOf,
    "type": type,
    "required": required,
    "propertyNames": propertyNames,
    "format": format,
    "properties": properties,
    "if": `if`,
  ]

  let formats: [String: (Context, String) -> (AnySequence<ValidationError>)] = [
    "ipv4": validateIPv4,
    "ipv6": validateIPv6,
    "uri": validateURI,
    "date-time": validateDateTime,
  ]

  public required init(schema: Bool) {
    if schema {
      self.schema = [:]
    } else {
      self.schema = ["not": [:]]
    }

    self.resolver = RefResolver(schema: self.schema, metaschemes: metaschmas, idField: "id", defsField: "definitions")
  }

  public required init(schema: [String: Any]) {
    self.schema = schema
    self.resolver = RefResolver(schema: schema, metaschemes: metaschmas, idField: "id", defsField: "definitions")
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
