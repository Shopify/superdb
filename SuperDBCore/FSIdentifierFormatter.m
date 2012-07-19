/* FSIdentifierFormatter.m Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSIdentifierFormatter.h"
#import "FSCompiler.h"


@implementation FSIdentifierFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
  return anObject;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
  //NSLog(@"getObjectValue:");
  //NSLog(string);
  *anObject = [string copy];
  
  if ([FSCompiler isValidIdentifier:string] || [string length] == 0) return YES;
  else return NO;

}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
  //NSLog(*partialStringPtr);
  
  if ([FSCompiler isValidIdentifier:*partialStringPtr] || [*partialStringPtr length] == 0) return YES;
  else return NO;
}


@end
