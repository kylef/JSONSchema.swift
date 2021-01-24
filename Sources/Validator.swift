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

  func descend(instance: Any, subschema: Any) -> AnySequence<ValidationError> {
    return validate(instance: instance, schema: subschema)
  }
}
