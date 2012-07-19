/*   CompilationResult.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCompilationResult.h"
#import <stdlib.h>

@implementation FSCompilationResult

+ compilationResultWithType:(enum CompilationResult_type)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last code:(FSCNBase *)theCode
{
  return [[[self alloc] initWithType:theType errorMessage:theErrorMessage errorFirstCharacterIndex:first errorLastCharacterIndex:last code:theCode] autorelease];
}

- (void)dealloc
{
  [errorMessage release];
  [code release];
  [super dealloc];        
}

- initWithType:(enum CompilationResult_type)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last code:(FSCNBase *)theCode
{
  if ((self = [super init]))
  {
    type = theType;
    errorMessage = [theErrorMessage retain];
    errorFirstCharacterIndex = first;
    errorLastCharacterIndex = last; 
    code = [theCode retain];
    return self;
  }    
  return nil;
}

@end
