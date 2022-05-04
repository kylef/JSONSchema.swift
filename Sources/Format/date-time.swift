import Foundation

func isValidDateTime(_ value: String) -> Bool {
    var valueArray = value.components(separatedBy: "T")
    if valueArray.count < 2 {
        valueArray = value.components(separatedBy: "t")
        if valueArray.count < 2 {
          valueArray = value.components(separatedBy: " ")
          if valueArray.count < 2 {
            return false
          }
        }
    }

    let date = valueArray[0]
    let time = valueArray[1]

    if isValidDate(date) && isValidTime(time) {
      return true
    } else {
      return false
    }
}

func validateDateTime(_ context: Context, _ value: String) -> AnySequence<ValidationError> {
  if isValidDateTime(value) {
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
