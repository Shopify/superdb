//
//  JBSuggestionsTableView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-24.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionsTableView.h"


@interface JBSuggestionsTableView ()
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
		NSLog(@"Tableview description= %@", self.tableView.delegate);
		[self.tableView setFrame:[self bounds]];
		[[self.tableView enclosingScrollView] setFrame:[self bounds]];
		
//		NSScrollView *scrollView  = [[NSScrollView alloc] initWithFrame:[self bounds]];
//		
//		[scrollView setBorderType:NSBezelBorder];
//		[scrollView setHasVerticalScroller:YES];
//		[scrollView setHasHorizontalScroller:YES];
//		[scrollView setAutohidesScrollers:NO];
//		
//		NSRect clipViewBounds  = [[scrollView contentView] bounds];
//		NSTableView *tableView       = [[NSTableView alloc] initWithFrame:clipViewBounds];
//		
//		NSTableColumn*  firstColumn     = [[NSTableColumn alloc] initWithIdentifier:@"firstColumn"];
//		[[firstColumn headerCell] setStringValue:@"First Column"];
//		[tableView addTableColumn:firstColumn];
//		
//
//		
//		[tableView setDataSource:self];
//		[tableView setDelegate:self];
//		
//		[scrollView setDocumentView:tableView];
//		[self addSubview:scrollView];
//		self.tableView = tableView;
		[self addSubview:[self.tableView enclosingScrollView]];
    }
    
    return self;
}


- (void)awakeFromNib {
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
	[self.tableView reloadData];
	
}

- (void)setSuggestions:(NSArray *)suggestions {
	_suggestions = [suggestions copy];
	
	[self.tableView reloadData];
}


#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"how many rows? %ld", [self.suggestions count]);
	return 10;
	return [self.suggestions count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *cell = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	
	NSDictionary *suggestion = self.suggestions[row];
	[cell.textField setStringValue:suggestion[@"title"]];
	NSLog(@"cellll %@", suggestion);
	return cell;
}

@end
