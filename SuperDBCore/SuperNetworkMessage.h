//
//  SuperNetworkMessage.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

/*
 The messages in this system work a lot like HTTP in that they are Request+Response based.
 
 Some key points:
 
 - Every request is matched with a response.
 - The format for both sides is JSON, not HTML
 - The headers are included in the JSON object.
 - Essentially every transmission can be considered a POST in that an object can be sent in any request. OR the body could be empty.
 - No PUSH from the Server (i.e., no unsolicited responses)
 
*/


#import <Foundation/Foundation.h>

typedef enum {
	SuperNetworkMessageTypeHandshake,
	SuperNetworkMessageTypeRequestResponse
} SuperNetworkMessageType;


extern NSString *kSuperNetworkMessageBodyStatusKey;
extern NSString *kSuperNetworkMessageBodyStatusOK;
extern NSString *kSuperNetworkMessageBodyStatusError;
extern NSString *kSuperNetworkMessageBodyErrorMessage;
extern NSString *kSuperNetworkMessageBodyErrorRange;
extern NSString *kSuperNetworkMessageBodyInputKey;
extern NSString *kSuperNetworkMessageBodyOutputKey;

extern NSString *kSuperNetworkMessageResourceInterpreter;
extern NSString *kSuperNetworkMessageResourceSymbolTable;

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

@end
