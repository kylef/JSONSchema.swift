//
//  JSONSchema.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation


func validateType(document:AnyObject)(type:String) -> Bool {
  switch type {
  case "integer":
    if let number = document as? NSNumber {
      return CFNumberIsFloatType(number) == 0 && CFNumberGetType(number) != .CharType
    }
  case "number":
    if let number = document as? NSNumber {
      return CFNumberGetType(number) != .CharType
    }
  case "string":
    return document is String
  case "object":
    return document is NSDictionary
  case "array":
    return document is NSArray
  case "boolean":
    if let number = document as? NSNumber {
      return CFNumberGetType(number) == .CharType
    }
  case "null":
    return document is NSNull
  default:
    break
  }

  return false
}

func validateType(document:AnyObject, type:[String]) -> Bool {
  let results = map(type, validateType(document))
  return filter(results) { result in result }.count > 0
}

func validateType(document:AnyObject, type:String) -> Bool {
  return validateType(document)(type: type)
}

public func validate(document:AnyObject, schema:[String:AnyObject]) -> Bool {
  if let type = schema["type"] as? String {
    return validateType(document, type)
  } else if let type = schema["type"] as? [String] {
    return validateType(document, type)
  }

  return false
}
