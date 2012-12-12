//
//  SuperNetworkMessage.m
//  SuperDBCore
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperNetworkMessage.h"


#define kBodyKey @"body"
#define kHeaderKey @"header"

#define kHeaderTypeKey @"type"
#define kHeaderResourceKey @"resource"

static NSArray *headerTypes = nil;
static NSDictionary *resourceTypes = nil;

NSString *kSuperNetworkMessageBodyStatusKey = @"status";
NSString *kSuperNetworkMessageBodyStatusOK = @"OK";
NSString *kSuperNetworkMessageBodyStatusError = @"Error";
NSString *kSuperNetworkMessageBodyErrorMessageKey = @"error_message";
NSString *kSuperNetworkMessageBodyErrorRange = @"error_range";
NSString *kSuperNetworkMessageBodyInputKey = @"input";
NSString *kSuperNetworkMessageBodyOutputKey = @"output";


NSString *kSuperNetworkMessageResourceInterpreter = @"interpreter";
NSString *kSuperNetworkMessageResourceSymbolTable = @"smybol_table";
NSString *kSuperNetworkMessageResourceClassList = @"class_list";
NSString *kSuperNetworkMessageResourcePropertyList = @"property_list";
NSString *kSuperNetworkMessageResourceMethodList = @"method_list";
NSString *kSuperNetworkMessageResourceUpdateCurrentSelfPointer = @"update_current_self_pointer";
NSString *kSuperNetworkMessageResourceDeviceLoggingSettings = @"device_logging";


@interface SuperNetworkMessage ()
@property (nonatomic, strong) NSMutableDictionary *storage;
@end

@implementation SuperNetworkMessage


+ (void)initialize {
	headerTypes = @[ @"SuperNetworkMessageTypeHandshake",
					 @"SuperNetworkMessageTypeRequestResponse" ];
	resourceTypes = @{	@".prop" : kSuperNetworkMessageResourcePropertyList,
						@".classes" : kSuperNetworkMessageResourceClassList,
						@".methods" : kSuperNetworkMessageResourceMethodList,
						@".self" : kSuperNetworkMessageResourceUpdateCurrentSelfPointer,
						@".logging" : kSuperNetworkMessageResourceDeviceLoggingSettings};
}


+ (id)messageWithHeader:(NSDictionary *)header body:(NSDictionary *)body {
	return [[self alloc] initWithHeader:header body:body];
}



- (id)initWithHeader:(NSDictionary *)header body:(NSDictionary *)body {
	if ((self = [super init])) {
		self.storage = [NSMutableDictionary dictionaryWithCapacity:2];
		self.header = header;
		self.body = body;
	}
    return self;
}


+ (id)messageWithJSONData:(NSData *)data {
	NSError *error = nil;
	NSDictionary *m = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
	if (nil == m) {
		NSLog(@"There was an error parsing message JSON: %@", [error userInfo]);
		return nil;
	}
	
	return [self messageWithHeader:[m objectForKey:kHeaderKey] body:[m objectForKey:kBodyKey]];
	
}


- (NSData *)JSONData {
	NSError *error = nil;
	NSData *d = [NSJSONSerialization dataWithJSONObject:self.storage options:kNilOptions error:&error];
	if (nil == d) {
		NSLog(@"There was an error creating a JSON message. %@", [error userInfo]);
	}
	
	return d; // will return nil if error
}


- (void)log {
	NSLog(@"%@", self.storage);
}


- (SuperNetworkMessageType)messageType {
	
	for (SuperNetworkMessageType i = 0; i < [headerTypes count]; i++) {
		if ([[headerTypes objectAtIndex:i] isEqualToString:[[self header] objectForKey:kHeaderTypeKey]])
			return i;
	}
	
	return 0;
}


- (NSString *)resource {
	return [[self header] objectForKey:kHeaderResourceKey];
}

#pragma mark - Public API

+ (instancetype)messageWithType:(SuperNetworkMessageType)messageType body:(NSDictionary *)body {
	
	NSString *typeString = [headerTypes objectAtIndex:messageType];
	NSDictionary *header = @{ kHeaderTypeKey : typeString };
	
	return [self messageWithHeader:header body:body];
}

+ (instancetype)messageWithResource:(NSString *)resource body:(NSDictionary *)body {
	NSString *typeString = [headerTypes objectAtIndex:SuperNetworkMessageTypeRequestResponse];
	NSDictionary *header = @{ kHeaderTypeKey : typeString, kHeaderResourceKey : resource };
	
	return [self messageWithHeader:header body:body];
}


+ (NSString *)messageResourceTypeForCommand:(NSString *)command {
	return resourceTypes[command];
}


#pragma mark -
#pragma mark Overriding the properties

- (void)setBody:(NSDictionary *)body {
	[self.storage setValue:body forKey:kBodyKey];
}


- (NSDictionary *)body {
	// Using -objectForKey: instead of -valueForKey: because ofk returns nil if the key isn't found, instead of blowing up.
	return [self.storage objectForKey:kBodyKey];
}


- (void)setHeader:(NSDictionary *)header {
	[self.storage setValue:header forKey:kHeaderKey];
}


- (NSDictionary *)header {
	return [self.storage objectForKey:kHeaderKey];
}


@end
