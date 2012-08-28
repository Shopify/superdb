//
//  SuperInterpreter.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-28.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperNetworkMessageTypes.h"

@class SuperNetworkMessage;

typedef SuperNetworkMessage *(^SuperInterpreterServiceRequestHandler)(SuperNetworkMessage *request);

@interface SuperInterpreter : NSObject
- (SuperNetworkMessage *)responseForRequest:(SuperNetworkMessage *)requestMessage;
@end
