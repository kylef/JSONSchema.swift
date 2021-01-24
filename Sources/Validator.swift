import Foundation

protocol Validator {
  typealias Validation = (Validator, Any, Any, [String: Any]) -> AnySequence<ValidationError>

  var resolver: RefResolver { get }

  var schema: [String: Any] { get }
  var metaschmas: [String: Any] { get }
  var validations: [String: Validation] { get }
  var formats: [String: (String) -> (AnySequence<ValidationError>)] { get }
}

extension Validator {
  public func validate(instance: Any) -> ValidationResult {
    return validate(instance: instance, schema: schema).validationResult()
  }

  public func validate(instance: Any) -> AnySequence<ValidationError> {
    return validate(instance: instance, schema: schema)
  }

  func validate(instance: Any, schema: Any) -> AnySequence<ValidationError> {
    if let schema = schema as? Bool {
      if schema == true {
        return AnySequence(EmptyCollection())
      }

      return AnySequence(["Falsy schema"])
    }

    guard let schema = schema as? [String: Any] else {
      return AnySequence(EmptyCollection())
    }

    return AnySequence(validations.compactMap { (key, validation) -> AnySequence<ValidationError> in
      if let value = schema[key] {
        return validation(self, value, instance, schema)
      }

      return AnySequence(EmptyCollection())
    }.joined())
  }

  func resolve(ref: String) -> Any? {
    return resolver.resolve(reference: ref)
  }

  func validatorForReference(_ reference: String) -> (Any) -> (AnySequence<ValidationError>) {
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

  func descend(instance: Any, subschema: Any) -> AnySequence<ValidationError> {
    return validate(instance: instance, schema: subschema)
  }
}
