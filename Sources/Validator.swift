import Foundation

protocol Validator {
  typealias Validation = (Validator, Any, Any, [String: Any]) -> (ValidationResult)
  typealias SequenceValidation = (Validator, Any, Any, [String: Any]) -> AnySequence<ValidationError>

  var resolver: RefResolver { get }

  var schema: [String: Any] { get }
  var validations: [String: Validation] { get }
  var formats: [String: (String) -> (ValidationResult)] { get }
}

func createSequence(validation: @escaping Validator.SequenceValidation) -> Validator.Validation {
  return { (validator, value, instance, schema) in
    return validation(validator, value, instance, schema).validationResult()
  }
}

extension Validator {
  public func validate(instance: Any) -> ValidationResult {
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

  func resolve(ref: String) -> Any? {
    return resolver.resolve(reference: ref)
  }

  func validatorForReference(_ reference: String) -> (Any) -> (ValidationResult) {
    // TODO: Rewrite this whole block: https://github.com/kylef/JSONSchema.swift/issues/12

    if reference == "http://json-schema.org/draft-04/schema#" {
      return { Draft4Validator(schema: DRAFT_04_META_SCHEMA).descend(instance: $0, subschema: DRAFT_04_META_SCHEMA) }
    }

    if reference == "http://json-schema.org/draft-06/schema#" {
      return { Draft7Validator(schema: DRAFT_06_META_SCHEMA).descend(instance: $0, subschema: DRAFT_06_META_SCHEMA) }
    }

    if reference == "http://json-schema.org/draft-07/schema#" {
      return { Draft7Validator(schema: DRAFT_07_META_SCHEMA).descend(instance: $0, subschema: DRAFT_07_META_SCHEMA) }
    }

    if reference == "https://json-schema.org/draft/2019-09/schema" {
      return { Draft201909Validator(schema: DRAFT_2019_09_META_SCHEMA).descend(instance: $0, subschema: DRAFT_2019_09_META_SCHEMA) }
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
