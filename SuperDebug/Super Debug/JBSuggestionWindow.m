//
//  JBSuggestionWindow.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionWindow.h"

@implementation JBSuggestionWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
	
	if (self) {
		[self setHasShadow:YES];
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
	}
	
	return self;
}

@end
