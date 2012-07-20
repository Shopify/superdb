//
//  JBShellView.m
//  TextViewShell
//
//  Created by Jason Brennan on 12-07-14.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBShellView.h"
#import "JBShellCommandHistory.h"


@interface JBShellView () <NSTextViewDelegate>
@property (nonatomic, assign) NSUInteger commandStart;
@property (nonatomic, assign) NSUInteger lastCommandStart;
@property (assign) BOOL delayedOutputMode;
@property (assign) BOOL userEnteredText;
@property (nonatomic, strong) JBShellCommandHistory *commandHistory;
@property (assign) CGPoint initialDragPoint;
@property (copy) NSString *initialString;
@property (strong) NSNumber *initialNumber;
@end

@implementation JBShellView


#pragma mark - Public API

- (id)initWithFrame:(CGRect)frame prompt:(NSString *)prompt inputHandler:(JBShellViewInputProcessingHandler)inputHandler
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		self.prompt = prompt;
		self.inputHandler = [inputHandler copy];
		[self setContinuousSpellCheckingEnabled:NO];
		
		[self setFont:[NSFont fontWithName:@"Menlo" size:18.0f]];
		[self setTextContainerInset:CGSizeMake(5.0f, 5.0f)];
		[self setDelegate:self];
		[self setAllowsUndo:YES];
		
		[self insertPrompt];
		
		self.commandStart = [[self string] length];
		self.commandHistory = [[JBShellCommandHistory alloc] init];
		self.initialDragPoint = CGPointZero;

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

- (void)appendOutput:(NSString *)output {
	[self moveToEndOfDocument:self];
	[self insertText:output];
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

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint {
	self.initialDragPoint = screenPoint;
	self.initialString = [[self string] substringWithRange:[self selectedRange]];
	self.initialNumber = [self numberFromString:self.initialString];
}


- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
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


- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
	session.animatesToStartingPositionsOnCancelOrFail = NO;
	self.initialDragPoint = CGPointZero;
	self.initialString = nil;
	self.initialNumber = nil;
}


- (NSNumber *)numberFromString:(NSString *)string {
	static NSNumberFormatter *formatter = nil;
	if (nil == formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setAllowsFloats:YES];
	}
	return [formatter numberFromString:string];
}


- (void)numberWasDragged:(NSNumber *)number toOffset:(CGSize)offset {
	// For now, we're just going to take an integer value out of the number
	// This will still work for floating point numbers but obviously we'll miss some of the precision
	
	// Maybe apply some kind of exponential growth (or something non-linear) to the x offset
	NSInteger offsetValue = [self.initialNumber integerValue] + (NSInteger)offset.width;
	NSNumber *updatedNumber = [NSNumber numberWithInteger:offsetValue];
	NSString *updatedString = [updatedNumber stringValue];
	NSString *numberString = [number stringValue];
	
	NSRange originalRange = [self selectedRange];
	if (originalRange.length < [updatedString length]) {
		originalRange.length = [updatedString length];
	} else if (originalRange.length > [updatedString length]) {
		originalRange.length = [numberString length];
	}
		
	[self insertText:updatedString replacementRange:originalRange];
	[self setSelectedRange:originalRange];
	
	if (self.numberDragHandler) {
		self.numberDragHandler([self tryAgainForRange:originalRange]);
	}
}


- (NSString *)commandFromHistoryForRange:(NSRange)range {
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


- (NSString *)tryAgainForRange:(NSRange)range {
	
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


#pragma mark - NSTextViewDelegate implementation

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	// Do not accept a modification outside the current command start
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
	if ([input length] > 0  /* && ![input isEqualToString:[self.commandHistory topCommand]] */) {
		NSRange range;
		
		range = NSMakeRange(_commandStart, [[self string] length] - _commandStart);
		
		[self.commandHistory addCommand:input forRange:range];
		[self.commandHistory moveToPreviousCommand];
	}
}

- (void)replaceCurrentCommandWith:(NSString *)command {
	[self setSelectedRange:NSMakeRange(self.commandStart, [[self string] length])];
	[self insertText:command];
	[self moveToEndOfDocument:self];
	[self scrollRangeToVisible:[self selectedRange]];
	self.userEnteredText = NO;
}


- (void)acceptInput {
	NSLog(@"Accepting input!");
	NSString *input = [[self string] substringFromIndex:self.commandStart];
	
	self.lastCommandStart = self.commandStart;
	// Check to see if the command has a length and that it was NOT the last item in the history, and add it
	if ([input length] > 0 /*&& ![input isEqualToString:[self.commandHistory topCommand]]*/) {
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
	[self insertText:@"\n"];
	if (nil != self.inputHandler) {
		self.inputHandler(input, self);
	}
	
	if (self.delayedOutputMode) {
		return; // The output will be finished when -endDelayedOutputMode is called
	}
	
	[self finishOutput];
	
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
}

@end
