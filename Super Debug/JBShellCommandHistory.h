//
//  JBShellCommandHistory.h
//  Super Debug
//
//  Created by Jason Brennan on 12-07-20.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//
//  A stack represnting the history of our command shell.

#import <Foundation/Foundation.h>

@interface JBShellCommandHistory : NSObject

- (void)addCommand:(NSString *)command forRange:(NSRange)commandRange;
- (id)moveToFirst; // chainable
- (id)moveToLast; // chainable
- (id)moveToPreviousCommand; // chainable
- (id)moveToNextHistoryCommand; // chainable
- (NSString *)topCommand; // the most recently added command
- (NSString *)currentCommand; // the command at the current stack pointer
- (NSString *)commandAtIndex:(NSUInteger)index; // returns nil if index is out of bounds
- (NSString *)commandForRange:(NSRange)range;
@end
