//
//  JBDeviceSelectionWindowController.h
//  Super Debug
//
//  Created by Jason Brennan on 12-07-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JBDeviceSelectionWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@end
