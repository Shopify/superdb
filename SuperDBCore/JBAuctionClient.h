//
//  JBIMClient.h
//  Lecture12
//
//  Created by Jason Brennan on 12-03-23.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const JBIMClientApplicationClosingNotification;

@class JBMessage;

typedef void(^JBAuctionClientMessageCallback)(JBMessage *responseMessage);

@interface JBAuctionClient : NSObject

- (id)initWithHost:(NSData *)address;
- (void)startNetworkConnectionWithLoginName:(NSString *)loginName loginCallbackHandler:(JBAuctionClientMessageCallback)callback usersChangedCallback:(JBAuctionClientMessageCallback)changedCallback textMessageReceivedCallback:(JBAuctionClientMessageCallback)textMessageReceivedCallback auctionListCallback:(JBAuctionClientMessageCallback)auctionListCallback itemMessageCallback:(JBAuctionClientMessageCallback)itemMessageCallback bidCallback:(JBAuctionClientMessageCallback)bidCallback;

- (void)sendMessage:(JBMessage *)message withCallbackHandler:(JBAuctionClientMessageCallback)callback;
- (void)sendAuctionListMessageWithCallbackHandler:(JBAuctionClientMessageCallback)callback;
@end
