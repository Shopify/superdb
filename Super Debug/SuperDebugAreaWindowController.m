//
//  SuperDebugAreaWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperDebugAreaWindowController.h"
#import "JBShellContainerView.h"
#import "JBShellView.h"


@interface SuperDebugAreaWindowController () <NSNetServiceDelegate>
@property (nonatomic, strong) SuperInterpreterClient *networkClient;
@property (nonatomic, strong) JBShellContainerView *shellContainer;
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
    
   	CGRect bounds = [[self.window contentView] bounds];
	NSString *prompt = [NSString stringWithFormat:@"%@> ", [self.netService name]];
    self.shellContainer = [[JBShellContainerView alloc] initWithFrame:bounds prompt:prompt shellInputProcessingHandler:^(NSString *input, JBShellView *sender) {
		//[self.networkClient ]
	}];
	[[[self window] contentView] addSubview:self.shellContainer];
	[self.window makeFirstResponder:self.shellContainer.shellView];
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
	
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	
	NSLog(@"Room could not resolve a connection! %@", errorDict);
}





@end
