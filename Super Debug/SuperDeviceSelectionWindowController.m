//
//  SuperDeviceSelectionWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

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
