enum ReferenceError: Error {
  case notFound
}

func ref(context: Context, reference: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  guard let reference = reference as? String else {
    return AnySequence(EmptyCollection())
  }

  guard let document = context.resolve(ref: reference) else {
    throw ReferenceError.notFound
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

  return try context.descend(instance: instance, subschema: document)
}
