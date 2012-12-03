//
//  SuperJSTP.m
//  SuperDBCore
//
//  Created by Jason Brennan on 2012-10-05.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperJSTP.h"
#import "SuperNetworkMessageTypes.h"

#define kMessageSentTag 9000

NSString *const kContentLengthKey = @"Content-Length: ";

@implementation SuperJSTP


- (NSUInteger)contentLengthFromHeaderData:(NSData *)header {
	NSString *headerString = [[NSString alloc] initWithData:header encoding:NSUTF8StringEncoding];
	NSArray *headers = [headerString componentsSeparatedByString:kCRLF];
	
	for (NSString *header in headers) {
		NSRange keyRange = [header rangeOfString:kContentLengthKey];
		if (keyRange.location != NSNotFound) {
			return (NSUInteger)[[header substringFromIndex:NSMaxRange(keyRange)] integerValue];
		}
	}
	
	return -1;
}


- (NSData *)dataByProcessingJSTPBodyData:(NSData *)body {
	[NSException raise:@"[SuperJSTP processJSTPBodyData:] No implementation!! Subclass must implement this" format:@""];
	return nil;
}


- (NSData *)packetDataForMessage:(NSData *)messageData {
	NSString *contentLength = [NSString stringWithFormat:@"%@%lu", kContentLengthKey, (long unsigned)[messageData length]];
	NSString *headers = [NSString stringWithFormat:@"%@%@", contentLength, kCRLFCRLF];
	NSData *headerData = [headers dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableData *packet = [NSMutableData dataWithCapacity:([messageData length] + [headerData length])];
	[packet appendData:headerData];
	[packet appendData:messageData];
	
	
	return packet;
}


- (void)writeMessageData:(NSData *)data toSocket:(GCDAsyncSocket *)socket {
	NSData *packetData = [self packetDataForMessage:data];
	[socket writeData:packetData withTimeout:kNoTimeout tag:kMessageSentTag];
}


- (void)readOnSocketToHeaderSeparator:(GCDAsyncSocket *)socket {
	NSData *headerSeperator = [kCRLFCRLF dataUsingEncoding:NSUTF8StringEncoding];
	[socket readDataToData:headerSeperator withTimeout:kNoTimeout tag:kJSTPHeaderTag];
}


#pragma mark - GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	
	if (kJSTPHeaderTag == tag) {
		
		// Read in the header to figure out how many bytes ahead we have to read
		NSUInteger bodyLength = [self contentLengthFromHeaderData:data];
		[sock readDataToLength:bodyLength withTimeout:kNoTimeout tag:kJSTPBodyTag];
		
	} else if (kJSTPBodyTag == tag) {
		
		NSData *response = [self dataByProcessingJSTPBodyData:data];
		if (response) {
			[self writeMessageData:response toSocket:sock];
		}
		
		// enqueue a read for the next header
		[self readOnSocketToHeaderSeparator:sock];
	}
}


@end
