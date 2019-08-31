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
    let validator = Draft4Validator(schema: schema)
    return validator.validate(instance: data)
  }
}


func validatorCurry(_ validator: @escaping (Draft4Validator, Any, Any, [String: Any]) -> ValidationResult) -> ((_ validator: Draft4Validator, _ value: Any, _ schema: [String: Any]) -> ((_ instance: Any) -> ValidationResult)) {
  return { (v, value, schema) in
    return { instance in
      return validator(v, value, instance, schema)
    }
  }
}


public func validate(_ value: Any, schema: [String: Any]) -> ValidationResult {
  let validator = Draft4Validator(schema: schema)
  return validator.validate(instance: value)
}


public func validate(_ value: Any, schema: Bool) -> ValidationResult {
  let validator = Draft4Validator(schema: schema)
  return validator.validate(instance: value)
}
