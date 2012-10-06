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


- (void)requestWithCommand:(NSString *)command input:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	NSString *messageResource = [SuperNetworkMessage messageResourceTypeForCommand:command];
	SuperNetworkMessage *message = [SuperNetworkMessage messageWithResource:messageResource body:@{ kSuperNetworkMessageBodyInputKey : input }];
	
	[self sendMessage:message responseHandler:responseHandler];
}


#pragma mark - Private API

- (void)sendMessage:(SuperNetworkMessage *)message responseHandler:(SuperInterpreterClientResponseHandler)responseHandler {
	
	// write the data
	NSData *packetData = [self packetDataForMessage:[message JSONData]];
	[self.clientSocket writeData:packetData withTimeout:kNoTimeout tag:kMessageSentTag];
	
	// Store the response handler and queue up a read
	
	[self.messageResponseHandlers setObject:[responseHandler copy] forKey:@(kJSTPBodyTag)];
	[self.clientSocket readDataWithTimeout:kNoTimeout tag:kJSTPHeaderTag];
}


- (NSData *)packetDataForMessage:(NSData *)messageData {
	NSString *contentLength = [NSString stringWithFormat:@"%@ %lu", @"Content-Length:", (long unsigned)[messageData length]];
	NSString *headers = [NSString stringWithFormat:@"%@%@", contentLength, kCRLFCRLF];
	NSData *headerData = [headers dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableData *packet = [NSMutableData dataWithCapacity:([messageData length] + [headerData length])];
	[packet appendData:headerData];
	[packet appendData:messageData];
	
	return packet;
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
	
	if (kJSTPHeaderTag == tag) {
		// Read in the header to figure out how many bytes ahead we have to read
		NSUInteger bodyLength = [self parseJSTPHeader:data];
		[sock readDataToLength:bodyLength withTimeout:kNoTimeout tag:kJSTPBodyTag];
	} else if (kJSTPBodyTag == tag) {
		
		[self processJSTPBodyData:data];
		
		// enqueue a read for the next header
		NSData *headerSeperator = [kCRLFCRLF dataUsingEncoding:NSUTF8StringEncoding];
		[sock readDataToData:headerSeperator withTimeout:kNoTimeout tag:kJSTPHeaderTag];
	}
	

}


- (NSUInteger)parseJSTPHeader:(NSData *)header {
	NSString *headerString = [[NSString alloc] initWithData:header encoding:NSUTF8StringEncoding];
	NSArray *headers = [headerString componentsSeparatedByString:@"\r\n"];
	
	for (NSString *header in headers) {
		NSRange keyRange = [header rangeOfString:@"Content-Lenght: "];
		if (keyRange.location != NSNotFound) {
			NSLog(@"Found content length header!");
			return (NSUInteger)[[header substringFromIndex:NSMaxRange(keyRange)] integerValue];
		}
	}
	
	return -1;
}


- (void)processJSTPBodyData:(NSData *)body {
	SuperInterpreterClientResponseHandler responseHandler = [self.messageResponseHandlers objectForKey:@(kJSTPBodyTag)];
	
	if (nil != responseHandler) {
		SuperNetworkMessage *message = [SuperNetworkMessage messageWithJSONData:body];
		[message log];
		
		// Remove the handler before we use it, to avoid any problems that might arrise if the handler itself sends a new message.
		[self.messageResponseHandlers removeObjectForKey:@(kJSTPBodyTag)];
		responseHandler(message);
		
	} else {
		NSLog(@"[CLIENT]: No client response handler to execute");
	}
}

@end
