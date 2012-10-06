//
//  SuperInterpreterService.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperInterpreterService.h"
#import "GCDAsyncSocket.h"
#import "JBServicesBrowser.h"
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

- (void)writeResponse:(SuperNetworkMessage *)response toClient:(GCDAsyncSocket *)clientSocket;

@end


@implementation SuperInterpreterService


- (id)init {
	if ((self = [super init])) {
		self.maximumConnectedClients = NSUIntegerMax;
	}
	
    return self;
}


#pragma mark - Public API

- (BOOL)startServer {
	
	if (nil == self.delegate) {
		NSLog(@"Delegate cannot be nil! Aborting");
		abort();
	}
	
	self.connectedClients = [@[] mutableCopy];
	
	dispatch_queue_t d = dispatch_get_main_queue();
	
	if (NULL == d) {
		NSLog(@"the dispatch q was null?");
		return NO;
	}
	
	self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	NSError *error = nil;
	if (![self.listenSocket acceptOnPort:DEFAULT_PORT error:&error]) {
		NSLog(@"Error starting the Server socket: %@", [error userInfo]);
		return NO;
	}
	
	NSLog(@"Server socket started..........");
	return YES;
}


- (void)stopServer {
	[self.connectedClients removeAllObjects];
	[self.listenSocket disconnect];
	self.listenSocket = nil;
}


- (void)publishServiceWithCallback:(SuperInterpreterServicePublishedServiceCallback)callback {
	self.publishedServiceCallback = callback;
	
	self.publishedService = [[NSNetService alloc] initWithDomain:[JBServicesBrowser netServiceDomain]
															type:[JBServicesBrowser netServiceType]
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
	self.interpreter = [SuperInterpreter new];
	self.publishedServiceCallback(@"The service was successfully published", nil);
}


- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	[self stopServer];
	//[self unpublishService];
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
		// Let the delegate process the message and return a response
		NSLog(@"[SERVER]: Going to let the delegate try...");
		response = [self.delegate responseMessageByProcessingRequestMessage:message];
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
