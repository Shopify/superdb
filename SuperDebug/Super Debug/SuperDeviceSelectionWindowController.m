//
//  SuperDeviceSelectionWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//
//  Copyright (c) 2012-2013, Shopify, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Shopify, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL Shopify, Inc. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SuperDeviceSelectionWindowController.h"
#import "SuperDebugAreaWindowController.h"
#import "JBShellView.h"


@interface SuperDeviceSelectionWindowController ()
@property (strong) SuperServicesBrowser *servicesBrowser;
@property (nonatomic, strong) NSArray *foundServices;
@property (nonatomic, strong) NSMutableDictionary *deviceWindowControllers;
@end


@implementation SuperDeviceSelectionWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
		self.deviceWindowControllers = [@{} mutableCopy];
    }
    
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
	[self.tableView setRowHeight:44.0f];
	
	self.servicesBrowser = [[SuperServicesBrowser alloc] initWithServicesCallback:^(id servicesFound, BOOL moreComing, NSDictionary *error) {
		NSLog(@"Found services: %@", servicesFound);
		self.foundServices = servicesFound;
		[self.tableView reloadData];
	}];
	[self.tableView setTarget:self];
	[self.tableView setDoubleAction:@selector(doubleClicked:)];
}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.foundServices count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *rowView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	
	NSNetService *service = [self.foundServices objectAtIndex:row];
	
	[rowView.textField setStringValue:[service name]];
	return rowView;
}


- (void)doubleClicked:(id)sender {
	NSInteger row = [self.tableView clickedRow];
	NSNetService *service = [self.foundServices objectAtIndex:row];
	
	SuperDebugAreaWindowController *controller = [self.deviceWindowControllers objectForKey:[service name]];
	if (nil == controller) {
		// create it and store it away for future reference
		controller = [SuperDebugAreaWindowController new];
		controller.netService = service;
		[self.deviceWindowControllers setObject:controller forKey:[service name]];
	}
	
	[[controller window] makeKeyAndOrderFront:self];
	
}


- (IBAction)showNewShell:(NSButton *)sender {
	SuperDebugAreaWindowController *controller = [SuperDebugAreaWindowController new];
	controller.disconnectedShell = YES;
	[[controller window] makeKeyAndOrderFront:self];
	
}


@end
