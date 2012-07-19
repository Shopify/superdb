//
//  SuperInterpreterService.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//
//  The main network service

#import <Foundation/Foundation.h>

@class SuperInterpreterService;
@class SuperNetworkMessage;
@protocol SuperInterpreterServiceDelegate <NSObject>
@required
- (SuperNetworkMessage *)responseMessageByProcessingRequestMessage:(SuperNetworkMessage *)request;
@end


typedef void(^SuperInterpreterServicePublishedServiceCallback)(id success, NSDictionary *errorDictionary);
typedef SuperNetworkMessage *(^SuperInterpreterServiceRequestHandler)(SuperNetworkMessage *request);

@interface SuperInterpreterService : NSObject

@property (nonatomic, assign) NSUInteger maximumConnectedClients; // defaults to NSUIntegerMax
@property (nonatomic, weak) id<SuperInterpreterServiceDelegate> delegate;

- (BOOL)startServer;
- (void)stopServer;

- (void)publishServiceWithCallback:(SuperInterpreterServicePublishedServiceCallback)callback;
- (NSString *)serviceName;

- (void)addRequestHandlerForResource:(NSString *)resource requestHandler:(SuperInterpreterServiceRequestHandler)requestHandler;

@end
