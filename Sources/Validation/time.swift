import Foundation

func validateTime(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
  if let date = value as? String {
    let rfc3339DateTimeFormatter = DateFormatter()

    rfc3339DateTimeFormatter.dateFormat = "HH:mm:ss.SSSZZZZZ"
    if rfc3339DateTimeFormatter.date(from: date) != nil {
      return AnySequence(EmptyCollection())
    }

    rfc3339DateTimeFormatter.dateFormat = "HH:mm:ssZZZZZ"
    if rfc3339DateTimeFormatter.date(from: date) != nil {
      return AnySequence(EmptyCollection())
    }
    
    return AnySequence([
      ValidationError(
        "'\(date)' is not a valid RFC 3339 formatted time.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}
