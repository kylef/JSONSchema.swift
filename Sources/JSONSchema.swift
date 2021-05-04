import Foundation


public enum Type: Swift.String {
  case object = "object"
  case array = "array"
  case string = "string"
  case integer = "integer"
  case number = "number"
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

  public func validate(_ data: Any) throws -> ValidationResult {
    let validator = try JSONSchema.validator(for: schema)
    return try validator.validate(instance: data)
  }

  public func validate(_ data: Any) throws -> AnySequence<ValidationError> {
    let validator = try JSONSchema.validator(for: schema)
    return try validator.validate(instance: data)
  }
}


func validator(for schema: [String: Any]) throws -> Validator {
  guard schema.keys.contains("$schema") else {
    // Default schema
    return Draft202012Validator(schema: schema)
  }

  guard let schemaURI = schema["$schema"] as? String else {
    throw ReferenceError.notFound
  }

  if let id = DRAFT_2020_12_META_SCHEMA["$id"] as? String, urlEqual(schemaURI, id) {
    return Draft202012Validator(schema: schema)
  }

  if let id = DRAFT_2019_09_META_SCHEMA["$id"] as? String, urlEqual(schemaURI, id) {
    return Draft201909Validator(schema: schema)
  }

  if let id = DRAFT_07_META_SCHEMA["$id"] as? String, urlEqual(schemaURI, id) {
    return Draft7Validator(schema: schema)
  }

  if let id = DRAFT_06_META_SCHEMA["$id"] as? String, urlEqual(schemaURI, id) {
    return Draft6Validator(schema: schema)
  }

  if let id = DRAFT_04_META_SCHEMA["id"] as? String, urlEqual(schemaURI, id) {
    return Draft4Validator(schema: schema)
  }

  throw ReferenceError.notFound
}


public func validate(_ value: Any, schema: [String: Any]) throws -> ValidationResult {
  return try validator(for: schema).validate(instance: value)
}


public func validate(_ value: Any, schema: Bool) throws -> ValidationResult {
  let validator = Draft4Validator(schema: schema)
  return try validator.validate(instance: value)
}
