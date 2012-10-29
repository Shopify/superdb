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
#import "JBSuggestionsTableView.h"

@interface JBSuggestionWindowController ()

@property (nonatomic, assign) NSTextView *parentTextView;
@property (nonatomic, weak) id localEventMonitor;
@property (nonatomic, weak) id globalEventMonitor;

@property (nonatomic, strong) JBSuggestionsTableView *suggestionsTableViewContainer;

@end

@implementation JBSuggestionWindowController

- (id)init {
	CGRect frame = CGRectMake(0, 0, 200, 200);
	NSWindow *window = [[JBSuggestionWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
		JBRoundedCornersMenuView *contentView = [[JBRoundedCornersMenuView alloc] initWithFrame:frame];
		[window setContentView:contentView];
		[contentView setAutoresizesSubviews:NO];
		
		self.suggestionsTableViewContainer = [[JBSuggestionsTableView alloc] initWithFrame:frame];
		[contentView addSubview:self.suggestionsTableViewContainer];
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
	self.parentTextView = parentTextView;
	
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
	//[self layoutSuggestions];
	[self.suggestionsTableViewContainer.tableView reloadData];
	[parentWindow addChildWindow:suggestionWindow ordered:NSWindowAbove];
	NSLog(@"tv:%@", [[[suggestionWindow contentView] subviews] valueForKey:@"frame"]);
	
	
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


- (void)setSuggestions:(NSArray *)suggestions {
	//_suggestions = [suggestions copy];
	self.suggestionsTableViewContainer.suggestions = suggestions;
	
//	if ([self.window isVisible]) {
//		[self layoutSuggestions];
//	}
}


- (NSArray *)suggestions {
	return self.suggestionsTableViewContainer.suggestions;
}


- (void)layoutSuggestions {
	const CGFloat rowHeight = 22.0f;
	CGFloat windowWidth = 0.0f;
	CGFloat currentHeight = 0.0f;
	
	JBRoundedCornersMenuView *menuView = [[self window] contentView];
	
//	for (NSDictionary *suggestion in _suggestions) {
//		NSString *title = suggestion[@"title"];
//		
//		NSFont *titleFont = [self.parentTextView font];
//		CGFloat currentWidth = [title sizeWithAttributes:@{NSFontAttributeName : titleFont}].width;
//		
//		if (currentWidth > windowWidth) {
//			windowWidth = currentWidth;
//		}
//		
//		NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectMake(0, currentHeight, windowWidth, rowHeight)];
//		[label setBackgroundColor:[NSColor clearColor]];
//		[label setBezeled:NO];
//		[label setBordered:NO];
//		[label setFont:titleFont];
//		
//		NSAttributedString *string = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : titleFont}];
//		[label setAttributedStringValue:string];
//		
//		[menuView addSubview:label];
//		
//		currentHeight += rowHeight;
//	}
	
	CGRect windowContentFrame = CGRectMake(0, 0, windowWidth, currentHeight);
	[menuView setFrame:windowContentFrame];
	
	CGRect winFrame = [[self window] frame];
    winFrame.origin.y = NSMaxY(winFrame) - NSHeight(windowContentFrame);
    winFrame.size.height = NSHeight(windowContentFrame);
    [[self window] setFrame:winFrame display:YES];

}

@end
