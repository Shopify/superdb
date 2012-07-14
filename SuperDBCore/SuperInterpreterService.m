//
//  SuperInterpreterService.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-13.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperInterpreterService.h"
#import "GCDAsyncSocket.h"
#import "SuperDBCore.h"


@interface SuperInterpreterService () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) NSMutableArray *connectedClients;
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
