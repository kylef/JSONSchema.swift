func ref(context: Context, reference: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  guard let reference = reference as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let document = context.resolve(ref: reference) else {
    return AnySequence([
      ValidationError("Reference not found '\(reference)'"),
    ])
  }

  let id: String?
  if let document = document as? [String: Any],
     let idValue = document[context.resolver.idField] as? String
  {
    id = urlNormalise(idValue)
  } else {
    id = nil
  }

  if let id = id {
    context.resolver.stack.append(id)
  }
  defer {
    if let id = id {
      assert(context.resolver.stack.removeLast() == id,
             "popping id mismatch - if this assertion is triggered, there's probably a bug in JSON Schema context library")
    }
  }

  return context.descend(instance: instance, subschema: document)
}
