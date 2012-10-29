//
//  JBSuggestionTableRowView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBSuggestionTableRowView.h"

@implementation JBSuggestionTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	CGRect selectionRect = [self bounds];
	
	NSColor *startColor = [NSColor colorWithCalibratedRed:0.303 green:0.437 blue:0.650 alpha:1.000];
	NSColor *endColor = [NSColor colorWithCalibratedRed:0.078 green:0.260 blue:0.554 alpha:1.000];
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:4. yRadius:4.] angle:90];
}

@end
