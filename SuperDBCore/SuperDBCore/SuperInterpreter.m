//
//  SuperInterpreter.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-08-28.
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



//  This class is responsible for interfacing with the interpreter on the device.
//  It handles requests from the Server instance.


#import "SuperInterpreter.h"
#import "SuperNetworkMessage.h"
#import "FSInterpreter.h"
#import "FSMiscTools.h"
#import "SuperInterpreterObjectBrowser.h"
#import "Geometry.h"
#import "NSData+Base64.h"


#define kSuperDebuggerDeviceLogDefaultsKey @"org.superdb.device.log_settings"
#define USE_LOGGING [[NSUserDefaults standardUserDefaults] boolForKey:kSuperDebuggerDeviceLogDefaultsKey]

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
		[self setupInterpreterEnvironment];
    }
    return self;
}


- (void)guessProjectPrefix {
	// Get the app delegate, get its class name, then search that string until "App" is found.
	// The preceding substring could be the project prefix.
	// This will be useful for figuring out which classes (likely) belong to the given project.
	id application = nil;
#if !TARGET_OS_IPHONE
	application = [NSApplication sharedApplication];
#elif TARGET_OS_IPHONE
	application = [UIApplication sharedApplication];
#endif
	id delegate = [application delegate];
	NSString *delegateClassName = NSStringFromClass([delegate class]);
	NSRange appDelegateRange = [delegateClassName rangeOfString:@"App"];
	
	if (appDelegateRange.location != NSNotFound) {
		self.projectPrefix = [delegateClassName substringToIndex:appDelegateRange.location];
	}
	
	NSLog(@"The Project prefix is guessed to be: %@", self.projectPrefix);
}


- (void)setupInterpreterEnvironment {
	FSInterpreterResult *result = [self.interpreter execute:@"del := UIApplication sharedApplication delegate"];
	if (![result isOK]) {
		NSLog(@"ERROR setting up environment: %@", [result errorMessage]);
	}
	
	[self.interpreter setObject:nil forIdentifier:@"self"];
	
	// Add custom classes to the environment
	[self.interpreter setObject:[Geometry class] forIdentifier:NSStringFromClass([Geometry class])];
	
	
	// Enable logging by default
	if ([[NSUserDefaults standardUserDefaults] objectForKey:kSuperDebuggerDeviceLogDefaultsKey] == nil) {
		NSLog(@"[SuperDB]: Enabling device-side logs of interpreter input+output. These are stored in the defaults. To turn off, use `.logging off`");
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSuperDebuggerDeviceLogDefaultsKey];
	}
}


- (void)setCurrentSelfPointerBlock:(SuperInterpreterServiceUpdateSelfPointerBlock)currentSelfPointerBlock {
	if (_currentSelfPointerBlock == currentSelfPointerBlock)
		return;
	
	_currentSelfPointerBlock = [currentSelfPointerBlock copy];
	
	if (_currentSelfPointerBlock == nil)
		return;
	
	// Automatically set up the environment to have a pointer to `self` which executes the block passed in, automatically.
	
	id newSelf = _currentSelfPointerBlock();
	
	[self.interpreter setObject:newSelf forIdentifier:@"self"];
}


- (void)setupResponseHandlers {
	self.requestHandlers = [@{} mutableCopy];
	
	__weak __typeof__(self) weakSelf = self;
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceInterpreter requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:USE_LOGGING];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		
		if ([result isOK]) {
			NSLog(@"FSOK: %@", [result result]);
			
			if (nil == [result result]) {
				NSLog(@"[ERROR]: [result result] was nil... result is: %@", result);
				[body setObject:@"Empty result. This usually means you sent a message to a nil pointer." forKey:kSuperNetworkMessageBodyOutputKey];
			} else {
				[body setObject:[[result result] description] forKey:kSuperNetworkMessageBodyOutputKey];
			}
			
			[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
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
		if ([weakSelf.projectPrefix length])
			classList = [classList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF like[c] %@", [NSString stringWithFormat:@"%@*", self.projectPrefix]]];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
		[body setObject:classList forKey:kSuperNetworkMessageBodyOutputKey];
		
		
		SuperNetworkMessage *response = [SuperNetworkMessage messageWithHeader:request.header body:body];
		return response;

	}];
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceImageData
                        requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
                            
         NSMutableDictionary *body = [@{} mutableCopy];
         NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
         
         FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:USE_LOGGING];
         
         NSLog(@"[SERVER]: Transfering data for image: %@", input);
         
         if ([result isOK]) {
             NSLog(@"FSOK: %@", [result result]);
             
#if TARGET_OS_IPHONE
             id object = [result result];
             if ([object isKindOfClass:[UIImage class]]) {
                 
                 NSData *imgRep = UIImageJPEGRepresentation(object, 0.8);
                 [body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
                 [body setObject:[imgRep base64EncodedString] forKey:kSuperNetworkMessageBodyOutputKey];
             } else {
                 NSString *noImageError = @"The result is not an image.";
                 [body setObject:kSuperNetworkMessageBodyStatusError forKey:kSuperNetworkMessageBodyStatusKey];
                 [body setObject:noImageError forKey:kSuperNetworkMessageBodyErrorMessageKey];
                 
                 NSRange range = NSMakeRange(0, 1);
                 [body setObject:NSStringFromRange(range) forKey:kSuperNetworkMessageBodyErrorRange];
             }
#else
             [body setObject:kSuperNetworkMessageBodyStatusError forKey:kSuperNetworkMessageBodyStatusKey];
#endif
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
    
	[self addRequestHandlerForResource:kSuperNetworkMessageResourcePropertyList requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSMutableDictionary *body = [@{} mutableCopy];
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		SuperInterpreterObjectBrowser *objectBrowser = [SuperInterpreterObjectBrowser new];
		
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:USE_LOGGING];
		
		
		NSLog(@"[SERVER]: Loading properties for input: %@", input);
		
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
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceMethodList requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSMutableDictionary *body = [@{} mutableCopy];
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		SuperInterpreterObjectBrowser *objectBrowser = [SuperInterpreterObjectBrowser new];
		
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:USE_LOGGING];
		
		
		NSLog(@"[SERVER]: Loading methods for input: %@", input);
		
		if ([result isOK]) {
			NSLog(@"FSOK: %@", [result result]);
			id object = [result result];
			NSArray *properties = [objectBrowser methodsForObject:object];
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
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceUpdateCurrentSelfPointer requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSLog(@"[SERVER]: Updating the current view controller.");
		NSMutableDictionary *body = [@{} mutableCopy];
#if !TARGET_OS_IPHONE
		id newSelf = [[NSApplication sharedApplication] delegate];
#elif TARGET_OS_IPHONE
		// Defaults to the window's rootViewController
		id newSelf = [[[UIApplication sharedApplication] keyWindow] rootViewController];
#endif
		if (weakSelf.currentSelfPointerBlock) {
			newSelf = weakSelf.currentSelfPointerBlock();
		}
		
		// Assign this view controller in the environment
		[weakSelf.interpreter setObject:newSelf forIdentifier:@"self"];
		
		// Evaluate self and get the result to be returned to the client
		// Sure, could just pass in the actual view controller, but I'd rather hear it straight from the interpreter.
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:@"self" logResult:USE_LOGGING];
		if ([result isOK]) {
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
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceDeviceLoggingSettings requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		
		BOOL shouldSet = NO;
		if ([input compare:@"on" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			shouldSet = YES;
		}
		[[NSUserDefaults standardUserDefaults] setBool:shouldSet forKey:kSuperDebuggerDeviceLogDefaultsKey];
		NSString *output = [NSString stringWithFormat:@"Device logging is %@.", shouldSet? @"on" : @"off"];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
		[body setObject:output forKey:kSuperNetworkMessageBodyOutputKey];
		
		
		SuperNetworkMessage *response = [SuperNetworkMessage messageWithHeader:request.header body:body];
		return response;
	}];
}


- (FSInterpreterResult *)interpreterResultForInput:(NSString *)input logResult:(BOOL)shouldLog {
	FSInterpreterResult *result = [self.interpreter execute:input];
	
	if (shouldLog) {
		NSCalendar *cal = [NSCalendar currentCalendar];
		
		NSDate *date = [NSDate date];
		NSDateComponents *comps = [cal components:(NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
										 fromDate:date];
		NSDate *today = [cal dateFromComponents:comps];
		NSString *logKey = [today description];
		
		NSString *logForToday = [[NSUserDefaults standardUserDefaults] stringForKey:logKey];
		if (!logForToday) {
			logForToday = @"";
		}
		
		NSString *resultString = [result isOK]? [result result] : [result errorMessage];
		NSString *newLog = [NSString stringWithFormat:@"%@\n%@", logForToday, resultString];
		[[NSUserDefaults standardUserDefaults] setValue:newLog forKey:logKey];
	}
	
	return result;
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
