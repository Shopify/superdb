//
//  JBSuggestionWindowController.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionWindowController.h"
#import "JBSuggestionWindow.h"
#import "JBRoundedCornersMenuView.h"

@interface JBSuggestionWindowController ()

@end

@implementation JBSuggestionWindowController

- (id)init {
	CGRect frame = CGRectMake(100, 500, 200, 200);
	NSWindow *window = [[JBSuggestionWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
		JBRoundedCornersMenuView *contentView = [[JBRoundedCornersMenuView alloc] initWithFrame:frame];
		[window setContentView:contentView];
		[contentView setAutoresizesSubviews:NO];
		
		
	}
	
	return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)beginForParentTextView:(NSTextView *)parentTextView {
	NSWindow *suggestionWindow = [self window];
	NSWindow *parentWindow = [parentTextView window];
	
	CGRect suggestionFrame = [suggestionWindow frame];
	CGRect parentFrame = [parentWindow frame];
	
	// Sizes get set in the layout method... want to make the width only as wide as it has to be.
	CGRect insertionRect = [parentTextView firstRectForCharacterRange:[parentTextView selectedRange]];
	NSLog(@"Cursor rect: %@", NSStringFromRect(insertionRect));
	
//	CGPoint insertionPointInWindowCoordinates = [[parentTextView superview] convertPoint:insertionRect.origin toView:nil];
//	CGRect windowCooridinateRect;
//	windowCooridinateRect.origin = insertionPointInWindowCoordinates;
//	windowCooridinateRect.size = CGSizeMake(1, 1);
//	
//	CGPoint insertionPointInScreenCoordinates = [parentWindow convertRectToScreen:windowCooridinateRect].origin;
	[suggestionWindow setFrameTopLeftPoint:insertionRect.origin];
	
	[parentWindow addChildWindow:suggestionWindow ordered:NSWindowAbove];
}

@end
