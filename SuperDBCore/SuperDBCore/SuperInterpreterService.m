//
//  SuperInterpreterService.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//
//  Copyright (c) 2012-2013, Shopify, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Shopify, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL Shopify, Inc. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SuperInterpreterService.h"
#import "GCDAsyncSocket.h"
#import "SuperServicesBrowser.h"
#import "SuperNetworkMessage.h"
#import "SuperInterpreter.h"


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define kClientSocketReadTag 8000
#define kClientSocketWriteTag 8001


@interface SuperInterpreterService () <GCDAsyncSocketDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) NSMutableArray *connectedClients;
@property (nonatomic, strong) SuperInterpreterServicePublishedServiceCallback publishedServiceCallback;
@property (nonatomic, strong) NSNetService *publishedService;
@property (nonatomic, strong) SuperInterpreter *interpreter;

@end


@implementation SuperInterpreterService


- (id)init {
	if ((self = [super init])) {
		self.maximumConnectedClients = NSUIntegerMax;
		self.interpreter = [SuperInterpreter new];
	}
	
    return self;
}


- (void)setCurrentSelfPointerBlock:(SuperInterpreterServiceUpdateSelfPointerBlock)currentSelfPointerBlock {
	self.interpreter.currentSelfPointerBlock = currentSelfPointerBlock;
}


- (SuperInterpreterServiceUpdateSelfPointerBlock)currentSelfPointerBlock {
	return self.interpreter.currentSelfPointerBlock;
}


#pragma mark - Public API

- (BOOL)startServer {
	
	self.connectedClients = [@[] mutableCopy];
	
	
	self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	NSError *error = nil;
	if (![self.listenSocket acceptOnPort:DEFAULT_PORT error:&error]) {
		NSLog(@"Error starting the Server socket: %@", [error userInfo]);
		return NO;
	}
	
	NSLog(@"Server socket started.");
	return YES;
}


- (void)stopServer {
	[self.connectedClients removeAllObjects];
	[self.listenSocket disconnect];
	self.listenSocket = nil;
}


- (void)publishServiceWithCallback:(SuperInterpreterServicePublishedServiceCallback)callback {
	self.publishedServiceCallback = callback;
	
	self.publishedService = [[NSNetService alloc] initWithDomain:[SuperServicesBrowser netServiceDomain]
															type:[SuperServicesBrowser netServiceType]
															name:[self serviceName]
															port:DEFAULT_PORT];
	
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
	return [NSString stringWithFormat:@"%@: %@",[[UIDevice currentDevice] name], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
;
#endif
}


- (void)writeResponse:(SuperNetworkMessage *)response toClient:(GCDAsyncSocket *)clientSocket {
	[self writeMessageData:[response JSONData] toSocket:clientSocket];
}


#pragma mark - NSNetServiceDelegate methods

- (void)netServiceDidPublish:(NSNetService *)sender {
	self.publishedServiceCallback(@"The service was successfully published", nil);
}


- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	[self stopServer];
	self.publishedServiceCallback(nil, errorDict);
}


#pragma mark - GCDAsyncSocketDelegate methods
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	
	NSLog(@"Server: Accepted new client socketoooooooo2.");
	
	[self.connectedClients addObject:newSocket];
	NSLog(@"Server: Reading from new client socket.");
	
	[self readOnSocketToHeaderSeparator:newSocket];
	
}


- (NSData *)dataByProcessingJSTPBodyData:(NSData *)body {
	NSLog(@"[SERVER]: Going to read socket data!");
	
	// Read the object
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithJSONData:body];
	
	SuperNetworkMessage *response = nil;
	if ([message messageType] == SuperNetworkMessageTypeRequestResponse) {
		
		response = [self.interpreter responseForRequest:message];
		
	} else {
//		// Let the delegate process the message and return a response
//		NSLog(@"[SERVER]: Going to let the delegate try...");
//		response = [self.delegate responseMessageByProcessingRequestMessage:message];
		response = [SuperNetworkMessage messageWithType:SuperNetworkMessageTypeHandshake body:@{ @"debug" : @"OK" }];
	}
	
	return [response JSONData];
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"[SERVER]: Socket did WRITE data with tag: %lu", tag);
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
	if (sock != self.listenSocket) {
		NSLog(@"A client has disconnected");
		[self.connectedClients removeObject:sock];
	}
}


@end
