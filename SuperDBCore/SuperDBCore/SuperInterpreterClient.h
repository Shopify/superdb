//
//  SuperInterpreterClient.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperJSTP.h"


@class SuperNetworkMessage;
typedef void(^SuperInterpreterClientResponseHandler)(SuperNetworkMessage *response);

@interface SuperInterpreterClient : SuperJSTP

- (id)initWithHostData:(NSData *)hostData;
- (void)startNetworkConnectionWithResponseHandler:(SuperInterpreterClientResponseHandler)responseHandler;

- (void)requestWithStringToEvaluate:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler;
- (void)requestWithCommand:(NSString *)command input:(NSString *)input responseHandler:(SuperInterpreterClientResponseHandler)responseHandler;

@end
