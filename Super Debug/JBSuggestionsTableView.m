//
//  JBSuggestionsTableView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-24.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionsTableView.h"


@interface JBSuggestionsTableView () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation JBSuggestionsTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		if (![NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self]) {
			NSLog(@"Error loading %@ nib", NSStringFromClass([self class]));
		}
		NSLog(@"Tableview description= %@", self.tableView);
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
