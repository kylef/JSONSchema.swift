import Foundation


func `enum`(context: Context, enum: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let `enum` = `enum` as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  let instance = instance as! NSObject
  if (`enum` as! [NSObject]).contains(where: { isEqual(instance, $0) }) {
    return AnySequence(EmptyCollection())
  }

  let message = String(format: NSLocalizedString("'%@' is not a valid enumeration value of '%@'", comment: ""), "\(instance)", "\(`enum`)")
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
