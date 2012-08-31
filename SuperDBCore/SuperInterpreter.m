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
#import "FSInterpreter.h"
#import "FSMiscTools.h"
#import "SuperInterpreterObjectBrowser.h"


@interface SuperInterpreter ()
@property (nonatomic, strong) NSMutableDictionary *requestHandlers;
@property (nonatomic, strong) FSInterpreter *interpreter;
@property (nonatomic, strong) NSString *projectPrefix;
@end

@implementation SuperInterpreter


- (id)init {
    self = [super init];
    if (self) {
		self.interpreter = [[FSInterpreter alloc] init];
		[self guessProjectPrefix];
        [self setupResponseHandlers];
    }
    return self;
}


- (void)guessProjectPrefix {
	// Get the app delegate, get its class name, then search that string until "App" is found.
	// The preceding substring could be the project prefix.
	// This will be useful for figuring out which classes (likely) belong to the given project.
}


- (void)setupResponseHandlers {
	self.requestHandlers = [@{} mutableCopy];
	
	__weak __typeof__(self) weakSelf = self;
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceInterpreter requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		FSInterpreterResult *result = [weakSelf.interpreter execute:input];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		
		if ([result isOK]) {
			NSLog(@"FSOK: %@", [result result]);
			[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
			[body setObject:[[result result] description] forKey:kSuperNetworkMessageBodyOutputKey];
		} else {
			NSLog(@"FSBAD: %@", [result errorMessage]);
			[body setObject:kSuperNetworkMessageBodyStatusError forKey:kSuperNetworkMessageBodyStatusKey];
			[body setObject:[result errorMessage] forKey:kSuperNetworkMessageBodyErrorMessageKey];
			
			NSRange range = [result errorRange];
			[body setObject:NSStringFromRange(range) forKey:kSuperNetworkMessageBodyErrorRange];
		}
		
		SuperNetworkMessage *response = [SuperNetworkMessage messageWithHeader:request.header body:body];
		return response;
	}];
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceSymbolTable requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		
		
		return nil;
	}];
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceClassList requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSArray *classList = classNames();
		return nil;
	}];
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourcePropertyList requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSMutableDictionary *body = [@{} mutableCopy];
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		SuperInterpreterObjectBrowser *objectBrowser = [SuperInterpreterObjectBrowser new];
		
		FSInterpreterResult *result = [weakSelf.interpreter execute:input];
		
		
		
		
		if ([result isOK]) {
			NSLog(@"FSOK: %@", [result result]);
			id object = [result result];
			NSArray *properties = [objectBrowser propertiesForObject:object];
			[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
			[body setObject:properties forKey:kSuperNetworkMessageBodyOutputKey];
		} else {
			NSLog(@"FSBAD: %@", [result errorMessage]);
			[body setObject:kSuperNetworkMessageBodyStatusError forKey:kSuperNetworkMessageBodyStatusKey];
			[body setObject:[result errorMessage] forKey:kSuperNetworkMessageBodyErrorMessageKey];
			
			NSRange range = [result errorRange];
			[body setObject:NSStringFromRange(range) forKey:kSuperNetworkMessageBodyErrorRange];
		}
		
		SuperNetworkMessage *response = [SuperNetworkMessage messageWithHeader:request.header body:body];
		return response;
	}];
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
