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

#define kIdentifierLimit 5000
#define kMessageSentTag 9000

@interface SuperInterpreterClient () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) NSData *hostData;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, copy) SuperInterpreterClientResponseHandler connectionResponseHandler;
@property (nonatomic, strong) NSMutableDictionary *messageResponseHandlers;
@end


@implementation SuperInterpreterClient


- (id)initWithHostData:(NSData *)hostData {
	if ((self = [super init])) {
		self.hostData = hostData;
		self.messageResponseHandlers = [@{} mutableCopy];
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


- (void)requestWithSymbolForProperties:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithResource:kSuperNetworkMessageResourcePropertyList body:@{ kSuperNetworkMessageBodyInputKey : input }];
	
	[self sendMessage:message responseHandler:responseHandler];
}


#pragma mark - Private API

- (void)sendMessage:(SuperNetworkMessage *)message responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	
	// write the data
	[self.clientSocket writeData:[message JSONData] withTimeout:-1 tag:kMessageSentTag];
	
	// Store the response handler and queue up a read
	long identifierTag = arc4random() % kIdentifierLimit;
	[self.messageResponseHandlers setObject:[responseHandler copy] forKey:@(identifierTag)];
	[self.clientSocket readDataWithTimeout:-1 tag:identifierTag];
	NSLog(@"[CLIENT] Writing message of type: %@ with identifier tag: %lu", [message header], identifierTag);
}


#pragma mark - GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
	NSLog(@"[CLIENT]: Connected to the Server");
	
	
	// Send the handshake message
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithType:SuperNetworkMessageTypeHandshake body:@{}];
	[self sendMessage:message responseHandler:self.connectionResponseHandler];
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"[CLIENT] Read message with identifier tag: %lu", tag);
	
	
	SuperInterpreterClientResponseHandler responseHandler = [self.messageResponseHandlers objectForKey:@(tag)];
	
	if (nil != responseHandler) {
		SuperNetworkMessage *message = [SuperNetworkMessage messageWithJSONData:data];
		[message log];
		responseHandler(message);
		[self.messageResponseHandlers removeObjectForKey:@(tag)];
	} else {
		NSLog(@"[CLIENT]: No client response handler to execute");
	}
}

@end
