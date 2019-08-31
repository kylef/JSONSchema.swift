import Foundation


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

typealias LegacyValidator = (Any) -> (Bool)
typealias Validator = (Any) -> (ValidationResult)

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

func type(validator: Draft4Validator, type: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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

  let typeValidators = type.map(validateType) as [Validator]
  return anyOf(typeValidators)(instance)
}

/// Validate the given value is of the given type
func validateType(_ type: String) -> (_ value: Any) -> ValidationResult {
  return { value in
    switch type {
    case "integer":
      if let number = value as? NSNumber {
        if !CFNumberIsFloatType(number) && CFGetTypeID(number) != CFBooleanGetTypeID() {
          return .valid
        }
      }
    case "number":
      if let number = value as? NSNumber {
        if CFGetTypeID(number) != CFBooleanGetTypeID() {
          return .valid
        }
      }
    case "string":
      if value is String {
        return .valid
      }
    case "object":
      if value is NSDictionary {
        return .valid
      }
    case "array":
      if value is NSArray {
        return .valid
      }
    case "boolean":
      if let number = value as? NSNumber {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          return .valid
        }
      }
    case "null":
      if value is NSNull {
        return .valid
      }
    default:
      break
    }

    return .invalid(["'\(value)' is not of type '\(type)'"])
  }
}

/// Validate that a value is valid for any of the given validation rules
func anyOf(_ validators: [Validator], error: String? = nil) -> (_ value: Any) -> ValidationResult {
  return { value in
    for validator in validators {
      let result = validator(value)
      if result.valid {
        return .valid
      }
    }

    if let error = error {
      return .invalid([error])
    }

    return .invalid(["\(value) does not meet anyOf validation rules."])
  }
}

func anyOf(validator: Draft4Validator, anyOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let anyOf = anyOf as? [Any] else {
    return .valid
  }

  let anyOfValidators = anyOf.map(JSONSchema.validators(schema)).map(JSONSchema.allOf) as [Validator]
  return JSONSchema.anyOf(anyOfValidators)(instance)
}

func oneOf(validator: Draft4Validator, oneOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let oneOf = oneOf as? [Any] else {
    return .valid
  }

  let oneOfValidators = oneOf.map(JSONSchema.validators(schema)).map(allOf) as [Validator]
  return JSONSchema.oneOf(oneOfValidators)(instance)
}

func oneOf(_ validators: [Validator]) -> (_ value: Any) -> ValidationResult {
  return { value in
    let results = validators.map { validator in validator(value) }
    let validValidators = results.filter { $0.valid }.count

    if validValidators == 1 {
      return .valid
    }

    return .invalid(["\(validValidators) validates instead `oneOf`."])
  }
}

func not(validator: Draft4Validator, not: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  let notValidator = allOf(JSONSchema.validators(schema)(not))

  if notValidator(instance).valid {
    return .invalid(["'\(instance)' does not match 'not' validation."])
  }

  return .valid
}

func allOf(validator: Draft4Validator, allOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let allOf = allOf as? [Any] else {
    return .valid
  }

  return flatten(allOf.map(JSONSchema.validators(schema)).reduce([], +).map { $0(instance) })
}

func allOf(_ validators: [Validator]) -> (_ value: Any) -> ValidationResult {
  return { value in
    return flatten(validators.map { validator in validator(value) })
  }
}


func isEqual(_ lhs: NSObject, _ rhs: NSObject) -> Bool {
  if let lhs = lhs as? NSNumber, let rhs = rhs as? NSNumber, CFGetTypeID(lhs) != CFGetTypeID(rhs) {
    return false
  }

  return lhs == rhs
}

func `enum`(validator: Draft4Validator, enum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let `enum` = `enum` as? [Any] else {
    return .valid
  }

  let instance = instance as! NSObject
  if (`enum` as! [NSObject]).contains(where: { isEqual(instance, $0) }) {
    return .valid
  }

  return .invalid(["'\(instance)' is not a valid enumeration value of '\(`enum`)'"])
}

func const(validator: Draft4Validator, const: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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

func minLength(validator: Draft4Validator, minLength: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minLength = minLength as? Int else {
    return .valid
  }

  return validateLength(>=, length: minLength, error: "Length of string is smaller than minimum length \(minLength)")(instance)
}

func maxLength(validator: Draft4Validator, maxLength: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxLength = maxLength as? Int else {
    return .valid
  }

  return validateLength(<=, length: maxLength, error: "Length of string is larger than max length \(maxLength)")(instance)
}

func pattern(validator: Draft4Validator, pattern: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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

func multipleOf(validator: Draft4Validator, multipleOf: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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

func minimum(validator: Draft4Validator, minimum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minimum = minimum as? Double else {
    return .valid
  }

  return validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: "Value is lower than minimum value of \(minimum)")(instance)
}

func maximum(validator: Draft4Validator, maximum: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maximum = maximum as? Double else {
    return .valid
  }

  return validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: "Value exceeds maximum value of \(maximum)")(instance)
}

// MARK: Array

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

func minItems(validator: Draft4Validator, minItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minItems = minItems as? Int else {
    return .valid
  }

  return validateArrayLength(minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)")(instance)
}

func maxItems(validator: Draft4Validator, maxItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxItems = maxItems as? Int else {
    return .valid
  }

  return validateArrayLength(maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)")(instance)
}

func uniqueItems(validator: Draft4Validator, uniqueItems: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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

func contains(validator: Draft4Validator, contains: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [Any] else {
    return .valid
  }

  let validator = allOf(JSONSchema.validators(schema)(contains))
  let arrayContainsValue = instance.contains { validator($0).valid }
  if !arrayContainsValue {
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

func minProperties(validator: Draft4Validator, minProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let minProperties = minProperties as? Int else {
    return .valid
  }

  return validatePropertiesLength(minProperties, comparitor: <=, error: "Amount of properties is less than the required amount")(instance)
}

func maxProperties(validator: Draft4Validator, maxProperties: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let maxProperties = maxProperties as? Int else {
    return .valid
  }

  return validatePropertiesLength(maxProperties, comparitor: >=, error: "Amount of properties is greater than maximum permitted")(instance)
}

func required(validator: Draft4Validator, required: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  guard let required = required as? [String] else {
    return .valid
  }

  if (required.filter { key in !instance.keys.contains(key) }.count == 0) {
    return .valid
  }

  return .invalid(["Required properties are missing '\(required)'"])
}

func propertyNames(validator: Draft4Validator, propertyNames: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let instance = instance as? [String: Any] else {
    return .valid
  }

  let validators = allOf(JSONSchema.validators(schema)(propertyNames))
  return flatten(instance.keys.map(validators))
}

func validateProperties(_ properties: [String: Validator]?, patternProperties: [String: Validator]?, additionalProperties: Validator?) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? [String: Any] {
      let allKeys = NSMutableSet()
      var results = [ValidationResult]()

      if let properties = properties {
        for (key, validator) in properties {
          allKeys.add(key)

          if let value: Any = value[key] {
            results.append(validator(value))
          }
        }
      }

      if let patternProperties = patternProperties {
        for (pattern, validator) in patternProperties {
          do {
            let expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
            let keys = value.keys.filter {
              (key: String) in expression.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.count)).count > 0
            }

            allKeys.addObjects(from: Array(keys))
            results += keys.map { key in validator(value[key]!) }
          } catch {
            return .invalid(["[Schema] '\(pattern)' is not a valid regex pattern for patternProperties"])
          }
        }
      }

      if let additionalProperties = additionalProperties {
        let additionalKeys = value.keys.filter { !allKeys.contains($0) }
        results += additionalKeys.map { key in additionalProperties(value[key]!) }
      }

      return flatten(results)
    }

    return .valid
  }
}


func validateDependency(_ key: String, validator: @escaping LegacyValidator) -> (_ value: Any) -> Bool {
  return { value in
    if let value = value as? [String:Any] {
      if (value[key] != nil) {
        return validator(value as Any)
      }
    }

    return true
  }
}


func validateDependencies(_ key: String, dependencies: [String]) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? [String: Any] {
      if (value[key] != nil) {
        return flatten(dependencies.map { dependency in
          if value[dependency] == nil {
            return .invalid(["'\(key)' is missing it's dependency of '\(dependency)'"])
          }
          return .valid
        })
      }
    }

    return .valid
  }
}

func validateDependency(_ key: String, validator: @escaping Validator) -> (_ value: Any) -> ValidationResult {
  return { value in
    if let value = value as? [String: Any] {
      if (value[key] != nil) {
        return validator(value)
      }
    }

    return .valid
  }
}

func dependencies(validator: Draft4Validator, dependencies: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
  guard let dependencies = dependencies as? [String: Any] else {
    return .valid
  }

  var validators: [Validator] = []

  for (key, dependencies) in dependencies {
    if let dependencies = dependencies as? [String] {
      validators.append(validateDependencies(key, dependencies: dependencies))
    }

    let validator = allOf(JSONSchema.validators(schema)(dependencies))
    validators.append(validateDependency(key, validator: validator))
  }

  return flatten(validators.map { $0(instance) })
}

// MARK: Format

func format(validator: Draft4Validator, format: Any, instance: Any, schema: [String: Any]) -> ValidationResult {
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
