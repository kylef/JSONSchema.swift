import Foundation

class Context {
  let resolver: RefResolver
  let validator: Validator

  var instanceLocation = JSONPointer()
  var keywordLocation = JSONPointer(path: "#")

  init(resolver: RefResolver, validator: Validator) {
    self.resolver = RefResolver(resolver: resolver)
    self.validator = validator
  }

  func validate(instance: Any, schema: Any) throws -> AnySequence<ValidationError> {
    if let schema = schema as? Bool {
      if schema == true {
        return AnySequence(EmptyCollection())
      }

      return AnySequence([
        ValidationError(
          "Falsy schema",
          instanceLocation: instanceLocation,
          keywordLocation: keywordLocation
        )
      ])
    }

    guard let schema = schema as? [String: Any] else {
      return AnySequence(EmptyCollection())
    }

    if validator is Draft4Validator || validator is Draft6Validator {
      // Older versions of JSON Schema, $ref ignores any alongside keywords
      if let ref = schema["$ref"] as? String {
        keywordLocation.push("$ref")
        defer { keywordLocation.pop() }
        let validation = validator.validations["$ref"]!
        return try validation(self, ref, instance, schema)
      }
    }

    return try AnySequence(validator.validations.compactMap { (key, validation) -> AnySequence<ValidationError> in
      if let value = schema[key] {
        keywordLocation.push(key)
        defer { keywordLocation.pop() }
        return try validation(self, value, instance, schema)
      }

      return AnySequence(EmptyCollection())
    }.joined())
  }

  func resolve(ref: String) -> Any? {
    return resolver.resolve(reference: ref)
  }

  func descend(instance: Any, subschema: Any) throws -> AnySequence<ValidationError> {
    return try validate(instance: instance, schema: subschema)
  }
}

protocol Validator {
  typealias Validation = (Context, Any, Any, [String: Any]) throws -> AnySequence<ValidationError>

  var resolver: RefResolver { get }

  var schema: [String: Any] { get }
  var metaschmas: [String: Any] { get }
  var validations: [String: Validation] { get }
  var formats: [String: (Context, String) -> (AnySequence<ValidationError>)] { get }
}

extension Validator {
  public func validate(instance: Any) throws -> ValidationResult {
    let context = Context(resolver: resolver, validator: self)
    return try context.validate(instance: instance, schema: schema).validationResult()
  }

  public func validate(instance: Any) throws -> AnySequence<ValidationError> {
    let context = Context(resolver: resolver, validator: self)
    return try context.validate(instance: instance, schema: schema)
  }
}
