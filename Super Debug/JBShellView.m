//
//  JBShellView.m
//  TextViewShell
//
//  Created by Jason Brennan on 12-07-14.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBShellView.h"
#import "JBShellCommandHistory.h"
#import "JBTextEditorProcessor.h"
#import <ParseKit/ParseKit.h>


@interface JBShellView () <NSTextViewDelegate>
@property (nonatomic, assign) NSUInteger commandStart;
@property (nonatomic, assign) NSUInteger lastCommandStart;
@property (assign) BOOL delayedOutputMode;
@property (assign) BOOL userEnteredText;
@property (nonatomic, strong) JBShellCommandHistory *commandHistory;
@property (assign) CGPoint initialDragPoint;
@property (assign) NSRange initialDragRangeInOriginalCommand;
@property (copy) NSString *initialString;
@property (strong) NSNumber *initialNumber;
@property (copy) NSString *initialDragCommandString;
@property (assign) NSRange initialDragCommandRange;
@property (assign) NSUInteger initialDragCommandStart;
@property (strong) JBTextEditorProcessor *textProcessor;

@property (strong) NSMutableDictionary *numberRanges;
@property (assign) NSRange currentlyHighlightedRange;

@end

@implementation JBShellView


#pragma mark - Public API

- (id)initWithFrame:(CGRect)frame prompt:(NSString *)prompt inputHandler:(JBShellViewInputProcessingHandler)inputHandler
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		self.prompt = prompt?: @"> ";
		self.inputHandler = [inputHandler copy];
		self.textProcessor = [JBTextEditorProcessor new];
		
		[self setContinuousSpellCheckingEnabled:NO];
		
		[self setFont:[NSFont fontWithName:@"Menlo" size:18.0f]];
		[self setTextContainerInset:CGSizeMake(5.0f, 5.0f)];
		[self setDelegate:self];
		[self setAllowsUndo:YES];
		
		[self insertPrompt];
		
		self.commandStart = [[self string] length];
		self.commandHistory = [[JBShellCommandHistory alloc] init];
		
		[[self window] setAcceptsMouseMovedEvents:YES];
		
		//NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:<#(NSRect)#> options:<#(NSTrackingAreaOptions)#> owner:<#(id)#> userInfo:<#(NSDictionary *)#>]
		
		self.numberRanges = [@{} mutableCopy];
		self.initialDragPoint = CGPointZero;
		[self resetInitialDragRange];

    }
    
    return self;
}


- (id)initWithFrame:(NSRect)frameRect {
	return [self initWithFrame:frameRect prompt:@"> " inputHandler:^(NSString *input, JBShellView *sender) {
		NSRange errorRange = [input rangeOfString:@"nwe"];
		if (errorRange.location != NSNotFound)
			[sender showErrorOutput:@"Did you mean: new" errorRange:errorRange];
		else {
			//[sender appendOutputWithNewlines:@"All good."];
			NSString *message = @"All good";
			NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:message];
			NSDictionary *attributes = @{ NSBackgroundColorAttributeName : kJBShellViewSuccessColor, NSForegroundColorAttributeName : [NSColor whiteColor] };
			[message enumerateSubstringsInRange:NSMakeRange(0, [message length]) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
				if ([substring isEqualToString:@"good"]) {
					[output addAttributes:attributes range:substringRange];
				}
			}];
			[sender appendAttributedOutput:output];
		}
	}];
}


+ (NSColor *)errorColor {
	return [NSColor colorWithCalibratedRed:1.000 green:0.314 blue:0.333 alpha:1.000];
}


+ (NSColor *)successColor {
	return [NSColor colorWithCalibratedRed:0.376 green:0.780 blue:0.000 alpha:1.000];
}


- (void)setInputHandler:(JBShellViewInputProcessingHandler)inputHandler {
	_inputHandler = [inputHandler copy];
	NSLog(@"SET");
}

- (void)appendOutput:(NSString *)output {
	[self moveToEndOfDocument:self];
	[super insertText:output];
	self.commandStart = [[self string] length];
	[self scrollRangeToVisible:[self selectedRange]];
}


- (void)appendOutputWithNewlines:(NSString *)output {
	[self appendOutput:[output stringByAppendingFormat:@"\n"]];
}


- (void)showErrorOutput:(NSString *)output errorRange:(NSRange)errorRange {
	
	errorRange.location += self.lastCommandStart;
	
	
	// I don't understand this conditional.
	if (NSMaxRange(errorRange) >= [[self string] length] && errorRange.length > 1) {
		errorRange.length--;
	}
	
	if ([self shouldChangeTextInRange:errorRange replacementString:nil]) {
		NSTextStorage *textStorage = [self textStorage];
		[textStorage beginEditing];
		NSColor *errorColor = kJBShellViewErrorColor;
		NSDictionary *attributes = @{ NSForegroundColorAttributeName : [NSColor whiteColor], NSBackgroundColorAttributeName : errorColor };
		[textStorage addAttributes:attributes range:errorRange];
		[textStorage endEditing];
		[self didChangeText];
	}
	
	
	[self appendOutputWithNewlines:[NSString stringWithFormat:@"\n%@", output]];
}


- (void)appendAttributedOutput:(NSAttributedString *)attributedOutput {
	[self moveToEndOfDocument:self];
	[[self textStorage] appendAttributedString:attributedOutput];
	self.commandStart = [[self string] length];
	[self scrollRangeToVisible:[self selectedRange]];
}


- (void)appendAttributedOutputWithNewLines:(NSAttributedString *)attributedOutput {
	
}


- (void)beginDelayedOutputMode {
	self.delayedOutputMode = YES;
}


- (void)endDelayedOutputMode {
	
	self.delayedOutputMode = NO;
	[self finishOutput];
	
}

#pragma mark - NSTextView overrides

- (void)keyDown:(NSEvent *)theEvent {
	if ([theEvent type] != NSKeyDown) {
		[super keyDown:theEvent];
		return;
	}
	
	if (![[theEvent characters] length]) {
		// accent input, for example
		[super keyDown:theEvent];
		return;
	}
	
	unichar character = [[theEvent characters] characterAtIndex:0];
	NSUInteger modifierFlags = [theEvent modifierFlags];
	BOOL arrowKey = (character == NSLeftArrowFunctionKey
					 || character == NSRightArrowFunctionKey
					 || character == NSUpArrowFunctionKey
					 || character == NSDownArrowFunctionKey);
	
	// Is the insertion point greater than commandStart and also (not shift+arrow)?
	if ([self selectedRange].location < self.commandStart && !(modifierFlags & NSShiftKeyMask && (arrowKey))) {
		[self setSelectedRange:NSMakeRange(self.commandStart, 0)];
		[self scrollRangeToVisible:[self selectedRange]];
	}
	
	// When the control key is held down
	if (modifierFlags & NSControlKeyMask) {
		switch (character) {
			case NSCarriageReturnCharacter:
				[self insertNewlineIgnoringFieldEditor:self];
				break;
			case NSDeleteCharacter:
				[self setSelectedRange:NSMakeRange(self.commandStart, [[self string] length])];
				[self delete:self];
				break;
			case NSUpArrowFunctionKey:
				[self replaceCurrentCommandWith:[[self.commandHistory moveToPreviousCommand] currentCommand]];
				break;
			case NSDownArrowFunctionKey:
				[self replaceCurrentCommandWith:[[self.commandHistory moveToNextHistoryCommand] currentCommand]];
				break;
			default:
				[super keyDown:theEvent];
				break;
		}
	} else {
		switch (character) {
			case NSCarriageReturnCharacter:
				[self acceptInput];
				break;
			default:
				[super keyDown:theEvent];
				break;
		}
	}
}


- (NSArray *)readablePasteboardTypes {
	return @[ NSPasteboardTypeString ];
}


#pragma mark - Movement

- (void)moveToBeginningOfLine:(id)sender {
	[self setSelectedRange:[self commandStartRange]];
}


- (void)moveToEndOfLine:(id)sender {
	[self moveToEndOfDocument:sender];
}


- (void)moveToBeginningOfParagraph:(id)sender {
	[self setSelectedRange:[self commandStartRange]];
}


- (void)moveToEndOfParagraph:(id)sender {
	[self moveToEndOfDocument:sender];
}


- (void)moveLeft:(id)sender {
	if ([self selectedRange].location > self.commandStart) {
		[super moveLeft:sender];
	}
}


- (void)moveUp:(id)sender {
	// If we are on the first line of the current command then replace current command with the previous one from history
	// else, apply the normal text editing behavior.
	
	NSUInteger oldLocation = [self selectedRange].location;
	[super moveUp:sender];
	
	if ([self selectedRange].location < self.commandStart || [self selectedRange].location == oldLocation) {
		// moved before the start of command entry OR not moved because we are on the first line of the text view
		
		NSUInteger promptBottomLocation = self.commandStart - [self.prompt length];
		NSUInteger promptEndLocation = self.commandStart;
		NSUInteger insertionLocation = [self selectedRange].location;
		
		if (insertionLocation >= promptBottomLocation && insertionLocation < promptEndLocation) {
			// Insertion point is on the prompt, so move to the start of the current command.
			[self setSelectedRange:[self commandStartRange]];
		} else {
			[self saveEditedCommand];
			[self replaceCurrentCommandWith:[[self.commandHistory moveToPreviousCommand] currentCommand]];
		}
	}
}


- (void)moveDown:(id)sender {
	// If we are on the last line of the current command then replace current command with the next history item
	// else, apply the normal text editing behavior.
	NSUInteger oldLocation = [self selectedRange].location;
	[super moveDown:sender];
	
	if ([self selectedRange].location == oldLocation || [self selectedRange].location == [[self string] length]) {
		// no movement OR move to end of the document because we are on the last line
		[self saveEditedCommand];
		[self replaceCurrentCommandWith:[[self.commandHistory moveToNextHistoryCommand] currentCommand]];
	}
}


//- (BOOL)dragSelectionWithEvent:(NSEvent *)event offset:(NSSize)mouseOffset slideBack:(BOOL)slideBack {
//	NSLog(@"%@ %@", [[self string] substringWithRange:[self selectedRange]], NSStringFromSize(mouseOffset));
//	
//	return YES;
//}


/* Declares what types of operations the source allows to be performed. Apple may provide more specific "within" values in the future. To account for this, for unrecongized localities, return the operation mask for the most specific context that you are concerned with. For example:
 switch(context) {
 case NSDraggingContextOutsideApplication:
 return ...
 break;
 
 case NSDraggingContextWithinApplication:
 default:
 return ...
 break;
 }
 */
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
	switch (context) {
		case NSDraggingContextWithinApplication: {
			return NSDragOperationNone;
			break;
		}
			
			
		default:
			return NSDragOperationNone;
	}
}

#pragma mark - Dragging


- (void)mouseDown:(NSEvent *)theEvent {
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseDown:theEvent];
		return;
	}
	
	self.initialDragPoint = [NSEvent mouseLocation];
	self.initialString = [[self string] substringWithRange:self.currentlyHighlightedRange];
	self.initialNumber = [self numberFromString:self.initialString];
	
	NSString *wholeText = [self string];
	
	// The problem is the command doesn't get updated in our history, so it breaks after the first use!!
	// Maybe, as a hack for now, I'll just try to grab the command as it is in our textView
	// We won't have it entered in the history now, but that's OK I guess. It's a messy change otherwise.
	
//	NSString *originalCommand = [self commandFromHistoryForRange:self.currentlyHighlightedRange];
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
	
	
	//[self numberWasDragged:number toOffset:offset];
	
	NSInteger offsetValue = [self.initialNumber integerValue] + (NSInteger)offset.width;
	NSNumber *updatedNumber = @(offsetValue);
	NSString *updatedNumberString = [updatedNumber stringValue];
	
	// Now do the replacement in the existing text
	//NSString *originalCommand = [self commandFromHistoryForRange:self.currentlyHighlightedRange];
	//NSRange originalRange = [[self string] rangeOfString:originalCommand];
	
	//NSString *currentCommand = [self currentCommandForRange:originalRange];
	NSString *replacedCommand = [self.initialDragCommandString stringByReplacingCharactersInRange:self.initialDragRangeInOriginalCommand withString:updatedNumberString];
	
	[super insertText:updatedNumberString replacementRange:self.currentlyHighlightedRange];
	self.currentlyHighlightedRange = NSMakeRange(self.currentlyHighlightedRange.location, [updatedNumberString length]);
	NSLog(@"REPLACED COMMAND IS: %@", replacedCommand);
	
	// Update the position of commandStart depending on how our (whole) string has changed.
	NSUInteger lengthDifference = [self.initialDragCommandString length] - [replacedCommand length];
	self.commandStart = self.initialDragCommandStart - lengthDifference;
	
	if (self.numberDragHandler) {
		self.numberDragHandler(replacedCommand);\
	}
}


- (void)__unused_draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
	//NSLog(@"dragged");
	
	NSString *selection = [[self string] substringWithRange:[self selectedRange]];
	
	if ([selection length] < 1) {
		return;
	}
	
	NSNumber *number = [self numberFromString:selection];
	if (nil == number) {
		return;
	}
	
	//NSLog(@"%@", number);
	
	CGFloat x = screenPoint.x - self.initialDragPoint.x;
	CGFloat y = screenPoint.y - self.initialDragPoint.y;
	CGSize offset = CGSizeMake(x, y);
	
	
	[self numberWasDragged:number toOffset:offset];
	
}

- (NSRange)rangeForNumberNearestToIndex:(NSUInteger)index {
	// parse this out right now...
	//NSString *originalCommand = self.initialDragCommandString;//[self commandFromHistoryForRange:self.currentlyHighlightedRange];
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
	//NSUInteger startLocation = originalRange.location;
	// look until the next \n, starting from the start location searching possibly until the end of the whole text
	NSString *wholeString = [self string];
	//	NSLog(@"Length: %lu, %@", [wholeString length], wholeString);
	
	
	NSRange lineRange = [wholeString lineRangeForRange:originalRange];
	NSString *lineString = [wholeString substringWithRange:lineRange];
	
	
	
	return [lineString substringFromIndex:[self.prompt length]];
	//	// Gross hack but my brain is lost today......
	//	NSUInteger untilEnd = 0;
	//	BOOL foundNext = YES;
	//	while (foundNext) {
	//		untilEnd++;
	//		NSUInteger currentIndex = startLocation + untilEnd;
	//		NSRange nextCharRange = NSMakeRange(currentIndex, 1);
	//		if ([wholeString length] >= NSMaxRange(nextCharRange)) {
	//			NSLog(@"Went over the whole string and didn't find the next newline! oops!");
	//			return nil;
	//		}
	//		if ([[wholeString substringWithRange:NSMakeRange(currentIndex, 1)] isEqualToString:@"\n"]) {
	//			foundNext = NO;
	//		}
	//	}
	//
	//	return [wholeString substringWithRange:NSMakeRange(startLocation, untilEnd)];
	//
	//	return nil;
	//	// attempt 2
	//	NSUInteger length = [wholeString length];
	//	NSRange newlineRange = NSMakeRange(0, length);
	//
	//	while (newlineRange.location != NSNotFound) {
	//
	//
	//
	//		newlineRange = [wholeString rangeOfString: @"\n" options:0 range:newlineRange];
	//
	//		if (newlineRange.location != NSNotFound) {
	//
	//
	//			if (originalRange.location < NSMaxRange(newlineRange)) {
	//				// We found the spot
	//				NSLog(@"NEWLINE RANGE IS %@", NSStringFromRange(newlineRange));
	//				NSRange currentCommandRange = NSMakeRange(originalRange.location, NSMaxRange(newlineRange) - NSMaxRange(originalRange));
	//				return [wholeString substringWithRange:currentCommandRange];
	//			}
	//			newlineRange = NSMakeRange(newlineRange.location + newlineRange.length, length - (newlineRange.location + newlineRange.length));
	//		}
	//	}
	//
	//	NSLog(@"Failed to find the current command!");
	//	return nil;
	//	NSUInteger toEnd = [wholeString length] - NSMaxRange(originalRange);
	//
	//	NSRange untilReturn = [[self string] rangeOfString:@"\n" options:kNilOptions range:NSMakeRange(startLocation, toEnd)];
	//	if (untilReturn.location == NSNotFound) {
	//		NSLog(@"Couldn't find the current command for range: %@!", NSStringFromRange(originalRange));
	//		return @"";
	//	}
	//
	//	return [[self string] substringWithRange:NSMakeRange(startLocation, untilReturn.location)];
}


- (void)__unused_draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint {
	self.initialDragPoint = screenPoint;
	self.initialString = [[self string] substringWithRange:[self selectedRange]];
	self.initialNumber = [self numberFromString:self.initialString];
	
	NSString *wholeText = [self string];
	NSString *originalCommand = [self commandFromHistoryForRange:[self selectedRange]];
	NSRange originalCommandRange = [wholeText rangeOfString:originalCommand options:kNilOptions];
	self.initialDragRangeInOriginalCommand = NSMakeRange([self selectedRange].location - originalCommandRange.location, [self selectedRange].length);
	
	//self.initialDragRangeInOriginalCommand = [originalCommand rangeOfString:self.initialString options:kNilOptions range:<#(NSRange)#>];
}

- (void)__unused_draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
	session.animatesToStartingPositionsOnCancelOrFail = NO;
	self.initialDragPoint = CGPointZero;
	self.initialString = nil;
	self.initialNumber = nil;
	[self resetInitialDragRange];
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
	
	// TODO: When the string changes, this potentially screws up where _commandStart is. This needs to be updated!
}


- (NSNumber *)numberFromString:(NSString *)string {
	static NSNumberFormatter *formatter = nil;
	if (nil == formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setAllowsFloats:YES];
	}
	return [formatter numberFromString:string];
}


- (void)resetInitialDragRange {
	self.initialDragRangeInOriginalCommand = NSMakeRange(NSUIntegerMax, NSUIntegerMax);
}


- (void)numberWasDragged:(NSNumber *)number toOffset:(CGSize)offset {
	// For now, we're just going to take an integer value out of the number
	// This will still work for floating point numbers but obviously we'll miss some of the precision
	
	// Maybe apply some kind of exponential growth (or something non-linear) to the x offset
	NSInteger offsetValue = [self.initialNumber integerValue] + (NSInteger)offset.width;
	NSNumber *updatedNumber = @(offsetValue);
	NSString *updatedString = [updatedNumber stringValue];
	NSString *numberString = [number stringValue];
	
	NSRange originalRange = [self selectedRange];
	if (originalRange.length < [updatedString length]) {
		originalRange.length = [updatedString length];
	} else if (originalRange.length > [updatedString length]) {
		originalRange.length = [numberString length];
	}
		
	[super insertText:updatedString replacementRange:originalRange];
	[self setSelectedRange:originalRange];
	
	if (self.numberDragHandler) {
		
		NSString *originalCommand = [self commandFromHistoryForRange:originalRange];
		NSString *updatedCommand = [originalCommand stringByReplacingCharactersInRange:self.initialDragRangeInOriginalCommand withString:updatedString];
		
		NSLog(@"Updated command: %@", updatedCommand);
		//self.numberDragHandler(updatedCommand);
	}
}


- (NSString *)__unused_commandFromHistoryForRange:(NSRange)range {
	// Look backwards starting at range.location and count how many ocurrences of the prompt string we find.
	// That's the index of where we need to look in the command history
	// Obviously this will fail if `prompt` appears elsewhere in the output, but for now that's avoidable.
	NSString *upToRange = [[self string] substringToIndex:range.location];
	
	NSUInteger count = 0, length = [upToRange length];
	NSRange searchRange = NSMakeRange(0, length);
	NSRange lastFound = searchRange;
	
	while(searchRange.location != NSNotFound) {
		searchRange = [upToRange rangeOfString:self.prompt options:0 range:searchRange];
		
		if(searchRange.location != NSNotFound) {
			searchRange = NSMakeRange(searchRange.location + searchRange.length, length - (searchRange.location + searchRange.length));
			count++;
			lastFound = NSMakeRange(searchRange.location, searchRange.length);
		}
	}
	NSLog(@"Last found instance was %@", NSStringFromRange(searchRange));
	return [self.commandHistory commandAtIndex:count];
}


- (NSString *)commandFromHistoryForRange:(NSRange)range {
	
	NSString *untilEnd = [[self string] substringFromIndex:range.location];
	NSRange newlineRange = [untilEnd rangeOfString:@"\n" options:kNilOptions];
	if (newlineRange.location == NSNotFound) {
		// We're on the last line of the document so there's nothing entered after us. Return everything from commandStart -> end of string
		return [[self string] substringFromIndex:self.commandStart];
	}
	
	
	
	
	return [self.commandHistory commandForRange:range];
	
	
	
	
	
	// There's been a return somewhere, which means there are existing commands, so we need to
	NSString *upTo = [[self string] substringToIndex:range.location];
	
	// Find the next newline

	NSRange found = [upTo rangeOfString:self.prompt options:NSBackwardsSearch];
	newlineRange = [[self string] rangeOfString:@"\n" options:kNilOptions range:NSMakeRange(NSMaxRange(found), [[self string] length] - NSMaxRange(found))];
	
	NSLog(@"start: %lu, loc: %lu, all length: %lu", found.location, newlineRange.location, [[self string] length]);
	
	NSString *result = [[self string] substringWithRange:NSMakeRange(NSMaxRange(found), newlineRange.location)];
	return result;
	
	
}


- (void)insertText:(id)insertString {
	NSLog(@"inserting: %@", insertString);
	
	NSRange range = [self selectedRange];
	if (![self textView:self shouldChangeTextInRange:NSMakeRange(range.location, range.length) replacementString:@""]) {
		return;
	}
	
	NSString *input = [self inputString];
	
	NSString *deletedText = @"";
	if (range.length > 0) {
		deletedText = [[self string] substringWithRange:range];
	}
	range.location -= self.commandStart;
	[self.textProcessor processString:input
				changedSelectionRange:range
						deletedString:deletedText
					   insertedString:insertString
					completionHandler:^(NSString *processedText, NSRange newSelectedRange) {
						NSLog(@"Processed: %@", processedText);
						[self replaceCurrentCommandWith:processedText];
						
						newSelectedRange.location += self.commandStart;
						[self setSelectedRange:newSelectedRange];
	}];
}


- (void)deleteBackward:(id)sender {
	
	NSRange range = [self selectedRange];
	NSRange backwardRange = range;
	if (!backwardRange.length) {
		backwardRange.location -= 1;
	}
	if (![self textView:self shouldChangeTextInRange:backwardRange replacementString:@""]) {
		return;
	}
	
	NSString *input = [self inputString];
	
	NSString *deletedText = [[self string] substringWithRange:range];
	if (range.length < 1) {
		deletedText = [[self string] substringWithRange:NSMakeRange(range.location - 1, 1)];
		range.length = 1;
		range.location -= 1;
	}
	
	range.location -= self.commandStart;
	
	[self.textProcessor processString:input
				changedSelectionRange:range
						deletedString:deletedText
					   insertedString:@""
					completionHandler:^(NSString *processedText, NSRange newSelectedRange) {
						
						[self replaceCurrentCommandWith:processedText];
						
						newSelectedRange.location += self.commandStart;
						[self setSelectedRange:newSelectedRange];
	}];
}


#pragma mark - NSTextViewDelegate implementation

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	// Do not accept a modification outside the current command start
	if (_initialNumber != nil) {
		return YES;
	}
	
	
	if (replacementString && affectedCharRange.location < self.commandStart) {
		NSBeep();
		return NO;
	} else {
		self.userEnteredText = YES;
		return YES;
	}
}


#pragma mark - Private API

- (NSRange)commandStartRange {
	return NSMakeRange(_commandStart, 0);
}


- (void)saveEditedCommand {
	if (!_userEnteredText) {
		return;
	}
	
	NSString *input = [[self string] substringFromIndex:_commandStart];
	if ([input length] > 0 && ![input isEqualToString:[self.commandHistory topCommand]]) {
		NSRange range;
		
		range = NSMakeRange(_commandStart, [[self string] length] - _commandStart);
		
		NSLog(@"Before save: %@", self.commandHistory);
		[self.commandHistory addCommand:input forRange:range];
		[self.commandHistory moveToPreviousCommand];
		NSLog(@"After save: %@", self.commandHistory);
	}
}

- (void)replaceCurrentCommandWith:(NSString *)command {
	[self setSelectedRange:NSMakeRange(self.commandStart, [[self string] length])];
	[super insertText:command];
	[self moveToEndOfDocument:self];
	[self scrollRangeToVisible:[self selectedRange]];
	self.userEnteredText = NO;
}


- (void)acceptInput {
	NSLog(@"Accepting input!");
	NSString *input = [self inputString];
	
	self.lastCommandStart = self.commandStart;
	// Check to see if the command has a length and that it was NOT the last item in the history, and add it
	if ([input length] > 0 && ![input isEqualToString:[self.commandHistory topCommand]]) {
		[self.commandHistory addCommand:input forRange:NSMakeRange(self.commandStart, [[self string] length] - self.commandStart)];
	}
	
	[self.commandHistory moveToLast];
	[self moveToEndOfDocument:self];
	[self insertNewlineIgnoringFieldEditor:self];
//	NSString *output = @"";
//	if (nil != self.inputHandler) {
//		output = self.inputHandler(input);
//	}
//	[self insertText:output];
	[super insertText:@"\n"];
	if (nil != self.inputHandler) {
		self.inputHandler(input, self);
	}
	
	if (self.delayedOutputMode) {
		return; // The output will be finished when -endDelayedOutputMode is called
	}
	
	[self finishOutput];
	
}


- (NSString *)inputString {
	return [[self string] substringFromIndex:self.commandStart];
}


- (void)insertPrompt {
	[super insertText:self.prompt];
}


- (void)finishOutput {
	[self insertNewlineIgnoringFieldEditor:self];
	[self insertPrompt];
	[self scrollRangeToVisible:[self selectedRange]];
	self.commandStart = [[self string] length];
	self.userEnteredText = NO;
	[[self undoManager] removeAllActions];
	
	[self highlightText];
}


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


- (void)mouseMoved:(NSEvent *)theEvent {
	//CGPoint cursorPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
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


@end
