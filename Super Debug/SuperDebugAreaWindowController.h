//
//  SuperDebugAreaWindowController.h
//  Super Debug
//
//  Created by Jason Brennan on 12-07-19.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JBShellView;
@interface SuperDebugAreaWindowController : NSWindowController
@property (nonatomic, strong, readonly) JBShellView *shellView;
@property (nonatomic, strong) NSNetService *netService;
@property (copy) NSString *prompt;
@property (assign) BOOL disconnectedShell;
@end
