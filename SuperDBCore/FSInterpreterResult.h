/* FSInterpreterResult.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  
#import <Foundation/Foundation.h>

extern NSString *FSInterpreterResultIllegalCallException;

@interface FSInterpreterResult : NSObject
{
  enum e_status {FS_OK,FS_SYNTAX_ERROR,FS_EXECUTION_ERROR} status; 
  NSRange errorRange;
  NSString *errorMessage;
  id result;
  NSArray *callStack;
}

-(NSArray *)callStack;
-(NSRange)errorRange;
-(NSString *)errorMessage;
-(void)inspectBlocksInCallStack; 
-(BOOL)isOk;  // Spelling mistake. Will be deprecated in favor of isOK, but will still be suported.
-(BOOL)isOK;
-(BOOL)isExecutionError;
-(BOOL)isSyntaxError;
-(id)result;

@end
