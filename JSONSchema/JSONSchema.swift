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

  // Numerical

  if let multipleOf = schema["multipleOf"] as? NSNumber {
    validators.append(validateMultipleOf(multipleOf))
  }

  if let minimum = schema["minimum"] as? NSNumber {
    validators.append(validateMinimum(minimum, schema["exclusiveMinimum"] as? Bool))
  }

  if let maximum = schema["maximum"] as? NSNumber {
    validators.append(validateMaximum(maximum, schema["exclusiveMaximum"] as? Bool))
  }

  // Array

  if let minItems = schema["minItems"] as? Int {
    validators.append(validateArrayLength(minItems, >=))
  }

  if let maxItems = schema["maxItems"] as? Int {
    validators.append(validateArrayLength(maxItems, <=))
  }

  if let uniqueItems = schema["uniqueItems"] as? Bool {
    if uniqueItems {
      validators.append(validateUniqueItems)
    }
  }

  if let items = schema["items"] as? [String:AnyObject] {
    let itemValidators = validate(JSONSchema.validators(items))

    func validateItems(document:AnyObject) -> Bool {
      if let document = document as? [AnyObject] {
        let results = map(document, itemValidators)
        return filter(results) { result in !result }.count == 0
      }

      return true
    }

    validators.append(validateItems)
  } else if let items = schema["items"] as? [[String:AnyObject]] {
    func createAdditionalItemsValidator(additionalItems:AnyObject?) -> Validator {
      if let additionalItems = additionalItems as? [String:AnyObject] {
        let additionalItemValidators = JSONSchema.validators(additionalItems)
        return validate(additionalItemValidators)
      }

      let additionalItems = additionalItems as? Bool ?? true
      return { value in
        return additionalItems
      }
    }

    let additionalItemsValidator = createAdditionalItemsValidator(schema["additionalItems"])
    let itemValidators = map(items, JSONSchema.validators)

    func validateItems(value:AnyObject) -> Bool {
      if let value = value as? [AnyObject] {
        for (index, element) in enumerate(value) {
          if index >= itemValidators.count {
            if !additionalItemsValidator(element) {
              return false
            }
          } else {
            let validators = itemValidators[index]
            if !validate(validators)(value:element) {
              return false
            }
          }
        }

        return true
      }

      return true
    }

    validators.append(validateItems)
  }

  if let maxProperties = schema["maxProperties"] as? Int {
    validators.append(validateMaxProperties(maxProperties))
  }

  if let minProperties = schema["minProperties"] as? Int {
    validators.append(validateMinProperties(minProperties))
  }

  return validators
}

func validate(validators:[Validator])(value:AnyObject) -> Bool {
  return filter(validators) { validator in
    return !validator(value)
  }.count == 0
}

public func validate(value:AnyObject, schema:[String:AnyObject]) -> Bool {
  return validate(validators(schema))(value: value)
}
