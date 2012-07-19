//
//  SuperInterpreterClient.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuperInterpreterClientResponseHandler)(id response);

@interface SuperInterpreterClient : NSObject
- (id)initWithHostData:(NSData *)hostData;
- (void)startNetworkConnectionWithResponseHandler:(SuperInterpreterClientResponseHandler)responseHandler;
@end
