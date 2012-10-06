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
#import "SuperNetworkMessageTypes.h"

#define kIdentifierLimit 5000


@interface SuperInterpreterClient () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSData *hostData;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, copy) SuperInterpreterClientResponseHandler connectionResponseHandler;
@property (nonatomic, strong) NSMutableArray *messageResponseHandlerQueue;
@end


@implementation SuperInterpreterClient


- (id)initWithHostData:(NSData *)hostData {
	if ((self = [super init])) {
		self.hostData = hostData;
		self.messageResponseHandlerQueue = [@[] mutableCopy];
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



- (void)requestWithStringToEvaluate:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithResource:kSuperNetworkMessageResourceInterpreter body:@{ kSuperNetworkMessageBodyInputKey : input }];
	
	[self sendMessage:message responseHandler:responseHandler];
}


- (void)requestWithCommand:(NSString *)command input:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	NSString *messageResource = [SuperNetworkMessage messageResourceTypeForCommand:command];
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithResource:messageResource body:@{ kSuperNetworkMessageBodyInputKey : input }];
	
	[self sendMessage:message responseHandler:responseHandler];
}


#pragma mark - Queue methods

- (void)enqueueResponseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	[self.messageResponseHandlerQueue insertObject:[responseHandler copy] atIndex:0];
}


- (SuperInterpreterClientResponseHandler)dequeueResponseHandler {
	id dequeued = [self.messageResponseHandlerQueue lastObject];
	[self.messageResponseHandlerQueue removeLastObject];
	return dequeued;
}


#pragma mark - Private API

- (void)sendMessage:(SuperNetworkMessage *)message responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	
	// write the data
	[self writeMessageData:[message JSONData] toSocket:self.clientSocket];
	
	// Store the response handler and queue up a read
	[self enqueueResponseHandler:responseHandler];

	[self.clientSocket readDataWithTimeout:kNoTimeout tag:kJSTPHeaderTag];
}



#pragma mark - GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
	NSLog(@"[CLIENT]: Connected to the Server");
	
	
	// Send the handshake message
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithType:SuperNetworkMessageTypeHandshake body:@{}];
	[self sendMessage:message responseHandler:self.connectionResponseHandler];
}


- (NSData *)dataByProcessingJSTPBodyData:(NSData *)body {
	SuperInterpreterClientResponseHandler responseHandler = [self dequeueResponseHandler];
	
	if (nil != responseHandler) {
		SuperNetworkMessage *message = [SuperNetworkMessage messageWithJSONData:body];
		[message log];
		responseHandler(message);
		
	} else {
		NSLog(@"[CLIENT]: No client response handler to execute");
	}
	
	return nil;
}

@end
