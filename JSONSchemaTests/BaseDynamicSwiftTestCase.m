//
//  BaseDynamicSwiftTestCase.m
//  JSONSchema
//
//  Created by Mark Lilback on 8/18/15.
//  Copyright © 2015 Mark Lilback. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseDynamicSwiftTestCase.h"
#import <objc/runtime.h>

@implementation BaseDynamicSwiftTestCase

//subclasses should overide
+(NSArray*)testSelectorNames
{
	return @[];
}

//since swift 2.0 can not reference NSInvocation, we instead ask the swift implementation for a list of selector names and create the invocations in Obj-C
+ (NSArray <NSInvocation *> *)testInvocations
{
	NSMutableArray *invocations = [NSMutableArray array];
	[[self testSelectorNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull selectorName, NSUInteger idx, BOOL * _Nonnull stop)
	{
		SEL sel = NSSelectorFromString(selectorName);;
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(class_getInstanceMethod(self, sel))]];
		[inv setSelector:sel];
		[invocations addObject:inv];
	}];
	return invocations;
}

@end
