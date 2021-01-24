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


class RefResolver {
  let referrer: [String: Any]
  var store: [String: Any]
  var stack: [String]
  let idField: String

  init(schema: [String: Any], metaschemes: [String: Any], idField: String = "$id") {
    self.referrer = schema
    self.store = metaschemes
    self.idField = idField

    if let id = schema[idField] as? String {
      self.store[id] = schema
      self.stack = [id]
    } else {
      self.store[""] = schema
      self.stack = [""]
    }
  }

  func resolve(reference: String) -> Any? {
    let url = urlJoin(stack.last!, reference)
    return resolve(url: url)
  }

  func resolve(url: String) -> Any? {
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

    guard let tmp = fragment.stringByRemovingPrefix("/"), let reference = (tmp as NSString).removingPercentEncoding else {
      return nil
    }

    var components = reference
      .components(separatedBy: "/")
      .map {
        $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
      }
    var schema: [String: Any] = document

    while let component = components.first {
      components.remove(at: components.startIndex)

      if let subschema = schema[component] as? [String: Any] {
        schema = subschema
        continue
      } else if let schemas = schema[component] as? [[String:Any]] {
        if let component = components.first, let index = Int(component) {
          components.remove(at: components.startIndex)

          if schemas.count > index {
            schema = schemas[index]
            continue
          }
        }
      } else if let subschema = schema[component] as? Bool {
        if !components.isEmpty {
          return nil
        }
        return subschema
      }

      return nil
    }

    return schema
  }
}
