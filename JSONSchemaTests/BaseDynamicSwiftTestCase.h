//
//  BaseDynamicSwiftTestCase.h
//  JSONSchema
//
//  Created by Mark Lilback on 8/18/15.
//  Copyright © 2015 Mark Lilback. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface BaseDynamicSwiftTestCase : XCTestCase
//subclasses should overide in place of testInstances()
+(NSArray*)testSelectorNames;
@end
