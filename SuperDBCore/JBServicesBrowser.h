//
//  JBServicesBrowser.h
//  Lecture12
//
//  Created by Jason Brennan on 12-03-22.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kIMServiceName;

typedef void(^JBServicesBrowserCallback)(id servicesFound, BOOL moreComing, NSDictionary *error);
typedef void(^JBServicesBrowserPublishedServiceCallback)(id success, NSDictionary *errorDictionary);

@interface JBServicesBrowser : NSObject

- (id)initWithServicesCallback:(JBServicesBrowserCallback)callback;
- (void)publishServiceForUsername:(NSString *)serviceName publicationCallback:(JBServicesBrowserPublishedServiceCallback)publicationCallback;

@end
