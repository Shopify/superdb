//
//  SuperJSTP.m
//  SuperDBCore
//
//  Created by Jason Brennan on 2012-10-05.
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
	NSLog(@"[JSTP]: READ TAG: %lu", tag);
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
