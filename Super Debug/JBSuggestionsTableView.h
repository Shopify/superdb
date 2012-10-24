//
//  JBSuggestionsTableView.h
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-24.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JBSuggestionsTableView : NSView
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSArray *suggestions;
@end
