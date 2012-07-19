//
//  SuperNetworkMessage.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	SuperNetworkMessageTypeHandshake
} SuperNetworkMessageType;

@interface SuperNetworkMessage : NSObject
@property (nonatomic, strong) NSDictionary *header;
@property (nonatomic, strong) NSDictionary *body;


+ (id)messageWithHeader:(NSDictionary *)header body:(NSDictionary *)body;
+ (id)messageWithJSONData:(NSData *)data;
- (NSData *)JSONData;
- (void)log;


// Specialized methods
+ (instancetype)messageWithType:(SuperNetworkMessageType)messageType body:(NSDictionary *)body;

@end
