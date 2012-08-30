/*   FSNSMutableString.m Copyright (c) 2000 Philippe Mougin.  */
/*   This software is open source. See the license.       */  

#import <Foundation/Foundation.h>
#import "FSNSMutableString.h"
#import "Number_fscript.h"
#import "FScriptFunctions.h"
#import "FSNSStringPrivate.h"

@implementation NSMutableString (FSNSMutableString)

- (NSString *) clone
{
  return [[self mutableCopy] autorelease];
}  

- (void)insert:(NSString *)str at:(NSNumber *)index
{
  double ind;
  
  FSVerifClassArgsNoNil(@"insert:at:",2,str,[NSString class],index,[NSNumber class]);
         
  ind = [index doubleValue];

  if (ind < 0)
    FSExecError(@"argument 2 of method \"insert:at:\" must be a number "
                @"greater or equal to 0");
  if (ind > [self length])
    FSExecError(@"argument 2 of method \"insert:at:\" must be a number "
                @"less or equal to the length of the string");
  if (ind != (NSInteger)ind)
    FSExecError(@"argument 2 of method \"insert:at:\" must be an integer");

       
  [self insertString:str atIndex:(NSUInteger)ind];
}    

- (void)setValue:(id)operand
{
  VERIF_OP_NSSTRING(@"setValue:")
  [self setString:operand];
}  

@end
