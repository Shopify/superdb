//
//  JBShellView.h
//  TextViewShell
//
//  Created by Jason Brennan on 12-07-14.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JBShellViewBlockTypedefs.h"

#define kJBShellViewErrorColor [JBShellView errorColor]
#define kJBShellViewSuccessColor [JBShellView successColor]


@class JBSuggestionWindowController;
@class JBShellCommandHistory;
@interface JBShellView : NSTextView

@property (nonatomic, strong) NSString *prompt;
@property (nonatomic, assign) NSUInteger commandStart; // The index for where input will be accepted in the textview (for subclasses to change)
@property (nonatomic, strong, readonly) JBShellCommandHistory *commandHistory;
@property (nonatomic, copy) JBShellViewInputProcessingHandler inputHandler;

@property (nonatomic, copy) JBShellViewDragHandler numberDragHandler;
@property (nonatomic, copy) JBShellViewDragHandler colorPickerDragHandler;

@property (nonatomic, strong) JBSuggestionWindowController *suggestionWindowController;

- (id)initWithFrame:(CGRect)frame prompt:(NSString *)prompt inputHandler:(JBShellViewInputProcessingHandler)inputHandler;

- (void)appendOutput:(NSString *)output; // used for finer-grained control of output
- (void)appendOutputWithNewlines:(NSString *)output; // Used for general output
- (void)showErrorOutput:(NSString *)output errorRange:(NSRange)errorRange;

- (void)appendAttributedOutput:(NSAttributedString *)attributedOutput;
- (void)appendAttributedOutputWithNewLines:(NSAttributedString *)attributedOutput;

+ (NSColor *)errorColor;
+ (NSColor *)successColor;


// Delayed output mode allows you to return from the inputHandler while still waiting for a task to complete, like a network operation.
// This way, tasks can be run asynchronously and the prompt won't be added until -endDelayedOutputMode is called.
- (void)beginDelayedOutputMode;
- (void)endDelayedOutputMode;

- (void)highlightText;

@end
