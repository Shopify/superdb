//
//  SuperAppDelegate.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperAppDelegate.h"
#import "SuperDeviceSelectionWindowController.h"


@interface SuperAppDelegate ()
@property (nonatomic, strong) SuperDeviceSelectionWindowController *deviceWindow;
@end

@implementation SuperAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.deviceWindow = [[SuperDeviceSelectionWindowController alloc] initWithWindowNibName:@"SuperDeviceSelectionWindowController"];
	[self.deviceWindow showWindow:nil];
	
}

- (IBAction)openNewShell:(NSMenuItem *)sender {
	[self.deviceWindow showNewShell:nil];
}
@end
