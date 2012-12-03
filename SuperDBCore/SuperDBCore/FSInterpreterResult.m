/* FSInterpreterResult.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSInterpreterResult.h"
#import "FSInterpreterResultPrivate.h"
#import "FSMiscTools.h"

NSString *FSInterpreterResultIllegalCallException = @"FSInterpreterResultIllegalCallException";

@implementation FSInterpreterResult

-(void)dealloc
{
  //NSLog(@"FSInterpreterResult dealloc");
  [errorMessage release];
  [result release];
  [callStack release];
  [super dealloc];
}    

-(NSArray *)callStack
{
  if (status == FS_OK) [NSException raise:FSInterpreterResultIllegalCallException format:@"illegal call of method \"callStack\" on an FSInterpreterResult object which is not denoting an error"];
  
  return callStack;
}

-(NSRange)errorRange        
{
  if (status == FS_OK) [NSException raise:FSInterpreterResultIllegalCallException format:@"illegal call of method \"errorRange\" on an FSInterpreterResult object which is not denoting an error"];

  return errorRange;
}

-(NSString *)errorMessage   
{
  if (status == FS_OK)  [NSException raise:FSInterpreterResultIllegalCallException format:@"illegal call of method \"errorMessage\" on an FSInterpreterResult object which is not denoting an error"];
  
  return errorMessage;   
} 

-(BOOL)isOk                 {return [self isOK];}
-(BOOL)isOK                 {return status == FS_OK;}
-(BOOL)isExecutionError     {return status == FS_EXECUTION_ERROR;}
-(BOOL)isSyntaxError        {return status == FS_SYNTAX_ERROR;}

-(id)result                 
{
  if (status != FS_OK)  [NSException raise:FSInterpreterResultIllegalCallException format:@"illegal call of method \"result\" on an FSInterpreterResult object denoting an error"];

  return result;
}   

-(void)inspectBlocksInCallStack 
{
  if (status == FS_OK) [NSException raise:FSInterpreterResultIllegalCallException format:@"illegal call of method \"inspectBlocksInCallStack\" on an FSInterpreterResult object which is not denoting an error"];
  
  if (callStack == nil) return;
  inspectBlocksInCallStack(callStack);
}

@end

@implementation FSInterpreterResult (FSInterpreterResultPrivate)

// This method may return an object initialized with other values than the ones provided. This happens when an error occurs while trying to retain the "theResult" parameter. In this case, this method returns an object representing an F-Script execution error.
+ (FSInterpreterResult *)interpreterResultWithStatus:(enum e_status)theStatus result:(id)theResult errorRange:(NSRange)theErrorRange errorMessage:(NSString *)theErrorMessage callStack:(NSArray *)theCallStack
{
  return [[[FSInterpreterResult alloc] initWithStatus:theStatus result:theResult errorRange:theErrorRange errorMessage:theErrorMessage callStack:theCallStack] autorelease];
}

// This method may return an object initialized with other values than the ones provided. This happens when an error occurs while trying to retain the "theResult" parameter. In this case, this method returns an object representing an F-Script execution error.
- (FSInterpreterResult *)initWithStatus:(enum e_status)theStatus result:(id)theResult errorRange:(NSRange)theErrorRange errorMessage:(NSString *)theErrorMessage callStack:(NSArray *)theCallStack
{
  if ((self = [super init]))
  {
    BOOL error = NO;
    
    @try 
    {
      result = [theResult retain]; // May throw an exception (example: NSAutoreleasePool throws an exception when sent retain)
    }
    @catch (id exception) 
    {
      error = YES;
      status = FS_EXECUTION_ERROR;
      errorRange = NSMakeRange(0,0);
      errorMessage = [[@"The following exception was raised when F-Script tried to retain an object: " stringByAppendingString:FSErrorMessageFromException(exception)] retain];
      callStack = nil; // We might be able to do better than that (i.e., providing more info related to the callStack). 
    }
   
    if (!error)
    {
      status = theStatus;
      errorRange = theErrorRange;
      errorMessage = [theErrorMessage retain];
      callStack = [theCallStack retain];
    }  
    return self;
  }
  return nil;
}

@end
