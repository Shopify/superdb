//
//  SuperNetworkMessage.h
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

/*
 The messages in this system work a lot like HTTP in that they are Request+Response based.
 
 Some key points:
 
 - Every request is matched with a response.
 - The format for both sides is JSON, not HTML
 - Like HTTP, each message has a set of CRLF delimited headers. Currently the only one supported is `Content-Length:`
 - Essentially every transmission can be considered a POST in that an object can be sent in any request. OR the body could be empty.
 - No PUSH from the Server (i.e., no unsolicited responses)
 
*/


#import <Foundation/Foundation.h>
#import "SuperNetworkMessageTypes.h"


@interface SuperNetworkMessage : NSObject
@property (nonatomic, strong) NSDictionary *header;
@property (nonatomic, strong) NSDictionary *body;


+ (id)messageWithHeader:(NSDictionary *)header body:(NSDictionary *)body;
+ (id)messageWithJSONData:(NSData *)data;
- (NSData *)JSONData;
- (void)log;

- (SuperNetworkMessageType)messageType;
- (NSString *)resource;


// Specialized methods
+ (instancetype)messageWithType:(SuperNetworkMessageType)messageType body:(NSDictionary *)body;
+ (instancetype)messageWithResource:(NSString *)resource body:(NSDictionary *)body;

+ (NSString *)messageResourceTypeForCommand:(NSString *)command;

@end
