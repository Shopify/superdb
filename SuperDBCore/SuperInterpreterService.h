//
//  SuperInterpreterService.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//
//  The main network service

#import <Foundation/Foundation.h>

@interface SuperInterpreterService : NSObject

- (void)startServer;
- (void)stopServer;

@end
