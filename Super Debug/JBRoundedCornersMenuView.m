//
//  JBRoundedCornersMenuView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBRoundedCornersMenuView.h"

@implementation JBRoundedCornersMenuView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    NSColor *color = [NSColor windowBackgroundColor];
	[color setFill];
	
	const CGFloat cornerRadius = 6.0f;
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:cornerRadius yRadius:cornerRadius];
	[path fill];
}


- (BOOL)isFlipped {
	return YES;
}

@end
