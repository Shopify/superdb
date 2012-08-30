
/*   BlockInspector.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "BlockInspector.h"
#import "FSBlock.h"
#import "FSCompiler.h"
#import "FSSymbolTable.h"
#import "BlockPrivate.h"
#import "BlockStackElem.h"
#import <AppKit/NSButton.h>
#import "FSMiscTools.h"
#import "FScriptFunctions.h"
#import "FSNSObject.h"
#import "FSVoid.h"
#import "FSObjectBrowser.h"
#import "FSSystem.h"
#import "FSSystemPrivate.h"
#import "FSInterpreter.h"
#import "FSArray.h"
#import "FSBlockCompilationResult.h"

static NSPoint topLeftPoint = {0,0}; // Used for cascading windows.
 
@implementation BlockInspector

- activate
{
  if (!splitView)
  {    
    [inspectedObject retain];
    [NSBundle loadNibNamed:@"blockInspector.nib" owner:self];
  }
  [[splitView window] makeKeyAndOrderFront:self];
  
  @try
  {
    // The call to isCompact may raise an FSExecutionErrorException
    if ([inspectedObject isCompact]) 
      [[sourceView documentView] setSelectedRange:NSMakeRange(1,[[[sourceView documentView] string] length]-1)];
  }
  @catch (NSException *exception)
  {
    if (! [[exception name] isEqualToString:FSExecutionErrorException]) 
      @throw;
  }
  
  [[splitView window] makeFirstResponder:[sourceView documentView]];
  return self;    
}

- (void)awakeFromNib
{
  [[sourceView documentView] setDelegate:self];
  [[sourceView documentView] setString:[inspectedObject printString]];
  [[sourceView documentView] setFont:[NSFont userFixedPitchFontOfSize:userFixedPitchFontSize()]];
  [[sourceView documentView] setUsesFindPanel:YES];
  [[sourceView documentView] setAllowsUndo:YES];
 
  [[messageView documentView] setFont:[NSFont userFixedPitchFontOfSize:userFixedPitchFontSize()]];
  [[messageView documentView] setUsesFindPanel:YES];
  
  [splitView display];
  topLeftPoint = [[splitView window] cascadeTopLeftFromPoint:topLeftPoint];
}  

- (IBAction) cancelArgumentsSheetAction:(id)sender
{
  [argumentsWindow orderOut:nil];
  [NSApp endSheet:argumentsWindow];
}

- (IBAction) compil:sender
{
  edited = YES; // to force compilation even if there is no change (is it useful ?).
  FSBlockCompilationResult *compilationResult = [inspectedObject compilation];
  
  switch (compilationResult->type)
  {
  case FSOKBlockCompilationResultType: [[messageView documentView] setString:@"Syntax ok"]; break;
  case FSErrorBlockCompilationResultType: 
    if (compilationResult->errorLastCharacterIndex == -1) 
      [self showError:compilationResult->errorMessage];
    else
      [self showError:[NSString stringWithFormat:@"%@, character %ld", compilationResult->errorMessage, (long)(compilationResult->errorFirstCharacterIndex)] start:compilationResult->errorFirstCharacterIndex end:compilationResult->errorLastCharacterIndex];
    break;
  }    
}

- (BOOL)edited
{  return edited;  }

- (IBAction)evaluateBlockAction:(id)sender
{
  NSForm *f = [[[[sender window] contentView] subviews] objectAtIndex:0];
  NSInteger nbarg = [f numberOfRows];
  FSArray *arguments = [FSArray arrayWithCapacity:nbarg]; // FSArray instead of NSMutableArray in order to support nil
  NSInteger i;
  FSInterpreter *interpreter;
  BOOL found;
  FSSystem *sys;
  FSSymbolTable *symbolTable = [inspectedObject symbolTable];
  
  while ([symbolTable parent]) symbolTable = [symbolTable parent];
  sys = [symbolTable objectForSymbol:@"sys" found:&found];
  NSAssert(found, @"\"sys\" object not found !");
  NSAssert([sys isKindOfClass:[FSSystem class]], @"\"sys\" object is not a FSSystem instance !");
        
  interpreter = [[[sys interpreter] retain] autorelease]; // Retain the interpreter to ensure it'll stay with us during the execution of the current method
  
  if (!interpreter)
  {
    NSRunAlertPanel(@"Error", @"Sorry, can't evaluate the arguments because there is no FSInterpreter associated with the block", @"OK", nil, nil,nil);
    [NSApp endSheet:[sender window]];
    [[sender window] orderOut:nil];
  }
  else
  {
    for (i = 0; i < nbarg; i++)
    {
      NSFormCell *cell = [f cellAtIndex:i];
      NSString *argumentString = [cell stringValue];
      FSInterpreterResult *result = [interpreter execute:argumentString];

      [[messageView documentView] setString:[NSString stringWithFormat:@"Evaluating argument %ld",(long)(i+1)]];
      [[messageView documentView] display];
      
      if ([result isOK])
        [arguments addObject:[result result]];
      else
      {
        NSMutableString *errorArgumentString = [NSString stringWithFormat:@"Argument %ld %@", (long)(i+1), [result errorMessage]];
        [[messageView documentView] setString:@""];
        [result inspectBlocksInCallStack];
        [f selectTextAtIndex:i];
        NSRunAlertPanel(@"Error", errorArgumentString, @"OK", nil, nil,nil);
        break;
      }
    }
    
    if (i == nbarg) // There were no error evaluating the arguments
    {
      FSInterpreterResult *interpreterResult;

      [[messageView documentView] setString:@"Evaluating block..."];
      [[messageView documentView] display];

      interpreterResult = [inspectedObject executeWithArguments:arguments];
      
      if ([interpreterResult isOK])
      {
        [argumentsWindow orderOut:nil];  
        [NSApp endSheet:[sender window]];

        if ([[interpreterResult result] isKindOfClass:[FSVoid class]])
          [[messageView documentView] setString:@""];
        else if (interpreter)
        {
          [[messageView documentView] setString:@""];
          [[FSObjectBrowser objectBrowserWithRootObject:[interpreterResult result] interpreter:interpreter] makeKeyAndOrderFront:nil];
        }  
      }
      else
      {
        [NSApp endSheet:[sender window]];
        [[sender window] orderOut:nil];
        [self showError:[interpreterResult errorMessage]]; // usefull if the call stack is empty
        [interpreterResult inspectBlocksInCallStack];
      }     
    }
  }
} 

- (void)dealloc
{
  //NSLog(@"BlockInspector dealloc");
  assert(!splitView); 
  [argumentsWindow close];   
  [super dealloc];
}     

- initWithBlock:(FSBlock*)bl
{
  if ([super init])
  {
    inspectedObject = bl;
    return self;
  }
  return nil;
}  

- (IBAction) run:sender
{ 
  NSInteger argumentCount;
  FSBlockCompilationResult *compilationResult;

  [[messageView documentView] setString:@""];
  
  compilationResult = [inspectedObject compilation];
  
  switch (compilationResult->type)
  {
  case FSOKBlockCompilationResultType: break;
  case FSErrorBlockCompilationResultType: 
    if (compilationResult->errorLastCharacterIndex == -1) 
      [self showError:compilationResult->errorMessage];
    else
      [self showError:[NSString stringWithFormat:@"%@, character %ld", compilationResult->errorMessage, (long)(compilationResult->errorFirstCharacterIndex)] start:compilationResult->errorFirstCharacterIndex end:compilationResult->errorLastCharacterIndex];
    return;
    break;
  }    

  argumentCount = [inspectedObject argumentCount];
  
  if (argumentCount == 0) 
  {
    id result = [inspectedObject guardedValue:nil];
    if (result && ![result isKindOfClass:[FSVoid class]])
    {
      BOOL found;
      FSSystem *sys;
      FSSymbolTable *symbolTable = [inspectedObject symbolTable];
      
      while ([symbolTable parent]) symbolTable = [symbolTable parent];
      sys = [symbolTable objectForSymbol:@"sys" found:&found];
      NSAssert(found, @"\"sys\" object not found !");
      NSAssert([sys isKindOfClass:[FSSystem class]], @"\"sys\" object is not a FSSystem instance !");
      
      if ([sys interpreter]) [[FSObjectBrowser objectBrowserWithRootObject:result interpreter:[sys interpreter]] makeKeyAndOrderFront:nil];
    }   
  }
  else
  {
    if (!argumentsWindow)
    {
      NSInteger i;
      NSInteger baseWidth  = 380;
      NSInteger baseHeight = argumentCount*(userFixedPitchFontSize()+17)+75;
      NSButton *sendButton;
      NSButton *cancelButton;
      NSForm *f;
      NSArray *argumentsNames;
      
      argumentsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,baseWidth,baseHeight) styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
      [argumentsWindow setTitle:@"Arguments"];
      [argumentsWindow setMinSize:NSMakeSize(230,baseHeight)];
      [argumentsWindow setMaxSize:NSMakeSize(1400,baseHeight)];
      
      f = [[[NSForm alloc] initWithFrame:NSMakeRect(20,60,baseWidth-40,baseHeight-80)] autorelease];
      [f setAutoresizingMask:NSViewWidthSizable];
      [f setInterlineSpacing:8]; 
      [[argumentsWindow contentView] addSubview:f]; // The form must be the first subview 
                                                    // (this is used by method evaluateBlockAction:)
      [argumentsWindow setInitialFirstResponder:f];                                              
                                                          
      sendButton = [[[NSButton alloc] initWithFrame:NSMakeRect(baseWidth/2,13,95,30)] autorelease];
      [sendButton setBezelStyle:1];
      [sendButton setTitle:@"Run"];   
      [sendButton setAction:@selector(evaluateBlockAction:)];
      [sendButton setTarget:self];
      [sendButton setKeyEquivalent:@"\r"];
      [[argumentsWindow contentView] addSubview:sendButton];
            
      cancelButton = [[[NSButton alloc] initWithFrame:NSMakeRect(baseWidth/2-95,13,95,30)] autorelease];
      [cancelButton setBezelStyle:1];
      [cancelButton setTitle:@"Cancel"];   
      [cancelButton setAction:@selector(cancelArgumentsSheetAction:)];
      [cancelButton setTarget:self];
      [cancelButton setKeyEquivalent:@"\e"]; 
      [[argumentsWindow contentView] addSubview:cancelButton];
      
      argumentsNames = [inspectedObject argumentsNames];
      
      for (i = 0; i < argumentCount; i++)
      {      
        [f addEntry:[argumentsNames objectAtIndex:i]];
      }
        
      [f setTextFont:[NSFont userFixedPitchFontOfSize:userFixedPitchFontSize()]];
      [f setTitleFont:[NSFont systemFontOfSize:systemFontSize()]];

      [f setAutosizesCells:YES]; 
      [f setTarget:sendButton];
      [f setAction:@selector(performClick:)];
      [f selectTextAtIndex:0];
    }
    [NSApp beginSheet:argumentsWindow modalForWindow:[messageView window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
  }  
}


- (void)setEdited:(BOOL)newVal
{
  edited = newVal;
}

- (void)showError:(NSString*)errorMessage 
{
  [self activate];
  
  if (argumentsWindow && [[sourceView  window] attachedSheet] == argumentsWindow)
  {
    [argumentsWindow orderOut:nil];
    [NSApp endSheet:argumentsWindow];
  }
  
  [[messageView documentView] setString:errorMessage];
  [[sourceView  window] makeFirstResponder:[sourceView documentView]];
}
      
- (void)showError:(NSString*)errorMessage start:(NSInteger)firstCharacterIndex end:(NSInteger)lastCharacterIndex
{
  [self activate];
  
  if (argumentsWindow && [[sourceView  window] attachedSheet] == argumentsWindow)
  {
    [argumentsWindow orderOut:nil];
    [NSApp endSheet:argumentsWindow];
  }

  [[messageView documentView] setString:errorMessage];
  [[sourceView documentView] setSelectedRange:NSMakeRange(firstCharacterIndex,lastCharacterIndex+1-firstCharacterIndex)];
  [[sourceView documentView] scrollRangeToVisible:[[sourceView documentView] selectedRange]];
  [[sourceView  window] makeFirstResponder:[sourceView documentView]];
}  
            
- (NSString*)source
{
  return [[[sourceView documentView] textStorage] string];
}  
 
- update
{
  NSTextView *documentView = [sourceView documentView];
  NSRange selectedRange = [documentView selectedRange];
  NSString *newString; 
  
  edited = NO; // (1)
  newString = [inspectedObject printString]; // The instruction (1) must be done before this one to avoid infinite recursion
  
  [documentView setString:newString];
  if (selectedRange.location + selectedRange.length <= [newString length])
    [documentView setSelectedRange:selectedRange]; 
    
  if (argumentsWindow)
  {
    if ([[sourceView  window] attachedSheet] == argumentsWindow)
    {
      [NSApp endSheet:argumentsWindow];
    }
    [argumentsWindow close];
    argumentsWindow = nil;
  }  
  
  return self;
}  

- (void)textDidChange:(NSNotification *)aNotification
{
  //NSLog(@"textDidChange:");
  edited = YES;
  if (argumentsWindow)
  {
    if ([[sourceView  window] attachedSheet] == argumentsWindow)
    {
      [NSApp endSheet:argumentsWindow];
    }
    [argumentsWindow close];
    argumentsWindow = nil;
  }  

  [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"BlockDidChangeNotification" object:inspectedObject] postingStyle:NSPostWhenIdle];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  if (edited)
    [inspectedObject sync];
  [[sourceView window] setDelegate:nil];    
  edited  = NO; 
  splitView   = nil;    
  sourceView  = nil;
  messageView = nil;
  [inspectedObject release];
} 

@end