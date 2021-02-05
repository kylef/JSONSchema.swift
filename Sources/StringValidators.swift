import Foundation


func validateLength(_ comparitor: @escaping ((Int, Int) -> (Bool)), length: Int, error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? String {
      if !comparitor(value.count, length) {
        return AnySequence([ValidationError(error)])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minLength(validator: Validator, minLength: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minLength = minLength as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateLength(>=, length: minLength, error: "Length of string is smaller than minimum length \(minLength)")(instance)
}


func maxLength(validator: Validator, maxLength: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxLength = maxLength as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateLength(<=, length: maxLength, error: "Length of string is larger than max length \(maxLength)")(instance)
}


func pattern(validator: Validator, pattern: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let pattern = pattern as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let expression = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0)) else {
    return AnySequence(["[Schema] Regex pattern '\(pattern)' is not valid"])
  }

  let range = NSMakeRange(0, instance.count)
  if expression.matches(in: instance, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range).count == 0 {
    return AnySequence(["'\(instance)' does not match pattern: '\(pattern)'"])
  }

  return AnySequence(EmptyCollection())
}


// MARK: Format


func format(validator: Validator, format: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let format = format as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let validator = validator.formats[format] else {
    return invalidValidation("'format' validation of '\(format)' is not yet supported.")(instance)
  }

  return validator(instance)
}


func validateIPv4(_ value: Any) -> AnySequence<ValidationError> {
  if let ipv4 = value as? String {
    if let expression = try? NSRegularExpression(pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", options: NSRegularExpression.Options(rawValue: 0)) {
      if expression.matches(in: ipv4, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, ipv4.count)).count == 1 {
        return AnySequence(EmptyCollection())
      }
    }

    return AnySequence(["'\(ipv4)' is not valid IPv4 address."])
  }

  return AnySequence(EmptyCollection())
}



func validateIPv6(_ value: Any) -> AnySequence<ValidationError> {
  if let ipv6 = value as? String {
    if !ipv6.contains("%") {
      var buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
      if inet_pton(AF_INET6, ipv6, &buf) == 1 {
        return AnySequence(EmptyCollection())
      }
    }

    return AnySequence(["'\(ipv6)' is not valid IPv6 address."])
  }

  return AnySequence(EmptyCollection())
}


func validateURI(_ value: Any) -> AnySequence<ValidationError> {
  if let uri = value as? String {
    // Using the regex from http://blog.dieweltistgarnichtso.net/constructing-a-regular-expression-that-matches-uris

    if let expression = try? NSRegularExpression(pattern: "((?<=\\()[A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+(?=\\)))|([A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+)", options: NSRegularExpression.Options(rawValue: 0)) {
      let result = expression.matches(in: uri, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, uri.count))
      if result.count == 1 {
        let foundRange = result[0].range
        if foundRange.location == 0 && foundRange.length == uri.count {
          return AnySequence(EmptyCollection())
        }
      }
    }

    return AnySequence(["'\(uri)' is not a valid URI."])
  }

  return AnySequence(EmptyCollection())
}


func validateUUID(_ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String {
    if UUID(uuidString: value) == nil {
      return AnySequence(["'\(value)' is not a valid uuid."])
    }
  }

  return AnySequence(EmptyCollection())
}


func validateRegex(_ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String {
    do {
      _ = try NSRegularExpression(pattern: value)
    } catch {
      return AnySequence(["'\(value)' is not a valid regex."])
    }
  }

  return AnySequence(EmptyCollection())
}


func validateJSONPointer(_ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String, !value.isEmpty {
    if !value.hasPrefix("/") {
      return AnySequence(["'\(value)' is not a valid json-pointer."])
    }

    if value
        .replacingOccurrences(of: "~0", with: "")
        .replacingOccurrences(of: "~1", with: "")
        .contains("~")
    {
      // unescaped ~
      return AnySequence(["'\(value)' is not a valid json-pointer."])
    }
  }

  return AnySequence(EmptyCollection())
}
