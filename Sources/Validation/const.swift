import Foundation


func const(context: Context, const: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  if isEqual(instance as! NSObject, const as! NSObject) {
     return AnySequence(EmptyCollection())
  }

  return AnySequence([
    ValidationError(
      "'\(instance)' is not equal to const '\(const)'",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
