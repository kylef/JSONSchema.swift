import Foundation


/*
partial-time https://tools.ietf.org/html/rfc3339

   time-hour       = 2DIGIT  ; 00-23
   time-minute     = 2DIGIT  ; 00-59
   time-second     = 2DIGIT  ; 00-58, 00-59, 00-60 based on leap second
                             ; rules
   time-secfrac    = "." 1*DIGIT
   time-numoffset  = ("+" / "-") time-hour ":" time-minute
   time-offset     = "Z" / time-numoffset

   partial-time    = time-hour ":" time-minute ":" time-second
                     [time-secfrac]
*/


var timeExpression: NSRegularExpression = {
  let time = #"""
  (?x)
  ^
    (?<hour>(([01]\d)|(2[0-3])))
    :
    (?<minute>([0-5]\d))
    :
    (?<second>(([0-5]\d)|(60)))
    (?<secfrac>\.\d+)?
    (?<offset>
      (
        Z
        |
        (?<numoffset>[+-]
          (([01]\d)|2[0-3])
          :
          ([0-5]\d)
        )
      )
    )
  $
  """#
  return try! NSRegularExpression(pattern: time, options: [.caseInsensitive])
}()


func isValidTime(_ value: String) -> Bool {
  guard let match = timeExpression.firstMatch(in: value, range: NSMakeRange(0, value.utf16.count)) else {
    return false
  }

  // FIXME if seconds is 60
  //    Z offset: only pass if hour=23 && minute=59
  //    if -00:00 offset, pass
  //    deduct or add offset to hour/minute and verify hour=23 && minute=59

  return true
}


func validateTime(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if isValidTime(value) {
    return AnySequence(EmptyCollection())
  }

  return AnySequence([
    ValidationError(
      "'\(value)' is not a valid RFC 3339 formatted time.",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
