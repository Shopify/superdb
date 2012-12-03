/* FSNSDate.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSDate.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
#import "FSNumber.h"
#import "FScriptFunctions.h"

#define VERIF_OP_NSDATE(METHOD) {if (![operand isKindOfClass:[NSDate class]]) FSArgumentError(operand,1,@"NSDate",METHOD);}

@implementation NSDate (FSNSDate)

+ (NSDate *) now
{
  return [self date]; 
}

- (id)clone
{
  return [[self copy] autorelease];
}    

- (id)max:(NSDate *)operand
{
  VERIF_OP_NSDATE(@"max:")
  
  return ([self compare:operand] == NSOrderedDescending ? self : operand);
}  

- (id)min:(NSDate *)operand
{
  VERIF_OP_NSDATE(@"min:")
  
  return ([self compare:operand] == NSOrderedDescending ? operand : self);
}  

- (FSBoolean *)operator_greater:(NSDate *)operand
{
  VERIF_OP_NSDATE(@">")
return [self compare:operand] == NSOrderedDescending ? fsTrue : fsFalse;
}

- (FSBoolean *)operator_greater_equal:(NSDate *)operand
{
  VERIF_OP_NSDATE(@">=")
return [self compare:operand] != NSOrderedAscending ? fsTrue : fsFalse;
}

- (NSNumber *) operator_hyphen:(NSDate *)operand
{
  VERIF_OP_NSDATE(@"-")
  return (id)[FSNumber numberWithDouble:
                       ([self timeIntervalSinceReferenceDate] -
                        [operand timeIntervalSinceReferenceDate])];
}

- (FSBoolean *)operator_less:(NSDate *)operand
{
  VERIF_OP_NSDATE(@"<")
  return [self compare:operand] == NSOrderedAscending ? fsTrue : fsFalse;
}

- (FSBoolean *)operator_less_equal:(NSDate *)operand
{
  VERIF_OP_NSDATE(@"<=")
return [self compare:operand] != NSOrderedDescending ? fsTrue : fsFalse;
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}


@end
