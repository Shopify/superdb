//
//  SuperDraggableShellView.m
//  Super Debug
//
//  Created by Jason Brennan on 2012-11-29.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "SuperDraggableShellView.h"
#import "JBShellCommandHistory.h"
#import <ParseKit/ParseKit.h>

@interface SuperDraggableShellView ()
@property (assign) CGPoint initialDragPoint;
@property (assign) NSRange initialDragRangeInOriginalCommand;
@property (strong) NSMutableDictionary *numberRanges;
@property (assign) NSRange currentlyHighlightedRange;

// For dragging
@property (copy) NSString *initialString;
@property (strong) NSNumber *initialNumber;
@property (copy) NSString *initialDragCommandString;
@property (assign) NSRange initialDragCommandRange;
@property (assign) NSUInteger initialDragCommandStart;

@end

@implementation SuperDraggableShellView

- (id)initWithFrame:(CGRect)frame prompt:(NSString *)prompt inputHandler:(JBShellViewInputProcessingHandler)inputHandler {
    self = [super initWithFrame:frame prompt:prompt inputHandler:inputHandler];
    if (self) {
		[[self window] setAcceptsMouseMovedEvents:YES];

		self.numberRanges = [@{} mutableCopy];
		self.initialDragPoint = CGPointZero;
		[self resetInitialDragRange];
    }
    
    return self;
}


- (void)resetInitialDragRange {
	self.initialDragRangeInOriginalCommand = NSMakeRange(NSUIntegerMax, NSUIntegerMax);
}


#pragma mark - NSTextView overrides

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	if (_initialNumber != nil) {
		return YES;
	}
	
	return [super shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
}


#pragma mark - Mousing

- (void)mouseMoved:(NSEvent *)theEvent {
	[[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:self.currentlyHighlightedRange];
	NSUInteger character = [self characterIndexForPoint:[NSEvent mouseLocation]];
	
	NSRange range = [self numberStringRangeForCharacterIndex:character];
	if (range.location == NSNotFound) {
		if (_currentlyHighlightedRange.location != NSNotFound) {
			// Only change this when it's not already set... skip some work, I suppose.
			self.currentlyHighlightedRange = range;
		}
		return;
	}
	
	
	self.currentlyHighlightedRange = range;
	NSColor *fontColor = [NSColor colorWithCalibratedRed:0.742 green:0.898 blue:0.397 alpha:1.000];
	[[self textStorage] addAttribute:NSBackgroundColorAttributeName value:fontColor range:range];
}


- (void)mouseDown:(NSEvent *)theEvent {
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseDown:theEvent];
		return;
	}
	
	self.initialDragPoint = [NSEvent mouseLocation];
	self.initialString = [[self string] substringWithRange:self.currentlyHighlightedRange];
	self.initialNumber = [self numberFromString:self.initialString];
	
	NSString *wholeText = [self string];
	
	
	NSString *originalCommand = [self currentCommandForRange:self.currentlyHighlightedRange];
	NSRange originalCommandRange = [wholeText rangeOfString:originalCommand];
	
	self.initialDragCommandString = originalCommand;
	self.initialDragCommandRange = originalCommandRange;
	self.initialDragCommandStart = self.commandStart;
	
	self.initialDragRangeInOriginalCommand = NSMakeRange(self.currentlyHighlightedRange.location - originalCommandRange.location, self.currentlyHighlightedRange.length);
}


- (void)mouseDragged:(NSEvent *)theEvent {
	
	// Skip it if we're not currently dragging a word
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseDragged:theEvent];
		return;
	}
	
	NSLog(@"mouse dragged, current range is: %@", NSStringFromRange(self.currentlyHighlightedRange));
	
	//NSRange numberRange = [self numberStringRangeForCharacterIndex:self.currentlyHighlightedRange.location];
	NSRange numberRange = [self rangeForNumberNearestToIndex:self.currentlyHighlightedRange.location];
	NSString *numberString = [[self string] substringWithRange:numberRange];
	
	NSLog(@"Dragging...current number is: %@", numberString);
	NSNumber *number = [self numberFromString:numberString];
	
	if (nil == number) {
		NSLog(@"Couldn't parse a number out of :%@", numberString);
		return;
	}
	
	CGPoint screenPoint = [NSEvent mouseLocation];
	CGFloat x = screenPoint.x - self.initialDragPoint.x;
	CGFloat y = screenPoint.y - self.initialDragPoint.y;
	CGSize offset = CGSizeMake(x, y);
	
	
	NSInteger offsetValue = [self.initialNumber integerValue] + (NSInteger)offset.width;
	NSNumber *updatedNumber = @(offsetValue);
	NSString *updatedNumberString = [updatedNumber stringValue];
	
	
	// Now do the replacement in the existing text
	NSString *replacedCommand = [self.initialDragCommandString stringByReplacingCharactersInRange:self.initialDragRangeInOriginalCommand withString:updatedNumberString];
	
	[super insertText:updatedNumberString replacementRange:self.currentlyHighlightedRange];
	self.currentlyHighlightedRange = NSMakeRange(self.currentlyHighlightedRange.location, [updatedNumberString length]);
	
	
	// Update the position of commandStart depending on how our (whole) string has changed.
	NSUInteger lengthDifference = [self.initialDragCommandString length] - [replacedCommand length];
	self.commandStart = self.initialDragCommandStart - lengthDifference;
	
	if (self.numberDragHandler) {
		self.numberDragHandler(replacedCommand);
	}
}


- (void)mouseUp:(NSEvent *)theEvent {
	// Skip it if we're not currently dragging a word
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseUp:theEvent];
		return;
	}
	
	// Trigger's clearing out our number-dragging state.
	[self highlightText];
	[self mouseMoved:theEvent];
	
	self.initialDragCommandString = nil;
	self.initialDragCommandRange = NSMakeRange(NSNotFound, NSNotFound);
	self.initialNumber = nil;
}


- (NSRange)rangeForNumberNearestToIndex:(NSUInteger)index {
	// parse this out right now...
	NSRange originalRange = self.initialDragCommandRange;
	
	// The problem is the command doesn't get updated in our history, so it breaks after the first use!!
	NSString *currentCommand = [self currentCommandForRange:originalRange];
	
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:currentCommand];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	
	NSUInteger currentLocation = 0; // in the command!
	
	while ((token = [tokenizer nextToken]) != eof) {
		
		NSRange numberRange = NSMakeRange(currentLocation + originalRange.location, [[token stringValue] length]);
		
		if ([token isNumber]) {
			if (NSLocationInRange(index, numberRange)) {
				return numberRange;
			}
		}
		
		
		currentLocation += [[token stringValue] length];
		
	}
	return NSMakeRange(NSNotFound, NSNotFound);
}


- (NSString *)currentCommandForRange:(NSRange)originalRange {
	
	NSString *wholeString = [self string];
	
	NSRange lineRange = [wholeString lineRangeForRange:originalRange];
	NSString *lineString = [wholeString substringWithRange:lineRange];
	
	return [lineString substringFromIndex:[self.prompt length]];
}


- (NSNumber *)numberFromString:(NSString *)string {
	static NSNumberFormatter *formatter = nil;
	if (nil == formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setAllowsFloats:YES];
	}
	return [formatter numberFromString:string];
}


#pragma mark - JBShellView overrides

- (void)highlightText {
	NSString *string = [[self textStorage] string];
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:string];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	[[self textStorage] beginEditing];
	[self.numberRanges removeAllObjects];
	NSUInteger currentLocation = 0;
	
	while ((token = [tokenizer nextToken]) != eof) {
		NSColor *fontColor = [NSColor whiteColor];//[NSColor grayColor];
		
		NSRange numberRange = NSMakeRange(currentLocation, [[token stringValue] length]);
		
		if ([token isNumber]) {
			fontColor = [NSColor colorWithCalibratedWhite:0.890 alpha:1.000];
			[self setNumberString:[token stringValue] forRange:numberRange];
		} else {
			NSColor *bgColor = [[self textStorage] attribute:NSBackgroundColorAttributeName atIndex:numberRange.location effectiveRange:NULL];
			if (bgColor) fontColor = bgColor;
		}
		
		
		[[self textStorage] addAttribute:NSBackgroundColorAttributeName value:fontColor range:numberRange];
		currentLocation += [[token stringValue] length];
		
		
	}
	
	[[self textStorage] endEditing];
}



#pragma mark - Private API

- (void)setNumberString:(NSString *)string forRange:(NSRange)numberRange {
	// Just store the start location of the number, because the length might change (if, say, number goes from 100 -> 99)
	self.numberRanges[NSStringFromRange(numberRange)] = string;
}


- (NSRange)numberStringRangeForCharacterIndex:(NSUInteger)character {
	for (NSString *rangeString in self.numberRanges) {
		NSRange range = NSRangeFromString(rangeString);
		if (NSLocationInRange(character, range)) {
			return range;
		}
		
	}
	return NSMakeRange(NSNotFound, 0);
}


@end
