//
//  SuperInterpreterClient.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
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
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"[CLIENT]: Did write data with tag: %ld", tag);
}



#pragma mark - GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
	NSLog(@"[CLIENT]: Connected to the Server");
	
	
	// Send the handshake message
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithType:SuperNetworkMessageTypeHandshake body:@{}];
	[self sendMessage:message responseHandler:self.connectionResponseHandler];
	[self readOnSocketToHeaderSeparator:self.clientSocket];
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
