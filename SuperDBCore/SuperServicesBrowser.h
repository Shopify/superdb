//
//  SuperServicesBrowser.h
//  
//
//  Created by Jason Brennan on 12-03-22.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_PORT 4789 // "For Seven ate Nine"

typedef void(^SuperServicesBrowserCallback)(id servicesFound, BOOL moreComing, NSDictionary *error);
typedef void(^SuperServicesBrowserPublishedServiceCallback)(id success, NSDictionary *errorDictionary);

@interface SuperServicesBrowser : NSObject

- (id)initWithServicesCallback:(SuperServicesBrowserCallback)callback;

+ (NSString *)netServiceType;
+ (NSString *)netServiceDomain;



@end
