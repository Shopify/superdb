//
//  JBMessage.m
//  Lecture12
//
//  Created by Jason Brennan on 12-03-25.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBMessage.h"

#define kBodyKey @"body"
#define kHeaderKey @"header"


NSString *const kJBMessageHeaderType = @"type";
NSString *const kJBMessageHeaderTypeLogin = @"LOGIN";
NSString *const kJBMessageHeaderTypeLogout = @"LOGOUT";
NSString *const kJBMessageHeaderTypeText = @"TEXT";
NSString *const kJBMessageHeaderTypeListing = @"LISTING";
NSString *const kJBMessageHeaderTypeItem = @"ITEM";
NSString *const kJBMessageHeaderTypeError = @"ERROR";
NSString *const kJBMessageHeaderTypeBid = @"BID";
NSString *const kJBMessageBodyTypeSender = @"sender";
NSString *const kJBMessageBodyTypeUsers = @"users";
NSString *const kJBMessageBodyTypeReceiver = @"receiver";
NSString *const kJBMessageBodyTypeMessage = @"message";
NSString *const kJBMessageBodyTypeItems = @"items";
NSString *const kJBMessageBodyTypeItem = @"item";
NSString *const kJBMessageBodyTypeAmount = @"amount";
NSString *const kJBMessageBodyTypeDelete = @"delete";
NSString *const kJBMessageBodyTypeAdd = @"add";


@interface JBMessage ()
@property (nonatomic, strong) NSMutableDictionary *storage;
@end


@implementation JBMessage
@synthesize storage = _storage;


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
