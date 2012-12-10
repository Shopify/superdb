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
#import "Geometry.h"


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
	
	// Add custom classes to the environment
	[self.interpreter setObject:[Geometry class] forIdentifier:NSStringFromClass([Geometry class])];
}


- (void)setupResponseHandlers {
	self.requestHandlers = [@{} mutableCopy];
	
	__weak __typeof__(self) weakSelf = self;
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceInterpreter requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:YES];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		
		if ([result isOK]) {
			NSLog(@"FSOK: %@", [result result]);
			
			if (nil == [result result]) {
				NSLog(@"[ERROR]: [result result] was nil... result is: %@", result);
				[body setObject:@"Empty result. This usually means you sent a message to the wrong view controller. Try calling `.self` and trying again." forKey:kSuperNetworkMessageBodyOutputKey];
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
		if ([self.projectPrefix length])
			classList = [classList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF like[c] %@", [NSString stringWithFormat:@"%@*", self.projectPrefix]]];
		
		NSMutableDictionary *body = [@{} mutableCopy];
		
		[body setObject:kSuperNetworkMessageBodyStatusOK forKey:kSuperNetworkMessageBodyStatusKey];
		[body setObject:classList forKey:kSuperNetworkMessageBodyOutputKey];
		
		
		SuperNetworkMessage *response = [SuperNetworkMessage messageWithHeader:request.header body:body];
		return response;

	}];
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourcePropertyList requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSMutableDictionary *body = [@{} mutableCopy];
		NSString *input = [[request body] objectForKey:kSuperNetworkMessageBodyInputKey];
		SuperInterpreterObjectBrowser *objectBrowser = [SuperInterpreterObjectBrowser new];
		
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:YES];
		
		
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
		
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:input logResult:YES];
		
		
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
	
	
	[self addRequestHandlerForResource:kSuperNetworkMessageResourceUpdateCurrentViewController requestHandler:^SuperNetworkMessage *(SuperNetworkMessage *request) {
		NSLog(@"[SERVER]: Updating the current view controller.");
		NSMutableDictionary *body = [@{} mutableCopy];
#if !TARGET_OS_IPHONE
		id newSelf = [[NSApplication sharedApplication] delegate];
#elif TARGET_OS_IPHONE
		// Defaults to the window's rootViewController
		id newSelf = [[[UIApplication sharedApplication] keyWindow] rootViewController];
#endif
		if (self.currentSelfPointerBlock) {
			newSelf = self.currentSelfPointerBlock();
		}
		
		// Assign this view controller in the environment
		[weakSelf.interpreter setObject:newSelf forIdentifier:@"self"];
		
		// Evaluate self and get the result to be returned to the client
		// Sure, could just pass in the actual view controller, but I'd rather hear it straight from the interpreter.
		FSInterpreterResult *result = [weakSelf interpreterResultForInput:@"self" logResult:YES];
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
}


- (void)setCurrentSelfPointerBlock:(SuperInterpreterServiceUpdateSelfPointerBlock)currentSelfPointerBlock {
	_currentSelfPointerBlock = [currentSelfPointerBlock copy];
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
