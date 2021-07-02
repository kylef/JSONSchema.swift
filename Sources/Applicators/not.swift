import Foundation


func not(context: Context, not: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard try context.descend(instance: instance, subschema: not).isValid else {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("'%@' does not match 'not' validation.", comment: ""), "\(instance)")
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}

