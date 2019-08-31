class Draft4Validator {
  let schema: [String: Any]
  let formats: [String: Validator] = [
    "ipv4": validateIPv4,
    "ipv6": validateIPv6,
    "uri": validateURI,
  ]

  required init(schema: Bool) {
    if schema {
      self.schema = [:]
    } else {
      self.schema = ["not": [:]]
    }
  }

  required init(schema: [String: Any]) {
    self.schema = schema
  }

  func validate(instance: Any) -> ValidationResult {
    return .valid
  }
}
