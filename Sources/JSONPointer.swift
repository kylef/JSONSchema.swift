import Foundation


struct JSONPointer {
  var components: [String]

  init(path: String) {
    if path.isEmpty {
      components = []
    } else {
      components = path
        .components(separatedBy: "/")
        .map {
          $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
        }
    }
  }

  func resolve(document: Any) -> Any? {
    if components.isEmpty {
      return document
    }

    var instance = document
    for component in components[1...] {
      if let document = instance as? [String: Any], let value = document[component] {
        instance = value
        continue
      }

      if let document = instance as? [Any], let index = UInt(component), index < document.count {
        instance = document[Int(index)]
        continue
      }

      return nil
    }

    return instance
  }
}

