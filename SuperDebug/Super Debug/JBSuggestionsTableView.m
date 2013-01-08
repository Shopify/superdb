//
//  JBSuggestionsTableView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-24.
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
		CGRect tableBounds = bounds;
		tableBounds.origin = CGPointZero;
		
		[self.tableView setFrame:tableBounds];
		[[self.tableView enclosingScrollView] setFrame:bounds];
		[self addSubview:[self.tableView enclosingScrollView]];
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
	const CGFloat padding = 8.0f;
	CGRect windowFrame = [[self window] frame];
	
	
	[self.tableView reloadData];
	
	CGFloat rowHeight = [self.tableView rowHeight];
	CGRect tableFrame = [self.tableView frame];
	
	CGFloat maxHeight = (5 * (rowHeight + [self.tableView intercellSpacing].height));
	
	if (CGRectGetHeight(tableFrame) > maxHeight) {
		tableFrame.size.height = maxHeight;
	} else {
		tableFrame.size.height = [self.tableView numberOfRows] * (rowHeight + [self.tableView intercellSpacing].height);
	}
	tableFrame.size.width = widest + (2 * inset) + padding;
	
	CGRect scrollFrame = tableFrame;
	scrollFrame.origin = CGPointMake(inset, inset);
	scrollFrame.size.height += inset;
	scrollFrame.size.width += inset;
	
	[self.tableView setFrame:tableFrame];
	[[self.tableView enclosingScrollView] setFrame:scrollFrame];
	
	windowFrame.size.height = 450.f;
	[[self window] setFrame:windowFrame display:NO];
	
	
//	CGRect frame = [[self window] frame];
//	CGFloat padding = 8.0f;
//
//	tableFrame.size.width = widest;
//	frame.size.height = tableFrame.size.height + 2*inset;
//	
//	CGRect scrollViewFrame = [[self.tableView enclosingScrollView] frame];
//	scrollViewFrame.size.width = widest + padding;
//	//scrollViewFrame.size.height = tableFrame.size.height;
//	
//	[[self.tableView enclosingScrollView] setFrame:scrollViewFrame];
//	//[[self.tableView enclosingScrollView] set]
//	[self.tableView setFrame:tableFrame];
//	[[self window] setFrame:frame display:NO];
	
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
