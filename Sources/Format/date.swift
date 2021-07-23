import Foundation


func validateDate(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if let regularExpression = try? NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$", options: []) {
    let range = NSRange(location: 0, length: value.utf16.count)
    let result = regularExpression.matches(in: value, options: [], range: range)
    if result.isEmpty {
      let message = String(format: NSLocalizedString("'%@' is not a valid RFC 3339 formatted date.", comment: ""), value)
      return AnySequence([
        ValidationError(
          message,
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        )
      ])
    }
  }

  let rfc3339DateTimeFormatter = DateFormatter()

  rfc3339DateTimeFormatter.dateFormat = "yyyy-MM-dd"
  if rfc3339DateTimeFormatter.date(from: value) != nil {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("'%@' is not a valid RFC 3339 formatted date.", comment: ""), value)
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
