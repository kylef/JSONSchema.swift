//
//  Validators.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation


typealias Validator = (AnyObject) -> (Bool)

// MARK: Type

func validateType(type:String)(value:AnyObject) -> Bool {
  switch type {
  case "integer":
    if let number = value as? NSNumber {
      return CFNumberIsFloatType(number) == 0 && CFNumberGetType(number) != .CharType
    }
  case "number":
    if let number = value as? NSNumber {
      return CFNumberGetType(number) != .CharType
    }
  case "string":
    return value is String
  case "object":
    return value is NSDictionary
  case "array":
    return value is NSArray
  case "boolean":
    if let number = value as? NSNumber {
      return CFNumberGetType(number) == .CharType
    }
  case "null":
    return value is NSNull
  default:
    break
  }

  return false
}


func validateType(type:[String])(value:AnyObject) -> Bool {
  let validators = map(type, validateType)
  let results = map(validators) { validator in validator(value: value) }
  return filter(results) { result in result }.count > 0
}

// MARK: String

func validateMaximumLength(maximumLength:Int)(value:AnyObject) -> Bool {
  if let value = value as? String {
    return countElements(value) <= maximumLength
  }
  return true
}


func validateMinimumLength(maximumLength:Int)(value:AnyObject) -> Bool {
  if let value = value as? String {
    return countElements(value) >= maximumLength
  }
  return true
}

func validatePattern(pattern:String)(value:AnyObject) -> Bool {
  if let value = value as? String {
    let expression = NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(0), error: nil)
    if let expression = expression {
      let range = NSMakeRange(0, value.utf16Count)
      if expression.matchesInString(value, options: NSMatchingOptions(0), range: range).count > 0 {
        return true
      }
    }

    return false
  }

  return true
}

// MARK: Numerical

func validateMultipleOf(number:NSNumber)(value:AnyObject) -> Bool {
  if let value = value as? NSNumber {
    if number.doubleValue > 0.0 {
      let result = value.doubleValue / number.doubleValue
      return result == floor(result)
    }
  }

  return true
}

func validateMaximum(maximum:NSNumber, exclusive:Bool?)(value:AnyObject) -> Bool {
  if let value = value as? NSNumber {
    if let exclusive = exclusive {
      if exclusive {
        return value.doubleValue < maximum.doubleValue
      }
    }
    return value.doubleValue <= maximum.doubleValue
  }

  return true
}

func validateMinimum(minimum:NSNumber, exclusive:Bool?)(value:AnyObject) -> Bool {
  if let value = value as? NSNumber {
    if let exclusive = exclusive {
      if exclusive {
        return value.doubleValue > minimum.doubleValue
      }
    }

    return value.doubleValue >= minimum.doubleValue
  }

  return true
}

func validateArrayLength(rhs:Int, comparitor:((Int, Int) -> Bool))(value:AnyObject) -> Bool {
  if let value = value as? [AnyObject] {
    return comparitor(value.count, rhs)
  }

  return true
}

func validateUniqueItems(value:AnyObject) -> Bool {
  if let value = value as? [AnyObject] {
    // 1 and true, 0 and false are isEqual for NSNumber's, so logic to count for that below

    func isBoolean(number:NSNumber) -> Bool {
      return CFNumberGetType(number) == .CharType
    }

    let numbers = filter(value) { value in value is NSNumber } as [NSNumber]
    let numerBooleans = filter(numbers, isBoolean)
    let booleans = numerBooleans as [Bool]
    let nonBooleans = filter(numbers) { number in !isBoolean(number) }
    let hasTrueAndOne = filter(booleans) { v in v }.count > 0 && filter(nonBooleans) { v in v == 1 }.count > 0
    let hasFalseAndZero = filter(booleans) { v in !v }.count > 0 && filter(nonBooleans) { v in v == 0 }.count > 0
    let delta = (hasTrueAndOne ? 1 : 0) + (hasFalseAndZero ? 1 : 0)

    return (NSSet(array: value).count + delta) == value.count
  }

  return true // not an array
}
