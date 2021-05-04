import Foundation

/*
https://tools.ietf.org/html/rfc3339

Durations:

   dur-second        = 1*DIGIT "S"
   dur-minute        = 1*DIGIT "M" [dur-second]
   dur-hour          = 1*DIGIT "H" [dur-minute]
   dur-time          = "T" (dur-hour / dur-minute / dur-second)
   dur-day           = 1*DIGIT "D"
   dur-week          = 1*DIGIT "W"
   dur-month         = 1*DIGIT "M" [dur-day]
   dur-year          = 1*DIGIT "Y" [dur-month]
   dur-date          = (dur-day / dur-month / dur-year) [dur-time]

   duration          = "P" (dur-date / dur-time / dur-week)
*/
var durationExpression: NSRegularExpression = {
  let second = "(\\d+S)"
  let minute = "((\\d+M)\(second)?)"
  let hour = "((\\d+H)\(minute)?)"
  let time = "(T(\(hour)|\(minute)|\(second)))"

  let day = "(\\d+D)"
  let week = "(\\d+W)"
  let month = "((\\d+M)\(day)?)"
  let year = "((\\d+Y)\(month)?)"
  let date = "((\(day)|\(month)|\(year))\(time)?)"

  let duration = "^P(\(date)|\(time)|\(week))$"
  return try! NSRegularExpression(pattern: duration, options: [])
}()


func isValidDuration(_ value: String) -> Bool {
  return durationExpression.numberOfMatches(in: value, range: NSMakeRange(0, value.utf16.count)) != 0
}


func validateDuration(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  guard isValidDuration(value) else {
    return AnySequence([
      ValidationError(
        "'\(value)' is not a valid duration.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }

  return AnySequence(EmptyCollection())
}
