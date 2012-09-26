//
//  JBShellCommandHistory.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-20.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBShellCommandHistory.h"

#define kCommandKey @"command"
#define kRangeKey @"range"

@implementation JBShellCommandHistory {
	NSUInteger _head, _currentCommand;
	NSMutableArray *_stack;
}


- (id)init {
    self = [super init];
    if (self) {
        _stack = [NSMutableArray array];
    }
    return self;
}


- (NSString *)description {
	return [NSString stringWithFormat:@"Command history:\n%@\nTop command: %@", _stack, [self topCommand]];
}


- (void)addCommand:(NSString *)command forRange:(NSRange)commandRange {
	
	NSDictionary *d = @{ kCommandKey : command, kRangeKey : NSStringFromRange(commandRange) };
	
	[_stack addObject:d];
}


- (id)moveToFirst {
	_currentCommand = 0;
	return self;
}


- (id)moveToLast {
	_currentCommand = [_stack count];// - 1;
	return self;
}


- (id)moveToPreviousCommand {
	if (_currentCommand > 0) {
		_currentCommand--;
	}
	return self;
}


- (id)moveToNextHistoryCommand {
	if (_currentCommand < [_stack count])
		_currentCommand++;
	return self;
}


- (NSString *)topCommand {
	return [[_stack lastObject] objectForKey:kCommandKey];
}


- (NSString *)currentCommand {
	return _currentCommand < [_stack count] ? [_stack[_currentCommand] objectForKey:kCommandKey] : @"";
}


- (NSString *)commandAtIndex:(NSUInteger)index {
	if (index >= [_stack count]) {
		return nil;
	}
	
	return [_stack[index] objectForKey:kCommandKey];
}


- (NSString *)commandForRange:(NSRange)range {
	for (NSDictionary *dictionary in _stack) {
		
		NSRange cRange = NSRangeFromString([dictionary objectForKey:kRangeKey]);
		if (RangeContainsRange(cRange, range)) {
			return [dictionary objectForKey:kCommandKey];
		}
		
		if ([[dictionary objectForKey:kRangeKey] isEqualToString:NSStringFromRange(range)]) {
			return [dictionary objectForKey:kCommandKey];
		}
	}
	return nil;
}


BOOL RangeContainsRange(NSRange a, NSRange b) {
	return (a.location <= b.location && NSMaxRange(a) >= NSMaxRange(b));
}


@end
