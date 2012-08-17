//
//  JBTextEditorProcessor.m
//  TextEditing
//
//  Created by Jason Brennan on 12-06-04.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBTextEditorProcessor.h"

@implementation JBTextEditorProcessor


- (void)processString:(NSString *)originalString changedSelectionRange:(NSRange)selectionRange deletedString:(NSString *)deletedString insertedString:(NSString *)insertedString completionHandler:(JBTextEditorProcessorCompletionHandler)completionHandler {
	NSString *originalCopy = [originalString copy];
	
	
	NSString *processedString = [originalCopy stringByReplacingCharactersInRange:selectionRange withString:insertedString];
	NSRange newSelectionRange = selectionRange;
	
	
	if (![insertedString length]) {
		
		newSelectionRange.length = 0;
		
		NSString *pair = nil;
		if ([originalCopy length] != NSMaxRange(selectionRange)) {
			pair = [originalCopy substringWithRange:NSMakeRange(selectionRange.location, 2)];
		}
		
		if ([pair length]) {
			
			NSRange pairRange = NSMakeRange(selectionRange.location, 2);
			
			if ([pair isEqualToString:@"()"] ||
				[pair isEqualToString:@"[]"] ||
				[pair isEqualToString:@"{}"] ||
				[pair isEqualToString:@"“”"]) {
				processedString = [originalCopy stringByReplacingCharactersInRange:pairRange withString:@""];
			}
		}
		
		
	} else if ([deletedString length] && [insertedString length]) {
		// There was a block of text selected, now new text is trying to inserted over it..
		
		// If the inserted text is an opening pair, enclose the selection with opening+closing pair
		// else, the processedString prepared above is sufficient; just move the selection range.
		
		
		newSelectionRange.length += 2;
		if ([insertedString isEqualToString:@"("]) {
			
			NSString *enclosed = [self stringByEnclosingString:deletedString withOpeningString:@"(" closingString:@")"];
			processedString = [originalCopy stringByReplacingCharactersInRange:selectionRange withString:enclosed];
			
		} else if ([insertedString isEqualToString:@"{"]) {
			
			NSString *enclosed = [self stringByEnclosingString:deletedString withOpeningString:@"{" closingString:@"}"];
			processedString = [originalCopy stringByReplacingCharactersInRange:selectionRange withString:enclosed];
			
		} else if ([insertedString isEqualToString:@"["]) {
			
			NSString *enclosed = [self stringByEnclosingString:deletedString withOpeningString:@"[" closingString:@"]"];
			processedString = [originalCopy stringByReplacingCharactersInRange:selectionRange withString:enclosed];
			
		} else if ([self isDoubleQuoteCharacter:insertedString]) {
			
			NSString *enclosed = [self stringByEnclosingString:deletedString withOpeningString:@"“" closingString:@"”"];
			processedString = [originalCopy stringByReplacingCharactersInRange:selectionRange withString:enclosed];
			
		} else {
			newSelectionRange.length = 0;
			newSelectionRange.location = selectionRange.location + 1;
		}
		
		
		
	} else {
		// insertion...prepare the new selection ranges
		newSelectionRange.length = 0;
		newSelectionRange.location += 1;
		
		
		// check for the closing of a pair
		NSString *pair = nil;
		NSString *originalPair = nil;
		if ([originalCopy length] > NSMaxRange(selectionRange)) {
			pair = [processedString substringWithRange:NSMakeRange(selectionRange.location, 2)];
			originalPair = [originalCopy substringWithRange:NSMakeRange(selectionRange.location - 1, 2)];
		}
		
		if ([pair length]) {
			if ([pair isEqualToString:@"))"] ||
				[pair isEqualToString:@"]]"] ||
				[pair isEqualToString:@"}}"] ||
				[pair isEqualToString:@"””"]) {
				
				processedString = originalCopy;
			}
		}
		
		if ([originalPair length]) {
			NSLog(@"original pair: %@", originalPair);
			NSString *suffix = [originalPair substringFromIndex:1];
			NSLog(@"suffix: %@", suffix);
			
			// If the cursor is in whitespace or end of a line then it should insert the pair.
			NSRange foundRange = [suffix rangeOfString:@"\\s" options:NSRegularExpressionSearch];
			if (foundRange.location != NSNotFound) {
				NSLog(@"whitespace");
			}
		}
		
		
		// Check for the opening of a pair
		if ([insertedString isEqualToString:@"("]) {
			processedString = [processedString stringByReplacingCharactersInRange:newSelectionRange withString:@")"];
		} else if ([insertedString isEqualToString:@"{"]) {
			processedString = [processedString stringByReplacingCharactersInRange:newSelectionRange withString:@"}"];
		} else if ([insertedString isEqualToString:@"["]) {
			processedString = [processedString stringByReplacingCharactersInRange:newSelectionRange withString:@"]"];
		} else if ([insertedString isEqualToString:@"“"]) {
			processedString = [processedString stringByReplacingCharactersInRange:newSelectionRange withString:@"”"];
		}
		
	}
	
	
	// Main Queue code
	completionHandler(processedString, newSelectionRange);
	
}


- (NSString *)stringByEnclosingString:(NSString *)string withOpeningString:(NSString *)openingString closingString:(NSString *)closingString {
	return [NSString stringWithFormat:@"%@%@%@", openingString, string, closingString];
}


// returns YES even for closing curly quote
// using this for selection wrapping...if the user selected text and hit any of these characters, they probably want to wrap the text in curly quotes
- (BOOL)isDoubleQuoteCharacter:(NSString *)string {
	return [string isEqualToString:@"\""] || [string isEqualToString:@"“"] || [string isEqualToString:@"”"];
}


@end
