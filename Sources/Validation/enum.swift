import Foundation


func `enum`(context: Context, enum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let `enum` = `enum` as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  let instance = instance as! NSObject
  if (`enum` as! [NSObject]).contains(where: { isEqual(instance, $0) }) {
    return AnySequence(EmptyCollection())
  }

  return AnySequence([
    ValidationError(
      "'\(instance)' is not a valid enumeration value of '\(`enum`)'",
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
