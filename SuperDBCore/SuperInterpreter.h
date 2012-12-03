//
//  SuperInterpreter.h
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-28.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperNetworkMessageTypes.h"
#import "SuperInterpreterService.h"

@class SuperNetworkMessage;

@interface SuperInterpreter : NSObject

// This property gets executed when the client (Mac Shell) issues the `.self` command.
// It should return whatever object you'd like to have the `self` variable point to.
// Typically, you'd want this to return your current view controller for however your heirarchy is nested
@property (nonatomic, copy) SuperInterpreterServiceUpdateSelfPointerBlock currentSelfPointerBlock;

- (SuperNetworkMessage *)responseForRequest:(SuperNetworkMessage *)requestMessage;
@end
