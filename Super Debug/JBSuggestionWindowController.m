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

@property (nonatomic, assign) NSTextView *parentTextView;
@property (nonatomic, weak) id localEventMonitor;
@property (nonatomic, weak) id globalEventMonitor;

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


- (void)dealloc {
	// Because for some shitty reason, NSTextViews can't be made `weak`, so we have to nil this out manually.
	self.parentTextView = nil;
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
	
	self.parentTextView = parentTextView;
	
	
	// cancellation events:
	self.localEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDown|NSRightMouseDown|NSOtherMouseDown handler:^(NSEvent *event) {
		
		if ([event window] != suggestionWindow) {
			if ([event window] == parentWindow) {
				
				// Want to test if the click was somewhere in the text view, and if not, cancel the suggestions and swallow the event
				NSView *contentView = [parentWindow contentView];
                CGPoint locationTest = [contentView convertPoint:[event locationInWindow] fromView:nil];
                NSView *hitView = [contentView hitTest:locationTest];
				
				if (hitView != parentTextView) {
					event = nil;
					[self cancelSuggestions];
				}
			} else {
				
				// Not the suggestion window, so must be in some other window of the app, thus dismiss the suggestions
				[self cancelSuggestions];
			}
		}
		
		return event;
	}];
	
	self.globalEventMonitor = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification object:parentWindow queue:nil usingBlock:^(NSNotification *notification) {
        // lost key status, cancel the suggestion window
        [self cancelSuggestions];
    }];
}


- (void)cancelSuggestions {
	NSWindow *suggestionsWindow = self.window;
	if ([suggestionsWindow isVisible]) {
	
	[[suggestionsWindow parentWindow] removeChildWindow:suggestionsWindow];
	[suggestionsWindow orderOut:nil];
	
	}
	
	if (self.globalEventMonitor) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.globalEventMonitor];
		self.globalEventMonitor = nil;
	}
	
	
	if (self.localEventMonitor) {
		[NSEvent removeMonitor:self.localEventMonitor];
		self.localEventMonitor = nil;
	}
}

@end
