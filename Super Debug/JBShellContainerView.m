//
//  JBShellContainerView.m
//  TextViewShell
//
//  Created by Jason Brennan on 12-07-14.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBShellContainerView.h"
#import "JBShellView.h"

@implementation JBShellContainerView

- (id)initWithFrame:(NSRect)frameRect shellViewClass:(Class)shellViewClass prompt:(NSString *)prompt shellInputProcessingHandler:(JBShellViewInputProcessingHandler)inputProcessingHandler
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code here.
		CGRect bounds = [self bounds];
		NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:bounds];
		[scrollView setBorderType:NSNoBorder];
		[scrollView setHasVerticalScroller:YES];
		[scrollView setHasHorizontalScroller:NO];
		[scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		CGSize contentSize = [scrollView contentSize];
		[scrollView setBackgroundColor:[NSColor whiteColor]];
		
		
		JBShellView *shellView = [[shellViewClass alloc] initWithFrame:CGRectMake(0, 0, contentSize.width, contentSize.height) prompt:prompt inputHandler:inputProcessingHandler];
		[shellView setAutoresizingMask:NSViewWidthSizable];
		[shellView setMinSize:CGSizeMake(0.0f, contentSize.height)];
		[shellView setMaxSize:CGSizeMake(1e7, 1e7)];
		[shellView setVerticallyResizable:YES];
		[shellView setHorizontallyResizable:NO];
		[shellView setBackgroundColor:[NSColor whiteColor]];
		[[shellView textContainer] setWidthTracksTextView:YES];
		
		self.shellView = shellView;
		
		[scrollView setDocumentView:shellView];
		[self addSubview:scrollView];
		
		[self setAutoresizesSubviews:YES];
		[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		[kJBShellViewErrorColor description];
    }
    
    return self;
}


- (BOOL)becomeFirstResponder {
	return [self.shellView becomeFirstResponder];
}

- (BOOL)canBecomeKeyView {
	return YES;
}


@end
