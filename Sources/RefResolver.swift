import Foundation

func urlSplitFragment(url: String) -> (String, String) {
  guard let hashIndex = url.index(of: "#") else {
    return (url, "")
  }

  return (
    String(url.prefix(upTo: hashIndex)),
    String(url.suffix(from: url.index(after: hashIndex)))
  )
}

func urlJoin(_ lhs: String, _ rhs: String) -> String {
  if lhs.isEmpty {
    return rhs
  }

  if rhs.isEmpty {
    return lhs
  }

  return URL(string: rhs, relativeTo: URL(string: lhs)!)!.absoluteString
}

func urlNormalise(_ value: String) -> String {
  if value.hasSuffix("#"), let index = value.lastIndex(of: "#") {
    return String(value.prefix(upTo: index))
  }

  return value
}


func urlEqual(_ lhs: String, _ rhs: String) -> Bool {
  return urlNormalise(lhs) == urlNormalise(rhs)
}


class RefResolver {
  let referrer: [String: Any]
  var store: [String: Any]
  var stack: [String]
  let idField: String
  let defsField: String

  init(schema: [String: Any], metaschemes: [String: Any], idField: String = "$id", defsField: String = "$defs") {
    self.referrer = schema
    self.store = metaschemes
    self.idField = idField
    self.defsField = defsField

    if let id = schema[idField] as? String {
      self.store[id] = schema
      self.stack = [id]
    } else {
      self.store[""] = schema
      self.stack = [""]
    }

    storeDefinitions(from: schema)
  }

  init(resolver: RefResolver) {
    referrer = resolver.referrer
    store = resolver.store
    stack = resolver.stack
    idField = resolver.idField
    defsField = resolver.defsField
  }

  func storeDefinitions(from document: Any) {
    guard
      let document = document as? [String: Any],
      let defs = document[defsField] as? [String: Any]
    else {
      return
    }


    for (_, defs) in defs {
      guard let def = defs as? [String: Any] else { continue }

      let id = def[idField] as? String
      let anchor = def["$anchor"] as? String

      let url: String
      if let anchor = anchor {
        url = urlJoin(stack.last!, "\(id ?? "")#\(anchor)")
      } else if let id = id {
        url = urlJoin(stack.last!, id)
      } else { continue }

      self.store[url] = def

      // recurse
      self.stack.append(url)
      storeDefinitions(from: def)
      self.stack.removeLast()
    }
  }

  func resolve(reference: String) -> Any? {
    let url = urlJoin(stack.last!, reference)
    return resolve(url: url)
  }

  func resolve(url: String) -> Any? {
    if let document = store[url] {
      return document
    }

    let (url, fragment) = urlSplitFragment(url: url)
    guard let document = store[url] else {
      return nil
    }

    if let document = document as? [String: Any] {
      return resolve(document: document, fragment: fragment)
    }

    if fragment == "" {
      return document
    }

    return nil
  }

  func resolve(document: [String: Any], fragment: String) -> Any? {
    guard !fragment.isEmpty else {
      return document
    }

    guard let reference = (fragment as NSString).removingPercentEncoding else {
      return nil
    }
    let pointer = JSONPointer(path: reference)
    return pointer.resolve(document: document)
  }
}
