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
	Class class = [self classOrMetaClassForObject:object];
	
	while (class) {
		NSUInteger propertyCount, index;
		objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
		
		if (NULL != properties) {
			
			for (index = 0; index < propertyCount; index++) {
				NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[index])];
				NSLog(@"Adding property for class: %@ %@", NSStringFromClass(class), propertyName);
				// Property value, currently ignored (might want to use these some day, and instead return a dictionary
				//id propertyValue = [object valueForKey:propertyName];
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
	return allProperties;
}


- (Class)classOrMetaClassForObject:object {
	return object_getClass(object);
}

@end
