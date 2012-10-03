//
//  SuperInterpreterObjectBrowser.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-31.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuperInterpreterObjectBrowser : NSObject
- (NSArray *)propertiesForObject:(id)object;
- (NSArray *)methodsForObject:(id)object; // `object` could be a Class, too.
@end
