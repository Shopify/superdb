//
//  JBIMServer.m
//  Lecture12
//
//  Created by Jason Brennan on 12-03-23.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBAuctionServer.h"
#import "GCDAsyncSocket.h"
#import "JBMessage.h"
#import "JBUser.h"


#define kClientSocketReadTag 100
#define kClientSocketWriteTag 101

typedef JBMessage *(^JBEventHandlerBlock)(JBMessage *message, JBUser *user);


@interface JBAuctionServer () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) NSMutableArray *connectedClients;
@property (nonatomic, strong) NSMutableDictionary *reactors;
@property (nonatomic, strong) NSMutableDictionary *auctionItems;

- (JBMessage *)responseMessageByProcessingMessage:(JBMessage *)message user:(JBUser *)user;
- (NSArray *)recipientsForSourceMessage:(JBMessage *)message;
- (void)writeResponse:(JBMessage *)response toRecipients:(NSArray *)recipients;
- (void)addEventType:(NSString *)type handler:(JBEventHandlerBlock)handler;
- (JBUser *)userForSocket:(GCDAsyncSocket *)socket;

@end

@implementation JBAuctionServer
@synthesize listenSocket = _listenSocket;
@synthesize connectedClients = _connectedClients;
@synthesize reactors = _reactors;
@synthesize auctionItems = _auctionItems;


- (void)startServer {
	
	self.connectedClients = [NSMutableArray array];
	self.reactors = [NSMutableDictionary dictionary];
	
	self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSInteger DEFAULT_PORT = 8080;
	NSError *error = nil;
	if (![self.listenSocket acceptOnPort:DEFAULT_PORT error:&error]) {
		NSLog(@"Error starting the Server Socket: %@", [error userInfo]);
	}
	NSLog(@"Server socket started!");
	
	self.auctionItems = [NSMutableDictionary dictionary];
	
	// add some dummy data for now
	[self.auctionItems setObject:[NSNumber numberWithInteger:99] forKey:@"The new iPad"];
	[self.auctionItems setObject:[NSNumber numberWithInteger:1] forKey:@"WWDC Ticket"];
	[self.auctionItems setObject:[NSNumber numberWithInteger:999] forKey:@"Time machine"];
	
	__block __typeof__(self) blockSelf = self; // avoids retain cycle
	// Add event handlers for different message types
	[self addEventType:kJBMessageHeaderTypeLogin handler:^JBMessage *(JBMessage *message, JBUser *user) {
		user.userName = [[message body] valueForKey:kJBMessageBodyTypeSender];
		
		NSMutableArray *otherUsers = [NSMutableArray arrayWithArray:blockSelf.connectedClients];
		[otherUsers removeObject:user];
		
		NSArray *remainingUserNames = [otherUsers valueForKey:@"userName"];
		
		
		NSDictionary *header = [NSDictionary dictionaryWithObject:kJBMessageHeaderTypeLogin forKey:kJBMessageHeaderType];
		NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:user.userName, kJBMessageBodyTypeSender, remainingUserNames, kJBMessageBodyTypeUsers, nil];
		
		JBMessage *response = [JBMessage messageWithHeader:header body:body];
		
		return response;
	}];
	
	
	[self addEventType:kJBMessageHeaderTypeText handler:^JBMessage *(JBMessage *message, JBUser *user) {
		// A message from `user`, being sent to the message's recepient...
		
		
		// Just return the message itself. We'll indicate later that it needs to be delivered to the recipient
		NSLog(@"Server is processing a TEXT message... just going to return it so it can be delivered");
		return message;
		
	}];
	
	
	[self addEventType:kJBMessageHeaderTypeLogout handler:^JBMessage *(JBMessage *message, JBUser *user) {
		
		// Remove that user logging out
		[self.connectedClients removeObject:user];
		
		NSDictionary *header = [NSDictionary dictionaryWithObject:kJBMessageHeaderTypeLogout forKey:kJBMessageHeaderType];
		NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:user.userName, kJBMessageBodyTypeSender, nil];
		
		return [JBMessage messageWithHeader:header body:body];
	}];
	
	
	[self addEventType:kJBMessageHeaderTypeListing handler:^JBMessage *(JBMessage *message, JBUser *user) {
		
		NSDictionary *header = message.header;
		
		NSDictionary *items = [blockSelf auctionItems];
		
		NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:user.userName, kJBMessageBodyTypeSender, items, kJBMessageBodyTypeItems, nil];
		
		return [JBMessage messageWithHeader:header body:body];
	}];
	
	
	[self addEventType:kJBMessageHeaderTypeItem handler:^JBMessage *(JBMessage *message, JBUser *user) {
		BOOL adding = NO;
		NSNumber *addNum = [message.body objectForKey:kJBMessageBodyTypeAdd];
		if (addNum != nil) {
			adding = YES; // else, assume we're deleting
		}
		
		NSString *name = [message.body objectForKey:kJBMessageBodyTypeItem];
		NSNumber *val = [message.body objectForKey:kJBMessageBodyTypeAmount];
		if (adding) {
			[[blockSelf auctionItems] setValue:val forKey:name];
		} else {
			[[blockSelf auctionItems] setValue:nil forKey:name];
		}
		
		return message;
	}];
	
	
	[self addEventType:kJBMessageHeaderTypeBid handler:^JBMessage *(JBMessage *message, JBUser *user) {
		// Ideally we should check here to make sure the bid is valid.
		// If NOT, return an error
		// else, respond with a valid message.....
		// But for now, I just want to get the bid working.
		[[blockSelf auctionItems] setValue:[message.body valueForKey:kJBMessageBodyTypeAmount] forKey:[message.body objectForKey:kJBMessageBodyTypeItem]];
		
		return message;
	}];
	
}


- (JBUser *)userForSocket:(GCDAsyncSocket *)socket {
	for (JBUser *user in self.connectedClients) {
		if (socket == user.socket)
			return user;
	}
	
	return nil;
}


- (JBUser *)userForUserName:(NSString *)userName {
	for (JBUser *user in self.connectedClients) {
		if ([user.userName isEqualToString:userName])
			return user;
	}
	
	return nil;
}


- (JBMessage *)responseMessageByProcessingMessage:(JBMessage *)message user:(JBUser *)user {
	
	
	// Figure out what type of message this is, and create an appropriate response
	JBEventHandlerBlock block = [self.reactors objectForKey:[[message valueForKeyPath:@"header.type"] uppercaseString]];
	
	JBMessage *response = nil;
	if (nil != block) {
		response = block(message, user);
	}
	
	
	return response;
}


- (NSArray *)recipientsForSourceMessage:(JBMessage *)message {
	
	
	// If the message is a TEXT message, then only send the response to its recepient
	if ([[[message valueForKeyPath:@"header.type"] uppercaseString] isEqualToString:kJBMessageHeaderTypeText]) {
		NSLog(@"SERVER:::::::TEXTTTTTTTTTTTTTTTTTTTTTT\n\n\n\n");
		return [NSArray arrayWithObject:[[self userForUserName:[message valueForKeyPath:@"body.receiver"]] socket]];
	}
	
	
	// If the message is a LISTING message, then only send the response to its sender
	if ([[[message valueForKeyPath:@"header.type"] uppercaseString] isEqualToString:kJBMessageHeaderTypeListing]) {
		NSLog(@"SERVER:::::::LISTING\n\n\n\n");
		return [NSArray arrayWithObject:[[self userForUserName:[message valueForKeyPath:@"body.sender"]] socket]];
	}	
	
	
//	if ([[[message valueForKeyPath:@"header.type"] uppercaseString] isEqualToString:kJBMessageHeaderTypeLogout]) {
//		
//		NSMutableArray *sockets = [NSMutableArray arrayWithArray:[self.connectedClients valueForKey:@"socket"]];
//		[sockets removeObject:[[self userForUserName:[message valueForKeyPath:@"body.receiver"]] socket]];
//		
//		return [NSArray arrayWithArray:sockets];
//	}
	
	// Otherwise send it to all users
	return [self.connectedClients valueForKeyPath:@"socket"];
}


- (void)writeResponse:(JBMessage *)response toRecipients:(NSArray *)recipients {
	for (GCDAsyncSocket *socket in recipients) {
		NSData *data = [response JSONData];
		[socket writeData:data withTimeout:-1 tag:kClientSocketWriteTag];
	}
}


- (void)addEventType:(NSString *)type handler:(JBEventHandlerBlock)handler {
	[self.reactors setValue:[handler copy] forKey:type];
}


- (void)stopServer {
	NSLog(@"Stopping the Server");
	[self.connectedClients removeAllObjects];
	[self.listenSocket disconnect];
	self.listenSocket = nil;
}


#pragma mark -
#pragma mark GCDAsyncSocketDelegate methods
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	
	NSLog(@"Server: Accepted a new client socket.");
	
	JBUser *newUser = [[JBUser alloc] init];
	newUser.socket = newSocket;
	[self.connectedClients addObject:newUser];
	
	
	// Get the new socket to start reading.. we're trying to listen for the client's login message
	[newSocket readDataWithTimeout:-1 tag:kClientSocketReadTag];
	
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	// Assume it's all JSON Data
	
	NSLog(@"Gonna read %lu for user %@", tag, [[self userForSocket:sock] userName]);
	
	
	switch (tag) {
		case kClientSocketReadTag: {
			
			// Read the object
			JBMessage *message = [JBMessage messageWithJSONData:data];
			// Process it
			JBMessage *response = [self responseMessageByProcessingMessage:message user:[self userForSocket:sock]];
			// Write a response
			[self writeResponse:response toRecipients:[self recipientsForSourceMessage:message]];
			
			// Tell it to read for the next message from this client
			[sock readDataWithTimeout:-1 tag:kClientSocketReadTag];
			break;
			
		}
			
		default: break;
	}
	
	
	NSError *error = nil;
	NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
	if (nil == dictionary) {
		NSLog(@"There was an error reading data from a client socket! %@", [error userInfo]);
		return;
	}
	
	NSLog(@"Object received from a client: %@", dictionary);
	
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
	if (sock != self.listenSocket) {
		NSLog(@"A client has disconnected");
		[self.connectedClients removeObject:sock];

	}
}




@end
