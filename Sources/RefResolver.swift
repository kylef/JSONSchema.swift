import Foundation

class RefResolver {
  let referrer: [String: Any]
  var store: [String: Any]

  init(schema: [String: Any], metaschemes: [String: Any]) {
    self.referrer = schema
    self.store = metaschemes
  }

  func resolve(reference: String) -> Any? {
    // TODO: Rewrite this whole block: https://github.com/kylef/JSONSchema.swift/issues/12

    if let fragment = reference.stringByRemovingPrefix("#") {  // Document relative
      return resolve(document: referrer, fragment: fragment)
    }

    return nil
  }

  func resolve(document: [String: Any], fragment: String) -> [String: Any]? {
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
      }

      return nil
    }

    return schema
  }
}
