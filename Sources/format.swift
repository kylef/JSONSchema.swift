import Foundation


func format(context: Context, format: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let format = format as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let validator = context.validator.formats[format] else {
    return AnySequence([
      ValidationError(
        "'format' validation of '\(format)' is not yet supported.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return validator(context, instance)
}


func validateIPv4(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let ipv4 = value as? String {
    if let expression = try? NSRegularExpression(pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", options: NSRegularExpression.Options(rawValue: 0)) {
      if expression.matches(in: ipv4, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, ipv4.count)).count == 1 {
        return AnySequence(EmptyCollection())
      }
    }

    return AnySequence([
      ValidationError(
        "'\(ipv4)' is not a IPv4 address.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}



func validateIPv6(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let ipv6 = value as? String {
    if !ipv6.contains("%") {
      var buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
      if inet_pton(AF_INET6, ipv6, &buf) == 1 {
        return AnySequence(EmptyCollection())
      }
    }

    return AnySequence([
      ValidationError(
        "'\(ipv6)' is not a IPv6 address.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}


func validateURI(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
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

    return AnySequence([
      ValidationError(
        "'\(uri)' is not a valid uri.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}


func validateUUID(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String {
    if UUID(uuidString: value) == nil {
      return AnySequence([
        ValidationError(
          "'\(value)' is not a valid uuid.",
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        )
      ])
    }
  }

  return AnySequence(EmptyCollection())
}


func validateRegex(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String {
    do {
      _ = try NSRegularExpression(pattern: value)
    } catch {
      return AnySequence([
        ValidationError(
          "'\(value)' is not a valid regex.",
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        )
      ])
    }
  }

  return AnySequence(EmptyCollection())
}


func validateJSONPointer(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let value = value as? String, !value.isEmpty {
    if !value.hasPrefix("/") {
      return AnySequence([
        ValidationError(
          "'\(value)' is not a valid json-pointer.",
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
      return AnySequence([
        ValidationError(
          "'\(value)' is not a valid json-pointer.",
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        )
      ])
    }
  }

  return AnySequence(EmptyCollection())
}
