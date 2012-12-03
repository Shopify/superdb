/* FScriptFunctions.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the licence.  */  

#import "FScriptFunctions.h"
#import "FSNSObject.h" 
#import "FSMiscTools.h"

NSString *FSExecutionErrorException = @"FSExecutionErrorException";
NSString *FSUserAbortedException    = @"FSUserAbortedException";

void FSVerifClassArgs(NSString *methodName, NSInteger nbArgs, ...)
{
  va_list pa;
  id currentArg;
  id currentClass;
  BOOL currentNilOK;
  NSInteger i;
  
  va_start(pa,nbArgs); 
  
  for (i = 1; i <= nbArgs; i++)
  {
    currentArg = va_arg(pa,id);
    currentClass = va_arg(pa,id);
    currentNilOK = va_arg(pa,NSInteger);
    //printf("\n%d\n",currentNilOK);
    
    if (((currentArg == nil) && (currentNilOK == 0)) || (currentArg!=nil && currentClass!=nil && ![currentArg isKindOfClass:currentClass]))
      FSArgumentError(currentArg,i,NSStringFromClass(currentClass),methodName);
  } 
  va_end(pa);
}  

void FSVerifClassArgsNoNil(NSString *methodName, NSInteger nbArgs, ...)
{
  va_list pa;
  id currentArg;
  id currentClass;
  NSInteger i;
  
  va_start(pa,nbArgs);
  
  for (i = 1; i <= nbArgs; i++)
  {
    currentArg = va_arg(pa,id);
    currentClass = va_arg(pa,id);
    
    if (currentArg == nil || (currentClass!=nil && ![currentArg isKindOfClass:currentClass]))
      FSArgumentError(currentArg,i,NSStringFromClass(currentClass),methodName);
  }
  va_end(pa);
}                       

void FSArgumentError(id argument, NSInteger index, NSString *expectedClass, NSString *methodName)
{
  if (argument == nil)
    FSExecError([NSString stringWithFormat:@"argument %ld of method \"%@\" is nil. An instance of %@ was expected", (long)index, methodName, expectedClass]);
  else
    FSExecError([NSString stringWithFormat:@"argument %ld of method \"%@\" is %@. An instance of %@ was expected", (long)index, methodName, descriptionForFSMessage(argument),expectedClass]);             
}

void FSExecError(NSString *errorStr)
{
  [NSException raise:FSExecutionErrorException format:@"error: %@", errorStr];
  exit(0); // to avoid a warning "noreturn function does return"
}  

void FSUserAborted(void)
{
  [NSException raise:FSUserAbortedException format:@"execution stopped by user\n"];
  exit(0); // to avoid a warning "noreturn function does return"
}

