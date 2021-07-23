import Foundation


func const(context: Context, const: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  if isEqual(instance as! NSObject, const as! NSObject) {
     return AnySequence(EmptyCollection())
  }
  
  let message = String(format: NSLocalizedString("'%@' is not equal to const '%@'", comment: ""), "\(instance)", "\(const)")
  return AnySequence([
    ValidationError(
      message,
      instanceLocation: context.instanceLocation,
      keywordLocation: context.keywordLocation
    )
  ])
}
