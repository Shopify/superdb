/*   BlockInspector.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.        */ 

#import <AppKit/AppKit.h>

@class NSMutableString;
@class FSBlock;
@class NSString;
@class NSSplitView;
@class NSScrollView;
@class NSButton;

@interface BlockInspector : NSObject
{
  FSBlock *inspectedObject;
  IBOutlet NSSplitView  *splitView;
  IBOutlet NSScrollView *sourceView;
  IBOutlet NSScrollView *messageView;
  BOOL edited; 
  NSWindow *argumentsWindow; 
}  


- activate;
- (IBAction)compil:sender;
- (BOOL)edited;
- initWithBlock:(FSBlock*)bl;
- (IBAction)run:sender;
- (void)setEdited:(BOOL)newVal;
- (void)showError:(NSString*)errorMessage; 
- (void)showError:(NSString*)errorMessage start:(NSInteger)firstCharacterIndex end:(NSInteger)lastCharacterIndex;
- (NSString *)source;
- update;

@end
