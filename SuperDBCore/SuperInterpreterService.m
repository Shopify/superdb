//
//  SuperInterpreterService.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperInterpreterService.h"
#import "GCDAsyncSocket.h"
//#import "SuperDBCore.h"
#import "JBServicesBrowser.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


@interface SuperInterpreterService () <GCDAsyncSocketDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) NSMutableArray *connectedClients;
@property (nonatomic, strong) SuperInterpreterServicePublishedServiceCallback publishedServiceCallback;
@property (nonatomic, strong) NSNetService *publishedService;
@end


@implementation SuperInterpreterService


- (id)init {
	if ((self = [super init])) {
		self.maximumConnectedClients = NSUIntegerMax;
	}
	
    return self;
}


#pragma mark - Public API

- (void)startServer {
	self.connectedClients = [@[] mutableCopy];
	
	self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	NSError *error = nil;
	if (![self.listenSocket acceptOnPort:DEFAULT_PORT error:&error]) {
		NSLog(@"Error starting the Server socket: %@", [error userInfo]);
		return;
	}
	
	NSLog(@"Server socket started");
	
}


- (void)stopServer {
	[self.connectedClients removeAllObjects];
	[self.listenSocket disconnect];
	self.listenSocket = nil;
}


- (void)publishServiceWithCallback:(SuperInterpreterServicePublishedServiceCallback)callback {
	self.publishedServiceCallback = callback;
	
	self.publishedService = [[NSNetService alloc] initWithDomain:[JBServicesBrowser netServiceDomain] type:[JBServicesBrowser netServiceName] name:[self serviceName] port:DEFAULT_PORT];
	
	if (nil ==  self.publishedService) {
		NSLog(@"There was an error publishing the network service.");
		self.publishedServiceCallback(nil, @{ @"reason" : @"The publication failed" });
		return;
	}
	
	[self.publishedService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[self.publishedService setDelegate:self];
	[self.publishedService publish];
}


- (NSString *)serviceName {
#if !TARGET_OS_IPHONE
	return [[NSHost currentHost] localizedName];
#elif TARGET_OS_IPHONE
	return [[UIDevice currentDevice] name];
#endif
}


#pragma mark - NSNetServiceDelegate methods

- (void)netServiceDidPublish:(NSNetService *)sender {
	self.publishedServiceCallback(@"The service was successfully published", nil);
}


- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	[self stopServer];
	//[self unpublishService];
	self.publishedServiceCallback(nil, errorDict);
}


#pragma mark - GCDAsyncSocketDelegate methods
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	
	NSLog(@"Server: Accepted new client socket.");
	
	if ([self.connectedClients count] <= self.maximumConnectedClients) {
		[self.connectedClients addObject:newSocket];
	} else {
		[newSocket disconnect];
	}
	
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
	if (sock != self.listenSocket) {
		NSLog(@"A client has disconnected");
		[self.connectedClients removeObject:sock];
	}
}


@end
