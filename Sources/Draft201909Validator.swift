import Foundation

public class Draft201909Validator: Validator {
  let schema: [String: Any]
  let resolver: RefResolver

  let metaschmas: [String : Any] = [
    "https://json-schema.org/draft/2019-09/schema": DRAFT_2019_09_META_SCHEMA,
    "https://json-schema.org/draft/2019-09/meta/core": DRAFT_2019_09_META_SCHEMA_CORE,
    "https://json-schema.org/draft/2019-09/meta/applicator": DRAFT_2019_09_META_SCHEMA_APPLICATOR,
    "https://json-schema.org/draft/2019-09/meta/validation": DRAFT_2019_09_META_SCHEMA_VALIDATION,
    "https://json-schema.org/draft/2019-09/meta/meta-data": DRAFT_2019_09_META_SCHEMA_METADATA,
    "https://json-schema.org/draft/2019-09/meta/format": DRAFT_2019_09_META_SCHEMA_FORMAT,
    "https://json-schema.org/draft/2019-09/meta/content": DRAFT_2019_09_META_SCHEMA_CONTENT,
  ]

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

    "unevaluatedItems": unsupported("unevaluatedItems"),
    "unevaluatedProperties": unsupported("unevaluatedProperties"),
  ]

  let formats: [String: (Context, String) -> (AnySequence<ValidationError>)] = [
    "ipv4": validateIPv4,
    "ipv6": validateIPv6,
    "uri": validateURI,
    "uuid": validateUUID,
    "regex": validateRegex,
    "json-pointer": validateJSONPointer,
    "duration": validateDuration,
    "time": validateTime,
    "date": validateDate,
    "date-time": validateDateTime,
  ]

  public required init(schema: Bool) {
    if schema {
      self.schema = [:]
    } else {
      self.schema = ["not": [:]]
    }

    self.resolver = RefResolver(schema: self.schema, metaschemes: metaschmas)
  }

  public required init(schema: [String: Any]) {
    self.schema = schema
    self.resolver = RefResolver(schema: self.schema, metaschemes: metaschmas)
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


let DRAFT_2019_09_META_SCHEMA_CORE: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/core",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/core": true
    },
    "$recursiveAnchor": true,

    "title": "Core vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "$id": {
            "type": "string",
            "format": "uri-reference",
            "$comment": "Non-empty fragments not allowed.",
            "pattern": "^[^#]*#?$"
        },
        "$schema": {
            "type": "string",
            "format": "uri"
        },
        "$anchor": {
            "type": "string",
            "pattern": "^[A-Za-z][-A-Za-z0-9.:_]*$"
        },
        "$ref": {
            "type": "string",
            "format": "uri-reference"
        },
        "$recursiveRef": {
            "type": "string",
            "format": "uri-reference"
        },
        "$recursiveAnchor": {
            "type": "boolean",
            "default": false
        },
        "$vocabulary": {
            "type": "object",
            "propertyNames": {
                "type": "string",
                "format": "uri"
            },
            "additionalProperties": {
                "type": "boolean"
            }
        },
        "$comment": {
            "type": "string"
        },
        "$defs": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "default": {}
        }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2019_09_META_SCHEMA_APPLICATOR: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/applicator",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/applicator": true
    },
    "$recursiveAnchor": true,

    "title": "Applicator vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "additionalItems": { "$recursiveRef": "#" },
        "unevaluatedItems": { "$recursiveRef": "#" },
        "items": {
            "anyOf": [
                { "$recursiveRef": "#" },
                { "$ref": "#/$defs/schemaArray" }
            ]
        },
        "contains": { "$recursiveRef": "#" },
        "additionalProperties": { "$recursiveRef": "#" },
        "unevaluatedProperties": { "$recursiveRef": "#" },
        "properties": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "default": {}
        },
        "patternProperties": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "propertyNames": { "format": "regex" },
            "default": {}
        },
        "dependentSchemas": {
            "type": "object",
            "additionalProperties": {
                "$recursiveRef": "#"
            }
        },
        "propertyNames": { "$recursiveRef": "#" },
        "if": { "$recursiveRef": "#" },
        "then": { "$recursiveRef": "#" },
        "else": { "$recursiveRef": "#" },
        "allOf": { "$ref": "#/$defs/schemaArray" },
        "anyOf": { "$ref": "#/$defs/schemaArray" },
        "oneOf": { "$ref": "#/$defs/schemaArray" },
        "not": { "$recursiveRef": "#" }
    },
    "$defs": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$recursiveRef": "#" }
        }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2019_09_META_SCHEMA_VALIDATION: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/validation",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/validation": true
    },
    "$recursiveAnchor": true,

    "title": "Validation vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
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
        "maxLength": { "$ref": "#/$defs/nonNegativeInteger" },
        "minLength": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "pattern": {
            "type": "string",
            "format": "regex"
        },
        "maxItems": { "$ref": "#/$defs/nonNegativeInteger" },
        "minItems": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "uniqueItems": {
            "type": "boolean",
            "default": false
        },
        "maxContains": { "$ref": "#/$defs/nonNegativeInteger" },
        "minContains": {
            "$ref": "#/$defs/nonNegativeInteger",
            "default": 1
        },
        "maxProperties": { "$ref": "#/$defs/nonNegativeInteger" },
        "minProperties": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "required": { "$ref": "#/$defs/stringArray" },
        "dependentRequired": {
            "type": "object",
            "additionalProperties": {
                "$ref": "#/$defs/stringArray"
            }
        },
        "const": true,
        "enum": {
            "type": "array",
            "items": true
        },
        "type": {
            "anyOf": [
                { "$ref": "#/$defs/simpleTypes" },
                {
                    "type": "array",
                    "items": { "$ref": "#/$defs/simpleTypes" },
                    "minItems": 1,
                    "uniqueItems": true
                }
            ]
        }
    },
    "$defs": {
        "nonNegativeInteger": {
            "type": "integer",
            "minimum": 0
        },
        "nonNegativeIntegerDefault0": {
            "$ref": "#/$defs/nonNegativeInteger",
            "default": 0
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
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2019_09_META_SCHEMA_METADATA: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/meta-data",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/meta-data": true
    },
    "$recursiveAnchor": true,

    "title": "Meta-data vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "title": {
            "type": "string"
        },
        "description": {
            "type": "string"
        },
        "default": true,
        "deprecated": {
            "type": "boolean",
            "default": false
        },
        "readOnly": {
            "type": "boolean",
            "default": false
        },
        "writeOnly": {
            "type": "boolean",
            "default": false
        },
        "examples": {
            "type": "array",
            "items": true
        }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2019_09_META_SCHEMA_FORMAT: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/format",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/format": true
    },
    "$recursiveAnchor": true,

    "title": "Format vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "format": { "type": "string" }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2019_09_META_SCHEMA_CONTENT: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/content",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/content": true
    },
    "$recursiveAnchor": true,

    "title": "Content vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "contentMediaType": { "type": "string" },
        "contentEncoding": { "type": "string" },
        "contentSchema": { "$recursiveRef": "#" }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()
