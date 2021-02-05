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

  let containsCount = Array(instance.enumerated()).filter({ (index, subinstance) -> Bool in
    context.instanceLocation.push(index.description)
    defer { context.instanceLocation.pop() }
    return context.descend(instance: subinstance, subschema: contains).isValid
  }).count
  if let max = max, containsCount > max {
    return AnySequence(["\(instance) does not match contains + maxContains \(max)"])
  }

  if min == 0 || containsCount >= min {
    return AnySequence(EmptyCollection())
  }

  return AnySequence(["\(instance) does not match contains"])
}
