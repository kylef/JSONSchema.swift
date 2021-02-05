import Foundation


func items(context: Context, items: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  if let items = items as? [String: Any] {
    return AnySequence(instance.map { context.descend(instance: $0, subschema: items) }.joined())
  }

  if let items = items as? Bool {
    return AnySequence(instance.map { context.descend(instance: $0, subschema: items) }.joined())
  }

  if let items = items as? [Any] {
    var results = [AnySequence<ValidationError>]()

    for (index, item) in instance.enumerated() where index < items.count {
      results.append(context.descend(instance: item, subschema: items[index]))
    }

    return AnySequence(results.joined())
  }

  return AnySequence(EmptyCollection())
}


func additionalItems(context: Context, additionalItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any], let items = schema["items"] as? [Any], instance.count > items.count else {
    return AnySequence(EmptyCollection())
  }

  if let additionalItems = additionalItems as? [String: Any] {
    return AnySequence(instance[items.count...].map { context.descend(instance: $0, subschema: additionalItems) }.joined())
  }

  if let additionalItems = additionalItems as? Bool, !additionalItems {
    return invalidValidation("Additional results are not permitted in this array.")(instance)
  }

  return AnySequence(EmptyCollection())
}


func validateArrayLength(_ rhs: Int, comparitor: @escaping ((Int, Int) -> Bool), error: String) -> (_ value: Any) -> AnySequence<ValidationError> {
  return { value in
    if let value = value as? [Any] {
      if !comparitor(value.count, rhs) {
        return AnySequence([ValidationError(error)])
      }
    }

    return AnySequence(EmptyCollection())
  }
}


func minItems(context: Context, minItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let minItems = minItems as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateArrayLength(minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)")(instance)
}


func maxItems(context: Context, maxItems: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let maxItems = maxItems as? Int else {
    return AnySequence(EmptyCollection())
  }

  return validateArrayLength(maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)")(instance)
}


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
      return AnySequence(["\(instance) does not have unique items"])
    }
    items.append(item)
  }

  return AnySequence(EmptyCollection())
}


func contains(context: Context, contains: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let instance = instance as? [Any] else {
    return AnySequence(EmptyCollection())
  }

  let min: Int
  if let minContains = schema["minContains"] as? Int, minContains >= 0 {
    min = minContains
  } else {
    min = 1
  }

  let max: Int?
  if let maxContains = schema["maxContains"] as? Int, maxContains > 0 {
    max = maxContains
  } else {
    max = nil
  }

  if max == nil && min == 0 {
    return AnySequence(EmptyCollection())
  }

  let containsCount = instance.filter({ context.descend(instance: $0, subschema: contains).isValid }).count
  if let max = max, containsCount > max {
    return AnySequence(["\(instance) does not match contains + maxContains \(max)"])
  }

  if min == 0 || containsCount >= min {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(["\(instance) does not match contains"])
}
