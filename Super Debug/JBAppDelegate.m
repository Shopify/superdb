//
//  JBAppDelegate.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBAppDelegate.h"
#import "JBDeviceSelectionWindowController.h"


@interface JBAppDelegate ()
@property (nonatomic, strong) JBDeviceSelectionWindowController *deviceWindow;
@end

@implementation JBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.deviceWindow = [[JBDeviceSelectionWindowController alloc] initWithWindowNibName:@"JBDeviceSelectionWindowController"];
	[self.deviceWindow showWindow:nil];
	
}

- (IBAction)openNewShell:(NSMenuItem *)sender {
	[self.deviceWindow showNewShell:nil];
}
@end
