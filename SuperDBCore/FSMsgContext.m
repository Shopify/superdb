/*   MsgContext.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSMsgContext.h"
#import <stdlib.h>
#import "build_config.h"
#import "FSNSProxy.h"
#import "FScriptFunctions.h"
#import "FSMiscTools.h"

@interface NSMethodSignature(UndocumentedNSMethodSignature)
+ (NSMethodSignature*) signatureWithObjCTypes:(const char *)types;
@end

@implementation FSMsgContext

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    tooLate = YES; 
  }
}

+ (FSMsgContext *) msgContext
{
  return [[[self alloc] init] autorelease];
}  

- (void) dealloc
{
  //NSLog(@"MsgContext dealloc");  

  if (initialized)
  {
    if (shouldConvertArguments) free(argumentTypes);
    //NSLog(@"releasing a signature with retainCount = %d", [signature retainCount]);
    [signature release];
  }
  [super dealloc];    
}

- (void)finalize 
{
  //NSLog(@"finalizing a MsgContext");  
  if (initialized && shouldConvertArguments) free(argumentTypes);
  [super finalize];
}

- (void) prepareForMessageWithReceiver:(id)receiver selector:(SEL)selector // May raise
{
  /// Temporary hack, for testing purposes only. Allows to send messages to the NSProxy class object
  /*if (receiver == [NSProxy class])
  {
    initialized             = YES;
    returnType              = '@';
    return_void             = NO;
    shouldConvertArguments  = NO;
    specialReturnType       = NO;
    return;
  }*/

  if (initialized)
  {    
    NSMethodSignature *oldSignature = signature;
    
    signature = [receiver methodSignatureForSelector:selector];
    
    if (signature == oldSignature)
    {
      return;
      // We are sure that cached information about the method is valid, so we can return safely.
    }
    else if (signature == nil)
    {
      // We should rarely be in this situation. It may happend if the receiver respond YES to respondsToSelector: but does return nil
      // when asked for the methodSignatureForSelector:, which may be the the case for the NSProxy *class* object (and subclass objects), which
      // is badly broken in the Mac OS X implementation.
      [oldSignature release];
      FSExecError([NSString stringWithFormat:@"can't invoke method %@", NSStringFromSelector(selector)]);
    }
    else
    {
      [signature retain];
      
      //NSLog(@"releasing an old signature with retainCount = %d", [oldSignature retainCount]);
      [oldSignature release];
    }  
    
    // Note that the test above on NSMethodSignature will provide performance gains only if NSMethodSignatures are uniquied by Cocoa.
    // This is the case for Mac OS X 10.3, but the doc says nothing about it. 
    // Update: no uniquing in 10.5.0.
  }
  else
  {
    signature = [[receiver methodSignatureForSelector:selector] retain];

    if (signature == nil)
    {
      // We should rarely be in this situation. It may happend if the receiver respond YES to respondsToSelector: but does return nil
      // when asked for the methodSignatureForSelector:, which may be the the case for the NSProxy *class* object (and subclass objects), which
      // is badly broken in the Mac OS X implementation.
      FSExecError([NSString stringWithFormat:@"can't invoke method %@", NSStringFromSelector(selector)]);
    }
  }
  
  {
    NSInteger i;
    NSInteger nbArg = [signature numberOfArguments];
    char argType[nbArg-2];
                    
    initialized             = YES;
    returnType              = FSEncode([signature methodReturnType]); 
    return_void             = (returnType == 'v');
    shouldConvertArguments  = NO;
    specialReturnType       = (returnType != 'v' && returnType != '@' && returnType != '#');
    unsuportedReturnType    = specialReturnType    && returnType != 'i' && returnType != 'd' && returnType != 'L'
                              && returnType != 'c' && returnType != '*' && returnType != 's' && returnType != 'l'
                              && returnType != 'q' && returnType != 'C' && returnType != 'I' && returnType != 'S'
                              && returnType != 'Q' && returnType != 'f' && returnType != ':' && returnType != 'w'
                              && returnType != 'x' && returnType != 'y' && returnType != 'z' && returnType != 'W'
                              && returnType != 'X' && returnType != 'Y' && returnType != '^' && returnType != 'B'
                              && returnType != '9';  
              
    for (i = 2; i < nbArg; i++)
    {
      argType[i-2] = FSEncode([signature getArgumentTypeAtIndex:i]); 
      if ( argType[i-2] != '@' && argType[i-2] != '#' ) shouldConvertArguments = YES;
    }
    if (shouldConvertArguments)
    {
      if (argumentTypes != NULL) free(argumentTypes);
      argumentTypes = malloc((nbArg-2)*sizeof(char));
      memcpy(argumentTypes, argType,nbArg-2);
    }
  }
}

- init
{
  if ((self = [super init]))
  {
    initialized = NO;
    
    //NSLog(@"MsgContext alloc+++++++++++++++++");  

    return self;
  }
  return nil;
}

-(NSInteger)unsuportedArgumentIndex
{
  NSUInteger i, numberOfArguments;

  if (!shouldConvertArguments) return -1;

  for (i = 0, numberOfArguments = [signature numberOfArguments]-2; i < numberOfArguments; i++)
    if ( argumentTypes[i] != '@' && argumentTypes[i] != '#' && argumentTypes[i] != 'i' && argumentTypes[i] != 'd' && argumentTypes[i] != 'L'
      && argumentTypes[i] != 'c' && argumentTypes[i] != '*' && argumentTypes[i] != 's' && argumentTypes[i] != 'l' && argumentTypes[i] != 'B'
      && argumentTypes[i] != 'q' && argumentTypes[i] != 'C' && argumentTypes[i] != 'I' && argumentTypes[i] != 'S'
      && argumentTypes[i] != 'Q' && argumentTypes[i] != 'f' && argumentTypes[i] != ':' && argumentTypes[i] != 'w'
      && argumentTypes[i] != 'W' && argumentTypes[i] != 'x' && argumentTypes[i] != 'X' && argumentTypes[i] != 'y'
      && argumentTypes[i] != 'Y' && argumentTypes[i] != 'z' && argumentTypes[i] != '^' && argumentTypes[i] != '9')
    {
      return i;
    }
  
  return -1;
}

-(BOOL)unsuportedReturnType
{
  return unsuportedReturnType;
}

@end
