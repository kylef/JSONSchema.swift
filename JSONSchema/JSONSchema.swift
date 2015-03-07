//
//  JSONSchema.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

/// Returns a set of validators for a schema and document
func validators(schema:[String:AnyObject]) -> [Validator] {
  var validators = [Validator]()

  if let type = schema["type"] as? String {
    validators.append(validateType(type))
  } else if let type = schema["type"] as? [String] {
    validators.append(validateType(type))
  }

  // String

  if let maxLength = schema["maxLength"] as? Int {
    validators.append(validateMaximumLength(maxLength))
  }

  if let minLength = schema["minLength"] as? Int {
    validators.append(validateMinimumLength(minLength))
  }

  if let pattern = schema["pattern"] as? String {
    validators.append(validatePattern(pattern))
  }

  if let multipleOf = schema["multipleOf"] as? NSNumber {
    validators.append(validateMultipleOf(multipleOf))
  }

  return validators
}

public func validate(document:AnyObject, schema:[String:AnyObject]) -> Bool {
  return filter(validators(schema)) { validator in
    return !validator(document)
  }.count == 0
}
