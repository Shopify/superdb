/*   FSBlockCompilationResult.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSBlockCompilationResult.h"

@implementation FSBlockCompilationResult

+ blockCompilationResultWithType:(enum FSBlockCompilationResultType)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last
{
  return [[[self alloc] initWithType:theType errorMessage:theErrorMessage errorFirstCharacterIndex:first errorLastCharacterIndex:last] autorelease];
}

- (void)dealloc
{
  [errorMessage release];
  [super dealloc];        
}

- initWithType:(enum FSBlockCompilationResultType)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last
{
  if ((self = [super init]))
  {
    type = theType;
    errorMessage = [theErrorMessage retain];
    errorFirstCharacterIndex = first;
    errorLastCharacterIndex = last; 
    return self;
  }    
  return nil;
}

@end
