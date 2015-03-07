//
//  Validators.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation


typealias Validator = (AnyObject) -> (Bool)


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
