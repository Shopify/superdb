//
//  SuperInterpreterClient.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperInterpreterClient.h"
#import "GCDAsyncSocket.h"
#import "SuperNetworkMessage.h"


@interface SuperInterpreterClient () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSData *hostData;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, copy) SuperInterpreterClientResponseHandler connectionResponseHandler;
@end


@implementation SuperInterpreterClient


- (id)initWithHostData:(NSData *)hostData {
	if ((self = [super init])) {
		self.hostData = hostData;
		
		self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	
    return self;
}


- (void)startNetworkConnectionWithResponseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	self.connectionResponseHandler = [responseHandler copy];
	
	NSError *error = nil;
	if (![self.clientSocket connectToAddress:self.hostData error:&error]) {
		NSLog(@"Client: Could not connect to server: %@", [error userInfo]);
		return;
	}
	
	
}


#pragma mark - GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
	NSLog(@"[CLIENT]: Connected to the Server");
	
	
	// Send the handshake message
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	
}

@end
