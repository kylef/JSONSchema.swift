import Foundation

func validateDate(_ context: Context, _ value: Any) -> AnySequence<ValidationError> {
    if let date = value as? String {
        
        if let regularExpression = try? NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$", options: []) {
            let range = NSRange(location: 0, length: date.utf16.count)
            let result = regularExpression.matches(in: date, options: [], range: range)
            if result.isEmpty  {
                return AnySequence([
                    ValidationError(
                        "'\(date)' is not a valid RFC 3339 formatted date.",
                      instanceLocation: context.instanceLocation,
                      keywordLocation: context.keywordLocation
                    )
                ])
            }
        }
        
        let rfc3339DateTimeFormatter = DateFormatter()
        
        rfc3339DateTimeFormatter.dateFormat = "yyyy-MM-dd"
        if rfc3339DateTimeFormatter.date(from: date) != nil {
            return AnySequence(EmptyCollection())
        }

        return AnySequence([
            ValidationError(
                "'\(date)' is not a valid RFC 3339 formatted date.",
              instanceLocation: context.instanceLocation,
              keywordLocation: context.keywordLocation
            )
        ])
    }

    return AnySequence(EmptyCollection())
}

