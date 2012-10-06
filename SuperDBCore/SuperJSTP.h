//
//  SuperJSTP.h
//  SuperDBCore
//
//  Created by Jason Brennan on 2012-10-05.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface SuperJSTP : NSObject <GCDAsyncSocketDelegate>

- (NSUInteger)contentLengthFromHeaderData:(NSData *)header;
- (void)processJSTPBodyData:(NSData *)body;
- (NSData *)packetDataForMessage:(NSData *)messageData;
- (void)writeMessageData:(NSData *)data toSocket:(GCDAsyncSocket *)socket;

@end
