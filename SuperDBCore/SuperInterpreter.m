//
//  SuperInterpreter.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-28.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//
//  This class is responsible for interfacing with the interpreter on the device.
//  It handles requests from the Server instance.


#import "SuperInterpreter.h"
#import "SuperNetworkMessage.h"

@interface SuperInterpreter ()
@property (nonatomic, strong) NSMutableDictionary *requestHandlers;
@end

@implementation SuperInterpreter


- (id)init {
    self = [super init];
    if (self) {
        [self setupResponseHandlers];
    }
    return self;
}


- (void)setupResponseHandlers {
	self.requestHandlers = [@{} mutableCopy];
	
	
}


- (void)addRequestHandlerForResource:(NSString *)resource requestHandler:(SuperInterpreterServiceRequestHandler)requestHandler {
	if (nil == requestHandler) {
		NSLog(@"Attempted to add a nil request handler for resource: %@", resource);
		return;
	}
	
	
	[self.requestHandlers setObject:[requestHandler copy] forKey:resource];
}


- (SuperNetworkMessage *)responseForRequest:(SuperNetworkMessage *)requestMessage; {
	
	SuperInterpreterServiceRequestHandler handler = [self.requestHandlers objectForKey:[requestMessage resource]];
	SuperNetworkMessage *response = nil;
	
	if (nil != handler) {
		response = handler(requestMessage);
	} else {
		NSLog(@"[INTERPRETER]: No handler for the resource: %@", [requestMessage resource]);
	}
	
	return response;
}

@end
