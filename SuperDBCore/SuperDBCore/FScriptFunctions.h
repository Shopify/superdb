/* FScriptFunctions.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  
 
#import <Foundation/Foundation.h>

extern NSString *FSExecutionErrorException; 
extern NSString *FSUserAbortedException; 

void  FSVerifClassArgs(NSString *methodName, NSInteger nbArgrs, ...);       
void  FSVerifClassArgsNoNil(NSString *methodName, NSInteger nbArgrs, ...);  

void  FSArgumentError(id argument, NSInteger index, NSString *expectedClass, NSString *methodName) __attribute__ ((noreturn)); 

void  FSExecError(NSString *errorStr) __attribute__ ((noreturn));

void  FSUserAborted(void) __attribute__ ((noreturn));
