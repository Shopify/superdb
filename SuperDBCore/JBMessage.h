//
//  JBMessage.h
//  Lecture12
//
//  Created by Jason Brennan on 12-03-25.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJBMessageHeaderType;
extern NSString *const kJBMessageHeaderTypeLogin;
extern NSString *const kJBMessageHeaderTypeLogout;
extern NSString *const kJBMessageHeaderTypeText;
extern NSString *const kJBMessageHeaderTypeListing;
extern NSString *const kJBMessageHeaderTypeItem;
extern NSString *const kJBMessageHeaderTypeError;
extern NSString *const kJBMessageHeaderTypeBid;
extern NSString *const kJBMessageBodyTypeSender;
extern NSString *const kJBMessageBodyTypeUsers;
extern NSString *const kJBMessageBodyTypeReceiver;
extern NSString *const kJBMessageBodyTypeMessage;
extern NSString *const kJBMessageBodyTypeItems;
extern NSString *const kJBMessageBodyTypeItem;
extern NSString *const kJBMessageBodyTypeAmount;
extern NSString *const kJBMessageBodyTypeDelete;
extern NSString *const kJBMessageBodyTypeAdd;

@interface JBMessage : NSObject

@property (nonatomic, strong) NSDictionary *header;
@property (nonatomic, strong) NSDictionary *body;


+ (id)messageWithHeader:(NSDictionary *)header body:(NSDictionary *)body;
+ (id)messageWithJSONData:(NSData *)data;
- (NSData *)JSONData;

@end
