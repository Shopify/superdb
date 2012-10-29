//
//  JBSuggestionsTableView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-24.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionsTableView.h"
#import "JBSuggestionTableRowView.h"

const CGFloat inset = 3.0f;

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
		CGRect bounds = CGRectInset([self bounds], inset, inset);
		[self.tableView setFrame:bounds];
		[[self.tableView enclosingScrollView] setFrame:bounds];
		[self addSubview:[self.tableView enclosingScrollView]];
		//[self.tableView setIden]
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
    }
    
    return self;
}

- (void)moveUp:(id)sender {
	NSInteger index = [self.tableView selectedRow];
	if (--index >= 0) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
		[self.tableView scrollRowToVisible:index];
	}
}


- (void)moveDown:(id)sender {
	NSInteger index = [self.tableView selectedRow];
	if (++index < [self.tableView numberOfRows]) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
		[self.tableView scrollRowToVisible:index];
	}
}

- (void)setSuggestions:(NSArray *)suggestions {
	_suggestions = [suggestions copy];
	
	// Figure out how big the view needs to be based on the biggest suggestion
	
	CGFloat widest = 0.0f;
	NSFont *font = [NSFont fontWithName:@"Menlo" size:18.0f];
	
	for (NSDictionary *suggestion in suggestions) {
		NSString *title = suggestion[@"title"];
		CGFloat width = [title sizeWithAttributes:@{NSFontAttributeName : font}].width;
		
		if (width > widest) widest = width;
	}
	CGRect frame = [[self window] frame];
	CGFloat padding = 8.0f;
	frame.size.width = widest + (2 * inset) + padding;
	[[self window] setFrame:frame display:NO];
	[self.tableView reloadData];
	NSLog(@"TableView size: %@", NSStringFromRect(self.tableView.frame));
}


#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"how many rows? %ld", [self.suggestions count]);
	return [self.suggestions count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *cell = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	
	NSDictionary *suggestion = self.suggestions[row];
	[cell.textField setStringValue:suggestion[@"title"]];
	return cell;
}

@end
