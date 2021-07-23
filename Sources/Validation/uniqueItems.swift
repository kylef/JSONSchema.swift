import Foundation


func uniqueItems(context: Context, uniqueItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let uniqueItems = uniqueItems as? Bool, uniqueItems else {
    return AnySequence(EmptyCollection())
  }

  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  var items: [Any] = []
  for item in instance {
    if items.contains(where: { isEqual(item as! NSObject, $0 as! NSObject) }) {
      let message = String(format: NSLocalizedString("%@ does not have unique items", comment: ""), "\(instance)")
      return AnySequence([
        ValidationError(
          message,
          instanceLocation: context.instanceLocation,
          keywordLocation: context.keywordLocation
        )
      ])
    }
    items.append(item)
  }

  return AnySequence(EmptyCollection())
}
