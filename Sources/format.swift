import Foundation


func format(context: Context, format: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let format = format as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let validator = context.validator.formats[format] else {
    let message = String(format: NSLocalizedString("'format' validation of '%@' is not yet supported.", comment: ""), format)
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return validator(context, instance)
}


func validateIPv4(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if let expression = try? NSRegularExpression(pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", options: NSRegularExpression.Options(rawValue: 0)) {
    if expression.matches(in: value, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, value.utf16.count)).count == 1 {
      return AnySequence(EmptyCollection())
    }
  }

  let message = String(format: NSLocalizedString("'%@' is not a IPv4 address.", comment: ""), value)
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}


func validateIPv6(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if !value.contains("%") {
    var buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
    if inet_pton(AF_INET6, value, &buf) == 1 {
      return AnySequence(EmptyCollection())
    }
  }

  let message = String(format: NSLocalizedString("'%@' is not a value address.", comment: ""), value)
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}


func validateURI(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  // Using the regex from http://blog.dieweltistgarnichtso.net/constructing-a-regular-expression-that-matches-uris

  if let expression = try? NSRegularExpression(pattern: "((?<=\\()[A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+(?=\\)))|([A-Za-z][A-Za-z0-9\\+\\.\\-]*:([A-Za-z0-9\\.\\-_~:/\\?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=]|%[A-Fa-f0-9]{2})+)", options: NSRegularExpression.Options(rawValue: 0)) {
    let result = expression.matches(in: value, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, value.utf16.count))
    if result.count == 1 {
      let foundRange = result[0].range
      if foundRange.location == 0 && foundRange.length == value.utf16.count {
        return AnySequence(EmptyCollection())
      }
    }
  }

  let message = String(format: NSLocalizedString("'%@' is not a valid uri.", comment: ""), value)
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}


func validateUUID(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if UUID(uuidString: value) == nil {
    let message = String(format: NSLocalizedString("'%@' is not a valid uuid.", comment: ""), value)
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}


func validateRegex(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  do {
    _ = try NSRegularExpression(pattern: value)
  } catch {
    let message = String(format: NSLocalizedString("'%@' is not a valid regex.", comment: ""), value)
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}


func validateJSONPointer(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  guard !value.isEmpty else {
    return AnySequence(EmptyCollection())
  }

  if !value.hasPrefix("/") {
    let message = String(format: NSLocalizedString("'%@' is not a valid json-pointer.", comment: ""), value)
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  if value
      .replacingOccurrences(of: "~0", with: "")
      .replacingOccurrences(of: "~1", with: "")
      .contains("~")
  {
    // unescaped ~
    let message = String(format: NSLocalizedString("'%@' is not a valid json-pointer.", comment: ""), value)
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}
