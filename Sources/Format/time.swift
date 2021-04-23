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
        (?<numoffset>
          (?<numoffsetdirection>[+-])
          (?<numoffsethour>([01]\d)|2[0-3])
          :
          (?<numoffsetminute>[0-5]\d)
        )
      )
    )
  $
  """#
  return try! NSRegularExpression(pattern: time, options: [.caseInsensitive])
}()


typealias TimeOffset = (hour: Int, minute: Int)


enum Offset {
  case zulu
  case positive(TimeOffset)
  case negative(TimeOffset)
}


struct Time {
  var hour: Int
  var minute: Int
  var second: Int
  var offset: Offset

  init(hour: Int, minute: Int, second: Int, offset: Offset) {
    self.hour = hour
    self.minute = minute
    self.second = second
    self.offset = offset
  }

  init?(value: String) {
    guard let match = timeExpression.firstMatch(in: value, range: NSMakeRange(0, value.utf16.count)) else {
      return nil
    }

    let hourRange = Range(match.range(withName: "hour"), in: value)!
    hour = Int(value[hourRange])!

    let minuteRange = Range(match.range(withName: "minute"), in: value)!
    minute = Int(value[minuteRange])!

    let secondRange = Range(match.range(withName: "second"), in: value)!
    second = Int(value[secondRange])!

    if Range(match.range(withName: "numoffset"), in: value) != nil {
      let direction = value[Range(match.range(withName: "numoffsetdirection"), in: value)!]

      let offsetHourRange = Range(match.range(withName: "numoffsethour"), in: value)!
      let offsetHour = Int(value[offsetHourRange])!

      let offsetMinuteRange = Range(match.range(withName: "numoffsetminute"), in: value)!
      let offsetMinute = Int(value[offsetMinuteRange])!

      if direction == "+" {
        offset = .positive((hour: offsetHour, minute: offsetMinute))
      } else if direction == "-" {
        offset = .negative((hour: offsetHour, minute: offsetMinute))
      } else {
        fatalError("ProgramaticError: Incorrect regular expression for time parsing invalid direction")
      }
    } else {
      offset = .zulu
    }
  }

  // returns the time converted to UTC (without num offset)
  var zulu: Time {
    switch offset {
    case .zulu:
      return self
    case let .positive(offset):
      return Time(hour: hour - offset.hour, minute: minute - offset.minute, second: second, offset: .zulu)
    case let .negative(offset):
      return Time(hour: hour + offset.hour, minute: minute + offset.minute, second: second, offset: .zulu)
    }
  }
}


func isValidTime(_ value: String) -> Bool {
  guard let time = Time(value: value) else {
    return false
  }

  let zuluTime = time.zulu
  if zuluTime.second == 60 && (zuluTime.hour != 23 || zuluTime.minute != 59) {
    return false
  }

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
