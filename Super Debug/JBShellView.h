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



@interface JBShellView : NSTextView

@property (nonatomic, strong) NSString *prompt;
@property (nonatomic, copy) JBShellViewInputProcessingHandler inputHandler;

- (id)initWithFrame:(CGRect)frame prompt:(NSString *)prompt inputHandler:(JBShellViewInputProcessingHandler)inputHandler;

- (void)appendOutput:(NSString *)output; // used for finer-grained control of output
- (void)appendOutputWithNewlines:(NSString *)output; // Used for general output
- (void)showErrorOutput:(NSString *)output errorRange:(NSRange)errorRange;

- (void)appendAttributedOutput:(NSAttributedString *)attributedOutput;
- (void)appendAttributedOutputWithNewLines:(NSAttributedString *)attributedOutput;

+ (NSColor *)errorColor;
+ (NSColor *)successColor;

@end
