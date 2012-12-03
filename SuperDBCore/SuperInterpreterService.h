//
//  SuperInterpreterService.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//
//  The main network service

#import <Foundation/Foundation.h>
#import "SuperNetworkMessageTypes.h"
#import "SuperJSTP.h"

@class SuperInterpreterService;
@class SuperNetworkMessage;
@protocol SuperInterpreterServiceDelegate <NSObject>
@required
- (SuperNetworkMessage *)responseMessageByProcessingRequestMessage:(SuperNetworkMessage *)request;
@end


typedef void(^SuperInterpreterServicePublishedServiceCallback)(id success, NSDictionary *errorDictionary);


typedef id(^SuperInterpreterServiceUpdateSelfPointerBlock)(void);


@interface SuperInterpreterService : SuperJSTP

@property (nonatomic, assign) NSUInteger maximumConnectedClients; // defaults to NSUIntegerMax
@property (nonatomic, weak) id<SuperInterpreterServiceDelegate> delegate;
@property (nonatomic, copy) SuperInterpreterServiceUpdateSelfPointerBlock currentViewControllerBlock;

- (BOOL)startServer;
- (void)stopServer;

- (void)publishServiceWithCallback:(SuperInterpreterServicePublishedServiceCallback)callback;
- (NSString *)serviceName;


@end
