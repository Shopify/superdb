//
//  SuperDebugAreaWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperDebugAreaWindowController.h"


@interface SuperDebugAreaWindowController () <NSNetServiceDelegate>
@property (nonatomic, strong) SuperInterpreterClient *networkClient;
@end

@implementation SuperDebugAreaWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)setNetService:(NSNetService *)netService {
	if (netService == _netService)
		return;
	
	_netService = netService;
	
	_netService.delegate = self;
	[_netService resolveWithTimeout:0];
	
}


#pragma mark -
#pragma mark NSNetServiceDelegate methods

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
	// Now ask for the addresses, and get the first one
	NSArray *addresses = [sender addresses];
	NSData *info = [addresses objectAtIndex:0];
	
	self.networkClient = [[SuperInterpreterClient alloc] initWithHostData:info];
	[self.networkClient startNetworkConnectionWithResponseHandler:^(SuperNetworkMessage *response) {
		[response log];
	}];
	
	// Generate a random username, just so I can properly test this between the Simulator and my device
//	NSInteger num = arc4random() % 1000;
//	NSString *userName = [NSString stringWithFormat:@"Jason%d", num];
//	self.userName = userName;
//	
//	[self.networkClient startNetworkConnectionWithLoginName:userName loginCallbackHandler:^(JBMessage *responseMessage) {
//		self.title = userName;
//		// Now logged in, update the room with a list of users
//		NSMutableArray *users = [NSMutableArray arrayWithArray:[[responseMessage body] valueForKey:kJBMessageBodyTypeUsers]];
//		
//		for (NSString *user in users) {
//			[self addChatRoomForUser:user];
//		}
//		
//		NSLog(@"%@ Login succeeded, got users: %@", userName, users);
//		[self.tableView reloadData];
//		
//		NSLog(@"Now asking for auctions");
//		[self.networkClient sendAuctionListMessageWithCallbackHandler:^(JBMessage *responseMessage) {
//			NSLog(@"Got the response message for AUCTIONLIST: %@", [responseMessage body]);
//			NSDictionary *items = [[responseMessage body] objectForKey:kJBMessageBodyTypeItems];
//			[self addAuctionItems:items];
//			[self.tableView reloadData];
//			self.navigationItem.rightBarButtonItem.enabled = YES;
//		}];
//		
//	} usersChangedCallback:^(JBMessage *responseMessage) {
//		
//		// The list has either grown or shrunk. We need to update our view accordingly
//		NSLog(@"Users changed!");
//		
//		
//		NSString *header = [[responseMessage header] valueForKey:kJBMessageHeaderType];
//		if ([header isEqualToString:kJBMessageHeaderTypeLogin]) {
//			// it's a login, so look for the new user!
//			[self addChatRoomForUser:[[responseMessage body] valueForKey:kJBMessageBodyTypeSender]];
//		} else {
//			// it's a logout, so see who's logged out and remove them
//			[self removeChatRoomForUser:[[responseMessage body] valueForKey:kJBMessageBodyTypeSender]];
//			
//			// Notify any open rooms, too
//			NSNotification *note = [NSNotification notificationWithName:JBChatRoomDidCloseNotification object:[[responseMessage body] valueForKey:kJBMessageBodyTypeSender]];
//			[[NSNotificationCenter defaultCenter] postNotification:note];
//		}
//		
//		[self.tableView reloadData];
//		
//		
//		
//	} textMessageReceivedCallback:^(JBMessage *responseMessage) {
//		
//		// We got a message from some user
//		// Figure out who sent the message,
//		// Find the JBChat that corresponds to that user,
//		// Add the new message to that Chat
//		NSLog(@"We got a text message!");
//		NSString *senderUserName = [[responseMessage body] objectForKey:kJBMessageBodyTypeSender];
//		JBChatRoom *room = [self chatRoomForUser:senderUserName];
//		
//		// update the room with the latest chat message
//		JBChatMessage *newMessage = [[JBChatMessage alloc] init];
//		newMessage.sender = senderUserName;
//		newMessage.recipient = self.userName;
//		newMessage.timestamp = [NSDate date];
//		newMessage.text = [[responseMessage body] objectForKey:kJBMessageBodyTypeMessage];
//		[room addChatMessagesObject:newMessage];
//		
//		// Post a notification message
//		[[NSNotificationCenter defaultCenter] postNotificationName:JBChatRoomDidAddMessageNotification object:nil];
//		
//	} auctionListCallback:^(JBMessage *responseMessage) {
//		NSLog(@"Auction list?");
//	} itemMessageCallback:^(JBMessage *responseMessage) {
//		
//		NSLog(@"CLIENT:Got an ITEM callback");
//		NSDictionary *body = responseMessage.body;
//		JBAuctionItem *newItem = [[JBAuctionItem alloc] init];
//		newItem.itemName = [body objectForKey:kJBMessageBodyTypeItem];
//		newItem.itemValue = [[body objectForKey:kJBMessageBodyTypeAmount] integerValue];
//		
//		[self.currentAuctions addObject:newItem];
//		[self.tableView reloadData];
//		
//	} bidCallback:^(JBMessage *responseMessage) {
//		//JBAuctionItem *item = nil;
//		for (JBAuctionItem *curItem in self.currentAuctions) {
//			if ([curItem.itemName isEqualToString:[responseMessage.body objectForKey:kJBMessageBodyTypeItem]]) {
//				curItem.itemValue = [[responseMessage.body objectForKey:kJBMessageBodyTypeAmount] integerValue];
//				break;
//			}
//		}
//		
//		[self.tableView reloadData];
//	}];
	
	
	
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	
	NSLog(@"Room could not resolve a connection! %@", errorDict);
}





@end
