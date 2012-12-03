//
//  JBSuggestionWindowController.h
//  Super Debug
//
//  Created by Jason Brennan on 2012-10-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JBSuggestionWindowController : NSWindowController

@property (nonatomic, copy) NSArray *suggestions;

- (void)beginForParentTextView:(NSTextView *)parentTextView;

- (BOOL)textViewShouldMoveUp:(NSTextView *)sender;
- (BOOL)textViewShouldMoveDown:(NSTextView *)sender;


@end
