import Foundation


func oneOf(context: Context, oneOf: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let oneOf = oneOf as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if try oneOf.filter({ try context.descend(instance: instance, subschema: $0).isValid }).count != 1 {
    let message = NSLocalizedString("Only one value from `oneOf` should be met.", comment: "")
    return AnySequence([
      ValidationError(
        message,
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      ),
    ])
  }

  return AnySequence(EmptyCollection())
}
