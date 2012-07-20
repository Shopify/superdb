//
//  JBShellCommandHistory.m
//  Super Debug
//
//  Created by Jason Brennan on 12-07-20.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBShellCommandHistory.h"

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


- (void)addCommand:(NSString *)command {
	[_stack addObject:command];
}


- (id)moveToFirst {
	_currentCommand = 0;
	return self;
}


- (id)moveToLast {
	_currentCommand = [_stack count] - 1;
	return self;
}


- (id)moveToPreviousCommand {
	if (_currentCommand > 0) {
		_currentCommand--;
	}
	return self;
}


- (id)moveToNextHistoryCommand {
	if (_currentCommand < [_stack count] - 1) {
		_currentCommand++;
	}
	return self;
}


- (NSString *)topCommand {
	return [_stack lastObject];
}


- (NSString *)currentCommand {
	return _currentCommand < [_stack count] ? [_stack objectAtIndex:_currentCommand] : @"";
}


@end
