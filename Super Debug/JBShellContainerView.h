//
//  JBShellContainerView.h
//  TextViewShell
//
//  Created by Jason Brennan on 12-07-14.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JBShellViewBlockTypedefs.h"

@class JBShellView;
@interface JBShellContainerView : NSView
@property (strong) JBShellView *shellView;


- (id)initWithFrame:(NSRect)frameRect shellViewClass:(Class)shellViewClass prompt:(NSString *)prompt shellInputProcessingHandler:(JBShellViewInputProcessingHandler)inputProcessingHandler;

@end
