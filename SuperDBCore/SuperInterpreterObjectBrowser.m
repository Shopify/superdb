//
//  SuperInterpreterObjectBrowser.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-31.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperInterpreterObjectBrowser.h"
#import "FSNSObject.h"
#include <objc/runtime.h>


@implementation SuperInterpreterObjectBrowser

- (NSArray *)propertiesForObject:(id)object {
	NSMutableArray *allProperties = [@[] mutableCopy];
	Class class = [object classOrMetaclass];
	
	while (class) {
		NSUInteger classCount, index;
		objc_property_t *properties = class_copyPropertyList(class, &classCount);
		
		if (NULL != properties) {
			
			for (index = 0; index < classCount; index++) {
				NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[index])];
				
				// Property value, currently ignored (might want to use these some day, and instead return a dictionary
				id propertyValue = [object valueForKey:propertyName];
				[allProperties addObject:propertyName];
			}
			
			free(properties);
		}
		if (class == [class superclass]) {
			class = nil; // Apparently some object hierarchies return self from that method, for the root object, instead of nil
		} else {
			class = [class superclass];
		}
	}
}

@end
