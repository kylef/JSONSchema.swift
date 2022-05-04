import Foundation

public class Draft202012Validator: Validator {
  let schema: [String: Any]
  let resolver: RefResolver

  let metaschmas: [String : Any] = [
    "https://json-schema.org/draft/2020-12/schema": DRAFT_2020_12_META_SCHEMA,
    "https://json-schema.org/draft/2020-12/vocab/core": DRAFT_2020_12_META_SCHEMA_CORE,
    "https://json-schema.org/draft/2020-12/vocab/applicator": DRAFT_2020_12_META_SCHEMA_APPLICATOR,
    "https://json-schema.org/draft/2020-12/vocab/unevaluated": DRAFT_2020_12_META_SCHEMA_UNEVALUATED,
    "https://json-schema.org/draft/2020-12/vocab/validation": DRAFT_2020_12_META_SCHEMA_VALIDATION,
    "https://json-schema.org/draft/2020-12/vocab/meta-data": DRAFT_2020_12_META_SCHEMA_METADATA,
    "https://json-schema.org/draft/2020-12/vocab/format-annotation": DRAFT_2020_12_META_SCHEMA_FORMAT_ANNOTATION,
    "https://json-schema.org/draft/2020-12/vocab/content": DRAFT_2020_12_META_SCHEMA_CONTENT,
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
    "prefixItems": prefixItems,
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


let DRAFT_2020_12_META_SCHEMA: [String: Any] = {
  let string = """
    {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://json-schema.org/draft/2020-12/schema",
        "$vocabulary": {
            "https://json-schema.org/draft/2020-12/vocab/core": true,
            "https://json-schema.org/draft/2020-12/vocab/applicator": true,
            "https://json-schema.org/draft/2020-12/vocab/unevaluated": true,
            "https://json-schema.org/draft/2020-12/vocab/validation": true,
            "https://json-schema.org/draft/2020-12/vocab/meta-data": true,
            "https://json-schema.org/draft/2020-12/vocab/format-annotation": true,
            "https://json-schema.org/draft/2020-12/vocab/content": true
        },
        "$dynamicAnchor": "meta",

        "title": "Core and Validation specifications meta-schema",
        "allOf": [
            {"$ref": "meta/core"},
            {"$ref": "meta/applicator"},
            {"$ref": "meta/unevaluated"},
            {"$ref": "meta/validation"},
            {"$ref": "meta/meta-data"},
            {"$ref": "meta/format-annotation"},
            {"$ref": "meta/content"}
        ],
        "type": ["object", "boolean"],
        "$comment": "This meta-schema also defines keywords that have appeared in previous drafts in order to prevent incompatible extensions as they remain in common use.",
        "properties": {
            "definitions": {
                "$comment": "\\"definitions\\" has been replaced by \\"$defs\\".",
                "type": "object",
                "additionalProperties": { "$dynamicRef": "#meta" },
                "deprecated": true,
                "default": {}
            },
            "dependencies": {
                "$comment": "\\"dependencies\\" has been split and replaced by \\"dependentSchemas\\" and \\"dependentRequired\\" in order to serve their differing semantics.",
                "type": "object",
                "additionalProperties": {
                    "anyOf": [
                        { "$dynamicRef": "#meta" },
                        { "$ref": "meta/validation#/$defs/stringArray" }
                    ]
                },
                "deprecated": true,
                "default": {}
            },
            "$recursiveAnchor": {
                "$comment": "\\"$recursiveAnchor\\" has been replaced by \\"$dynamicAnchor\\".",
                "$ref": "meta/core#/$defs/anchorString",
                "deprecated": true
            },
            "$recursiveRef": {
                "$comment": "\\"$recursiveRef\\" has been replaced by \\"$dynamicRef\\".",
                "$ref": "meta/core#/$defs/uriReferenceString",
                "deprecated": true
            }
        }
    }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2020_12_META_SCHEMA_CORE: [String: Any] = {
  let string = """
    {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://json-schema.org/draft/2020-12/meta/core",
        "$vocabulary": {
            "https://json-schema.org/draft/2020-12/vocab/core": true
        },
        "$dynamicAnchor": "meta",

        "title": "Core vocabulary meta-schema",
        "type": ["object", "boolean"],
        "properties": {
            "$id": {
                "$ref": "#/$defs/uriReferenceString",
                "$comment": "Non-empty fragments not allowed.",
                "pattern": "^[^#]*#?$"
            },
            "$schema": { "$ref": "#/$defs/uriString" },
            "$ref": { "$ref": "#/$defs/uriReferenceString" },
            "$anchor": { "$ref": "#/$defs/anchorString" },
            "$dynamicRef": { "$ref": "#/$defs/uriReferenceString" },
            "$dynamicAnchor": { "$ref": "#/$defs/anchorString" },
            "$vocabulary": {
                "type": "object",
                "propertyNames": { "$ref": "#/$defs/uriString" },
                "additionalProperties": {
                    "type": "boolean"
                }
            },
            "$comment": {
                "type": "string"
            },
            "$defs": {
                "type": "object",
                "additionalProperties": { "$dynamicRef": "#meta" }
            }
        },
        "$defs": {
            "anchorString": {
                "type": "string",
                "pattern": "^[A-Za-z_][-A-Za-z0-9._]*$"
            },
            "uriString": {
                "type": "string",
                "format": "uri"
            },
            "uriReferenceString": {
                "type": "string",
                "format": "uri-reference"
            }
        }
    }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()

let DRAFT_2020_12_META_SCHEMA_APPLICATOR: [String: Any] = {
  let string = """
    {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://json-schema.org/draft/2020-12/meta/applicator",
        "$vocabulary": {
            "https://json-schema.org/draft/2020-12/vocab/applicator": true
        },
        "$dynamicAnchor": "meta",

        "title": "Applicator vocabulary meta-schema",
        "type": ["object", "boolean"],
        "properties": {
            "prefixItems": { "$ref": "#/$defs/schemaArray" },
            "items": { "$dynamicRef": "#meta" },
            "contains": { "$dynamicRef": "#meta" },
            "additionalProperties": { "$dynamicRef": "#meta" },
            "properties": {
                "type": "object",
                "additionalProperties": { "$dynamicRef": "#meta" },
                "default": {}
            },
            "patternProperties": {
                "type": "object",
                "additionalProperties": { "$dynamicRef": "#meta" },
                "propertyNames": { "format": "regex" },
                "default": {}
            },
            "dependentSchemas": {
                "type": "object",
                "additionalProperties": { "$dynamicRef": "#meta" },
                "default": {}
            },
            "propertyNames": { "$dynamicRef": "#meta" },
            "if": { "$dynamicRef": "#meta" },
            "then": { "$dynamicRef": "#meta" },
            "else": { "$dynamicRef": "#meta" },
            "allOf": { "$ref": "#/$defs/schemaArray" },
            "anyOf": { "$ref": "#/$defs/schemaArray" },
            "oneOf": { "$ref": "#/$defs/schemaArray" },
            "not": { "$dynamicRef": "#meta" }
        },
        "$defs": {
            "schemaArray": {
                "type": "array",
                "minItems": 1,
                "items": { "$dynamicRef": "#meta" }
            }
        }
    }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2020_12_META_SCHEMA_UNEVALUATED: [String: Any] = {
  let string = """
      {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://json-schema.org/draft/2020-12/meta/unevaluated",
        "$vocabulary": {
            "https://json-schema.org/draft/2020-12/vocab/unevaluated": true
        },
        "$dynamicAnchor": "meta",

        "title": "Unevaluated applicator vocabulary meta-schema",
        "type": ["object", "boolean"],
        "properties": {
            "unevaluatedItems": { "$dynamicRef": "#meta" },
            "unevaluatedProperties": { "$dynamicRef": "#meta" }
        }
    }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2020_12_META_SCHEMA_VALIDATION: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/validation",
    "$vocabulary": {
        "https://json-schema.org/draft/2020-12/vocab/validation": true
    },
    "$dynamicAnchor": "meta",

    "title": "Validation vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
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
        },
        "const": true,
        "enum": {
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


let DRAFT_2020_12_META_SCHEMA_METADATA: [String: Any] = {
  let string = """
    {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://json-schema.org/draft/2020-12/meta/meta-data",
        "$vocabulary": {
            "https://json-schema.org/draft/2020-12/vocab/meta-data": true
        },
        "$dynamicAnchor": "meta",

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


let DRAFT_2020_12_META_SCHEMA_FORMAT_ANNOTATION: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/format-annotation",
    "$vocabulary": {
        "https://json-schema.org/draft/2020-12/vocab/format-annotation": true
    },
    "$dynamicAnchor": "meta",

    "title": "Format vocabulary meta-schema for annotation results",
    "type": ["object", "boolean"],
    "properties": {
        "format": { "type": "string" }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()


let DRAFT_2020_12_META_SCHEMA_CONTENT: [String: Any] = {
  let string = """
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/content",
    "$vocabulary": {
        "https://json-schema.org/draft/2020-12/vocab/content": true
    },
    "$dynamicAnchor": "meta",

    "title": "Content vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "contentEncoding": { "type": "string" },
        "contentMediaType": { "type": "string" },
        "contentSchema": { "$dynamicRef": "#meta" }
    }
  }
  """
  let object = try! JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: JSONSerialization.ReadingOptions(rawValue: 0))
  return object as! [String: Any]
}()
