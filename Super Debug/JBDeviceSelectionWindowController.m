//
//  JBDeviceSelectionWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBDeviceSelectionWindowController.h"
#import "SuperDebugAreaWindowController.h"


@interface JBDeviceSelectionWindowController ()
@property (strong) JBServicesBrowser *servicesBrowser;
@property (nonatomic, strong) NSArray *foundServices;
@property (nonatomic, strong) NSMutableDictionary *deviceWindowControllers;
@end

@implementation JBDeviceSelectionWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
		self.deviceWindowControllers = [@{} mutableCopy];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.tableView setRowHeight:44.0f];
	
	self.servicesBrowser = [[JBServicesBrowser alloc] initWithServicesCallback:^(id servicesFound, BOOL moreComing, NSDictionary *error) {
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

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	return @"woah";
//}

/* View Based TableView: 
 Non-bindings: This method is required if you wish to turn on the use of NSViews instead of NSCells. The implementation of this method will usually call -[tableView makeViewWithIdentifier:[tableColumn identifier] owner:self] in order to reuse a previous view, or automatically unarchive an associated prototype view for that identifier. The -frame of the returned view is not important, and it will be automatically set by the table. 'tableColumn' will be nil if the row is a group row. Returning nil is acceptable, and a view will not be shown at that location. The view's properties should be properly set up before returning the result.
 
 Bindings: This method is optional if at least one identifier has been associated with the TableView at design time. If this method is not implemented, the table will automatically call -[self makeViewWithIdentifier:[tableColumn identifier] owner:[tableView delegate]] to attempt to reuse a previous view, or automatically unarchive an associated prototype view. If the method is implemented, the developer can setup properties that aren't using bindings.
 
 The autoresizingMask of the returned view will automatically be set to NSViewHeightSizable to resize properly on row height changes.
 */
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *rowView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	[rowView.textField setStringValue:@"A ROW!!"];
	NSLog(@"%d", SOMETHING);
	return rowView;
}


- (void)doubleClicked:(id)sender {
	NSInteger row = [self.tableView clickedRow];
	NSNetService *service = [self.foundServices objectAtIndex:row];
	
	SuperDebugAreaWindowController *controller = [self.deviceWindowControllers objectForKey:[service name]];
	if (nil == controller) {
		// create it and store it away for future reference
		controller = [[SuperDebugAreaWindowController alloc] initWithWindowNibName:@"SuperDebugAreaWindowController"];
		controller.netService = service;
		[self.deviceWindowControllers setObject:controller forKey:[service name]];
	}
	
	[[controller window] makeKeyAndOrderFront:self];
	
}



@end
