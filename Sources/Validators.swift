import Foundation

typealias ValidationError = String
public enum ValidationResult {
  case valid
  case invalid([String])

  public var valid: Bool {
    switch self {
    case .valid:
      return true
    case .invalid:
      return false
    }
  }

  public var errors: [String]? {
    switch self {
    case .valid:
      return nil
    case .invalid(let errors):
      return errors
    }
  }
}

/// Flatten an array of results into a single result (combining all errors)
func flatten(_ results: [ValidationResult]) -> ValidationResult {
  let failures = results.filter { result in !result.valid }
  if failures.count > 0 {
    let errors = failures.reduce([String]()) { (accumulator, failure) in
      if let errors = failure.errors {
        return accumulator + errors
      }

      return accumulator
    }

    return .invalid(errors)
  }

  return .valid
}

/// Creates a Validator which always returns an valid result
func validValidation(_ value: Any) -> ValidationResult {
  return .valid
}

/// Creates a Validator which always returns an invalid result with the given error
func invalidValidation(_ error: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    return .invalid([error])
  }
}

// MARK: Shared

func ref(validator: Validator, reference: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let reference = reference as? String else {
    return .valid
  }

  if let metaSchemaID = DRAFT_04_META_SCHEMA["id"] as? String, reference == metaSchemaID {
    return Draft4Validator(schema: DRAFT_04_META_SCHEMA).validate(instance: instance)
  }

  if let metaSchemaID = DRAFT_06_META_SCHEMA["$id"] as? String, reference == metaSchemaID {
    return Draft6Validator(schema: DRAFT_06_META_SCHEMA).validate(instance: instance)
  }

  if let metaSchemaID = DRAFT_07_META_SCHEMA["$id"] as? String, reference == metaSchemaID {
    return Draft7Validator(schema: DRAFT_07_META_SCHEMA).validate(instance: instance)
  }

//  if let metaSchemaID = DRAFT_2019_09_META_SCHEMA["$id"] as? String, reference == metaSchemaID {
//    return Draft201909Validator(schema: DRAFT_2019_09_META_SCHEMA).validate(instance: instance)
//  }

  guard let document = validator.resolve(ref: reference) else {
    return .invalid(["Reference not found '\(reference)'"])
  }

  return validator.descend(instance: instance, subschema: document)
}

func type(validator: Validator, type: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  func ensureArray(_ value: Any) -> [String]? {
    if let value = value as? [String] {
      return value
    }

    if let value = value as? String {
      return [value]
    }

    return nil
  }

  guard let type = ensureArray(type) else {
    return .valid
  }

  if type.contains(where :{ isType($0, instance) }) {
    return .valid
  }

  let types = type.map { "'\($0)'" }.joined(separator: ", ")
  return .invalid(["'\(instance)' is not of type \(types)"])
}

func isInteger(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
  return !CFNumberIsFloatType(number) && CFGetTypeID(number) != CFBooleanGetTypeID()
}

func isNumber(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
  return CFGetTypeID(number) != CFBooleanGetTypeID()
}

func isObject(_ instance: Any) -> Bool {
  return instance is String
}

func isDictionary(_ instance: Any) -> Bool {
  return instance is NSDictionary
}

func isArray(_ instance: Any) -> Bool {
  return instance is NSArray
}

func isBoolean(_ instance: Any) -> Bool {
  guard let number = instance as? NSNumber else { return false }
  return CFGetTypeID(number) == CFBooleanGetTypeID()
}

func isNull(_ instance: Any) -> Bool {
  return instance is NSNull
}

/// Validate the given value is of the given type
func isType(_ type: String, _ instance: Any) -> Bool {
  switch type {
  case "integer":
    return isInteger(instance)
  case "number":
    return isNumber(instance)
  case "string":
    return isObject(instance)
  case "object":
    return isDictionary(instance)
  case "array":
    return isArray(instance)
  case "boolean":
    return isBoolean(instance)
  case "null":
    return isNull(instance)
  default:
    return false
  }
}

func anyOf(validator: Validator, anyOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let anyOf = anyOf as? [Any] else {
    return .valid
  }

  if !anyOf.contains(where: { validator.descend(instance: instance, subschema: $0).valid }) {
    return .invalid(["\(instance) does not meet anyOf validation rules."])
  }

  return .valid
}

func oneOf(validator: Validator, oneOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let oneOf = oneOf as? [Any] else {
    return .valid
  }

  if oneOf.filter({ validator.descend(instance: instance, subschema: $0).valid }).count != 1 {
    return .invalid(["Only one value from `oneOf` should be met"])
  }

  return .valid
}

func not(validator: Validator, not: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  let result = validator.descend(instance: instance, subschema: not)

  if result.valid {
    return .invalid(["'\(instance)' does not match 'not' validation."])
  }

  return .valid
}

func `if`(validator: Validator, `if`: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  if validator.validate(instance: instance, schema: `if`).validationResult().valid {
    if let then = schema["then"] {
      return validator.descend(instance: instance, subschema: then)
    }
  } else if let `else` = schema["else"] {
    return validator.descend(instance: instance, subschema: `else`)
  }

  return .valid
}

func allOf(validator: Validator, allOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let allOf = allOf as? [Any] else {
    return .valid
  }

  return flatten(allOf.map({ validator.descend(instance: instance, subschema: $0) }))
}

func isEqual(_ lhs: NSObject, _ rhs: NSObject) -> Bool {
  if let lhs = lhs as? NSNumber, let rhs = rhs as? NSNumber, CFGetTypeID(lhs) != CFGetTypeID(rhs) {
    return false
  }

  return lhs == rhs
}

func `enum`(validator: Validator, enum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let `enum` = `enum` as? [Any] else {
    return .valid
  }

  let instance = instance as! NSObject
  if (`enum` as! [NSObject]).contains(where: { isEqual(instance, $0) }) {
    return .valid
  }

  return .invalid(["'\(instance)' is not a valid enumeration value of '\(`enum`)'"])
}

func const(validator: Validator, const: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  if isEqual(instance as! NSObject, const as! NSObject) {
     return .valid
  }

  return .invalid(["'\(instance)' is not equal to const '\(const)'"])
}

// MARK: String

func validateLength(_ comparitor: @escaping ((Int, Int) -> (Bool)), length: Int, error: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? String {
      if !comparitor(value.count, length) {
        return .invalid([error])
      }
    }

    return .valid
  }
}

func minLength(validator: Validator, minLength: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minLength = minLength as? Int else {
    return .valid
  }

  return validateLength(>=, length: minLength, error: "Length of string is smaller than minimum length \(minLength)")(instance)
}

func maxLength(validator: Validator, maxLength: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxLength = maxLength as? Int else {
    return .valid
  }

  return validateLength(<=, length: maxLength, error: "Length of string is larger than max length \(maxLength)")(instance)
}

func pattern(validator: Validator, pattern: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let pattern = pattern as? String else {
    return .valid
  }

  guard let instance = instance as? String else {
    return .valid
  }

  guard let expression = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0)) else {
    return .invalid(["[Schema] Regex pattern '\(pattern)' is not valid"])
  }

  let range = NSMakeRange(0, instance.count)
  if expression.matches(in: instance, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range).count == 0 {
    return .invalid(["'\(instance)' does not match pattern: '\(pattern)'"])
  }

  return .valid
}

// MARK: Numerical

func multipleOf(validator: Validator, multipleOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let multipleOf = multipleOf as? Double else {
    return .valid
  }

  guard let instance = instance as? Double, instance > 0.0 else {
    return .valid
  }

  let result = instance / multipleOf
  if result != floor(result) {
    return .invalid(["\(instance) is not a multiple of \(multipleOf)"])
  }

  return .valid
}

func validateNumericLength(_ length: Double, comparitor: @escaping ((Double, Double) -> (Bool)), exclusiveComparitor: @escaping ((Double, Double) -> (Bool)), exclusive: Bool?, error: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? Double {
      if exclusive ?? false {
        if !exclusiveComparitor(value, length) {
          return .invalid([error])
        }
      }

      if !comparitor(value, length) {
        return .invalid([error])
      }
    }

    return .valid
  }
}

func minimumDraft4(validator: Validator, minimum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minimum = minimum as? Double else {
    return .valid
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: "Value is lower than minimum value of \(minimum)")(instance)
}

func maximumDraft4(validator: Validator, maximum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maximum = maximum as? Double else {
    return .valid
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: "Value exceeds maximum value of \(maximum)")(instance)
}

func minimum(validator: Validator, minimum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minimum = minimum as? Double else {
    return .valid
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: false, error: "Value is lower than minimum value of \(minimum)")(instance)
}

func maximum(validator: Validator, maximum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maximum = maximum as? Double else {
    return .valid
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: false, error: "Value exceeds maximum value of \(maximum)")(instance)
}

func exclusiveMinimum(validator: Validator, minimum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minimum = minimum as? Double else {
    return .valid
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: true, error: "Value is lower than exclusive minimum value of \(minimum)")(instance)
}

func exclusiveMaximum(validator: Validator, maximum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maximum = maximum as? Double else {
    return .valid
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: true, error: "Value exceeds exclusive maximum value of \(maximum)")(instance)
}

// MARK: Array

func items(validator: Validator, items: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [Any] else {
    return .valid
  }

  if let items = items as? [String: Any] {
    return flatten(instance.map { validator.descend(instance: $0, subschema: items) })
  }

  if let items = items as? Bool {
    return flatten(instance.map { validator.descend(instance: $0, subschema: items) })
  }

  if let items = items as? [Any] {
    var results = [ValidationResult]()

    for (index, item) in instance.enumerated() where index < items.count {
      results.append(validator.descend(instance: item, subschema: items[index]))
    }

    return flatten(results)
  }

  return .valid
}

func additionalItems(validator: Validator, additionalItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [Any], let items = schema["items"] as? [Any], instance.count > items.count else {
    return .valid
  }

  if let additionalItems = additionalItems as? [String: Any] {
    return flatten(instance[items.count...].map { validator.descend(instance: $0, subschema: additionalItems) })
  }

  if let additionalItems = additionalItems as? Bool, !additionalItems {
    return invalidValidation("Additional results are not permitted in this array.")(instance)
  }

  return .valid
}

func validateArrayLength(_ rhs: Int, comparitor: @escaping ((Int, Int) -> Bool), error: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? [Any] {
      if !comparitor(value.count, rhs) {
        return .invalid([error])
      }
    }

    return .valid
  }
}

func minItems(validator: Validator, minItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minItems = minItems as? Int else {
    return .valid
  }

  return validateArrayLength(minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)")(instance)
}

func maxItems(validator: Validator, maxItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxItems = maxItems as? Int else {
    return .valid
  }

  return validateArrayLength(maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)")(instance)
}

func uniqueItems(validator: Validator, uniqueItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let uniqueItems = uniqueItems as? Bool, uniqueItems else {
    return .valid
  }

  guard let instance = instance as? [Any] else {
    return .valid
  }

  // 1 and true, 0 and false are isEqual for NSNumber's, so logic to count for that below

  func isBoolean(_ number: NSNumber) -> Bool {
    return CFGetTypeID(number) != CFBooleanGetTypeID()
  }

  let numbers = instance.filter { value in value is NSNumber } as! [NSNumber]
  let numerBooleans = numbers.filter(isBoolean)
  let booleans = (numerBooleans as? [Bool]) ?? []
  let nonBooleans = numbers.filter { number in !isBoolean(number) }
  let hasTrueAndOne = booleans.filter { v in v }.count > 0 && nonBooleans.filter { v in v == 1 }.count > 0
  let hasFalseAndZero = booleans.filter { v in !v }.count > 0 && nonBooleans.filter { v in v == 0 }.count > 0
  let delta = (hasTrueAndOne ? 1 : 0) + (hasFalseAndZero ? 1 : 0)

  if (NSSet(array: instance).count + delta) == instance.count {
    return .valid
  }

  return .invalid(["\(instance) does not have unique items"])
}

func contains(validator: Validator, contains: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [Any] else {
    return .valid
  }

  if !instance.contains(where: { validator.descend(instance: $0, subschema: contains).valid }) {
    return .invalid(["\(instance) does not match contains"])
  }

  return .valid
}


// MARK: Object

func validatePropertiesLength(_ length: Int, comparitor: @escaping ((Int, Int) -> (Bool)), error: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? [String: Any] {
      if !comparitor(length, value.count) {
        return .invalid([error])
      }
    }

    return .valid
  }
}

func minProperties(validator: Validator, minProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minProperties = minProperties as? Int else {
    return .valid
  }

  return validatePropertiesLength(minProperties, comparitor: <=, error: "Amount of properties is less than the required amount")(instance)
}

func maxProperties(validator: Validator, maxProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxProperties = maxProperties as? Int else {
    return .valid
  }

  return validatePropertiesLength(maxProperties, comparitor: >=, error: "Amount of properties is greater than maximum permitted")(instance)
}

func required(validator: Validator, required: Any, instance: Any, schema: [String: Any]) -> AnySequence<String> {
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }

  guard let required = required as? [String] else {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(required.lazy.compactMap { key -> String? in
    guard !instance.keys.contains(key) else { return nil }
    return "Required property '\(key)' is missing"
  })
}

func dependentRequired(validator: Validator, dependentRequired: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  guard let dependentRequired = dependentRequired as? [String: [String]] else {
    return .valid
  }

  return flatten(dependentRequired.compactMap({ (key, required) -> ValidationResult? in
    if instance.keys.contains(key) {
      return JSONSchema.required(validator: validator, required: required, instance: instance, schema: schema).validationResult()
    }

    return nil
  }))
}

func dependentSchemas(validator: Validator, dependentRequired: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  guard let dependentRequired = dependentRequired as? [String: Any] else {
    return .valid
  }

  return flatten(dependentRequired.compactMap({ (key, subschema) -> ValidationResult? in
    if instance.keys.contains(key) {
      return validator.descend(instance: instance, subschema: subschema)
    }

    return nil
  }))
}

func propertyNames(validator: Validator, propertyNames: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  return flatten(instance.keys.map { validator.descend(instance: $0, subschema: propertyNames) })
}

func properties(validator: Validator, properties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  guard let properties = properties as? [String: Any] else {
    return .valid
  }

  return flatten(instance.map({ (key, value) in
    if let schema = properties[key] {
      return validator.descend(instance: value, subschema: schema)
    }

    return .valid
  }))
}

func patternProperties(validator: Validator, patternProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  guard let patternProperties = patternProperties as? [String: Any] else {
    return .valid
  }

  var results: [ValidationResult] = []

  for (pattern, schema) in patternProperties {
    do {
      let expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
      let keys = instance.keys.filter {
        (key: String) in expression.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.count)).count > 0
      }

      for key in keys {
        results.append(validator.descend(instance: instance[key]!, subschema: schema))
      }
    } catch {
      return .invalid(["[Schema] '\(pattern)' is not a valid regex pattern for patternProperties"])
    }
  }

  return flatten(results)
}

func findAdditionalProperties(instance: [String: Any], schema: [String: Any]) -> Set<String> {
  var keys: Set<String> = Set(instance.keys)

  if let properties = schema["properties"] as? [String: Any] {
    keys.subtract(properties.keys)
  }

  if let patternProperties = schema["patternProperties"] as? [String: Any] {
    let patterns = patternProperties.keys
      .compactMap { try? NSRegularExpression(pattern: $0, options: NSRegularExpression.Options(rawValue: 0)) }

    for pattern in patterns {
      for key in keys {
        if pattern.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.count)).count > 0 {
          keys.remove(key)
        }
      }
    }
  }

  return keys
}

func additionalProperties(validator: Validator, additionalProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  let extras = findAdditionalProperties(instance: instance, schema: schema)

  if let additionalProperties = additionalProperties as? [String: Any] {
    return flatten(extras.map { validator.descend(instance: instance[$0]!, subschema: additionalProperties) })
  }

  if let additionalProperties = additionalProperties as? Bool, !additionalProperties && !extras.isEmpty {
    return invalidValidation("Additional properties are not permitted in this object.")(instance)
  }

  return .valid
}

func dependencies(validator: Validator, dependencies: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let dependencies = dependencies as? [String: Any] else {
    return .valid
  }

  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  var results: [ValidationResult] = []

  for (property, dependency) in dependencies where instance.keys.contains(property) {
    if let dependency = dependency as? [String] {
      for key in dependency {
        if !instance.keys.contains(key) {
          results.append(.invalid(["'\(key)' is a dependency for '\(property)'"]))
        }
      }
    } else {
      results.append(validator.descend(instance: instance, subschema: dependency))
    }
  }

  return flatten(results)
}

// MARK: Format

func format(validator: Validator, format: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let format = format as? String else {
    return .valid
  }

  guard let instance = instance as? String else {
    return .valid
  }

  guard let validator = validator.formats[format] else {
    return invalidValidation("'format' validation of '\(format)' is not yet supported.")(instance)
  }

  return validator(instance)
}

func validateIPv4(_ value: Any) -> ValidationResult {
  if let ipv4 = value as? String {
    if let expression = try? NSRegularExpression(pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", options: NSRegularExpression.Options(rawValue: 0)) {
      if expression.matches(in: ipv4, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, ipv4.count)).count == 1 {
        return .valid
      }
    }

    return .invalid(["'\(ipv4)' is not valid IPv4 address."])
  }

  return .valid
}


func validateIPv6(_ value: Any) -> ValidationResult {
  if let ipv6 = value as? String {
    var buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
    if inet_pton(AF_INET6, ipv6, &buf) == 1 {
      return .valid
    }

    return .invalid(["'\(ipv6)' is not valid IPv6 address."])
  }

  return .valid
}


func validateURI(_ value: Any) -> ValidationResult {
  if let uri = value as? String {
    // Using the regex from http://blog.dieweltistgarnichtso.net/constructing-a-regular-expression-that-matches-uris

    if let expression = try? NSRegularExpression(pattern: "((?<=\\()[A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+(?=\\)))|([A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+)", options: NSRegularExpression.Options(rawValue: 0)) {
      let result = expression.matches(in: uri, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, uri.count))
      if result.count == 1 {
        let foundRange = result[0].range
        if foundRange.location == 0 && foundRange.length == uri.count {
          return .valid
        }
      }
    }

    return .invalid(["'\(uri)' is not a valid URI."])
  }

  return .valid
}


extension Sequence where Iterator.Element == ValidationError {
  func validationResult() -> ValidationResult {
    let errors = Array(self)
    if errors.isEmpty {
      return .valid
    }

    return .invalid(errors)
  }
}
