/* FSNSNumber.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSNumber.h"
#import "FSNumber.h"
#import "FScriptFunctions.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
#import "BlockPrivate.h"
#import "ArrayPrivate.h"
#import "ArrayRepDouble.h"

@interface NSNumber(FSNSNumberPrivate)
- (BOOL) hasFrac_bool;
@end

@implementation NSNumber(FSNSNumber)

- (NSNumber *)abs
{ 
  return [FSNumber numberWithDouble:fabs([self doubleValue])];
}

- (NSNumber *)arcCos
{
  double value = [self doubleValue];
  if((value < -1.0) || (value > 1.0)) FSExecError(@"receiver of message \"arcCos\" must be a number between -1 and 1");
  return [FSNumber numberWithDouble:(acos(value))];  
}

- (NSNumber *)arcCosh
{
  double value = [self doubleValue];
  if(value < 1.0) FSExecError(@"receiver of message \"arcCosh\" must be a number equal to or greater than 1");
  return [FSNumber numberWithDouble:(acosh(value))];  
}

- (NSNumber *)arcSin
{
  double value = [self doubleValue];
  if((value < -1.0) || (value > 1.0)) FSExecError(@"receiver of message \"arcSin\" must be a number between -1 and 1");
  return [FSNumber numberWithDouble:asin(value)];
}

- (NSNumber *)arcSinh
{
  double value = [self doubleValue];
  return [FSNumber numberWithDouble:asinh(value)];
}

- (NSNumber *)arcTan
{
  return [FSNumber numberWithDouble:atan([self doubleValue])];
}

- (NSNumber *)arcTanh
{
  double value = [self doubleValue];
  if((value <= -1.0) || (value >= 1.0)) FSExecError(@"receiver of message \"arcTanh\" must be a number greater than -1 and less than 1");
  return [FSNumber numberWithDouble:atanh([self doubleValue])];
}

- (NSDate *)asDate
{
  return [NSDate dateWithTimeIntervalSinceReferenceDate:[self doubleValue]];
}

- (FSBoolean *)between:(NSNumber *)a and:(NSNumber *)b
{
  FSVerifClassArgsNoNil(@"between:and:",2,a,[NSNumber class],b,[NSNumber class]);  
  if ([a compare:b] == NSOrderedDescending)
  {
    NSNumber *temp = a;
    a = b;
    b = temp;
  }
  return (([self compare:a] == NSOrderedAscending || [self compare:b] == NSOrderedDescending) ? (FSBoolean *)[FSBoolean fsFalse] : fsTrue);  
}        

- (NSNumber *)bitAnd:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"bitAnd:",1,operand,[NSNumber class]);
  NSNumber *zero = [NSNumber numberWithInt:0];
  if ([self compare:zero] == NSOrderedAscending) FSExecError(@"receiver of message \"bitAnd:\" must be a positive integer"); 
  if ([[self fractionPart] compare:zero] != NSOrderedSame) FSExecError(@"receiver of message \"bitAnd:\" must be an integer");
  if ([operand compare:zero] == NSOrderedAscending) FSExecError(@"argument of message \"bitAnd:\" must be a positive integer"); 
  if ([[operand fractionPart] compare:zero] != NSOrderedSame) FSExecError(@"argument of message \"bitAnd:\" must be an integer");
  
  /*
  NSNumber *uint_max = [NSNumber numberWithUnsignedInt:UINT_MAX];   
  if ([self compare:uint_max] != NSOrderedAscending) FSExecError([NSString stringWithFormat:@"receiver of message \"bitAnd:\" must be less or equal to %u",UINT_MAX]);
  if ([operand compare:uint_max] != NSOrderedAscending) FSExecError([NSString stringWithFormat:@"argument of message \"bitAnd:\" must be less or equal to %u",UINT_MAX]);
  
  Due to a bug in NSNumber (support for unsigned types is broken, Mac OS X 10.3) , the code above does not work. We use the code below instead.
  */
  double value = [self doubleValue];
  double operandValue = [operand doubleValue];
  if (value        > UINT_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"bitAnd:\" must be less or equal to %u",UINT_MAX]);
  if (operandValue > UINT_MAX) FSExecError([NSString stringWithFormat:@"argument of message \"bitAnd:\" must be less or equal to %u",UINT_MAX]);

  return [FSNumber numberWithDouble:[self unsignedLongValue] & [operand unsignedLongValue]];  
}

- (NSNumber *)bitOr:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"bitOr:",1,operand,[NSNumber class]);
  NSNumber *zero = [NSNumber numberWithInt:0];
  if ([self compare:zero] == NSOrderedAscending)              FSExecError(@"receiver of message \"bitOr:\" must be a positive integer"); 
  if ([[self fractionPart] compare:zero] != NSOrderedSame)    FSExecError(@"receiver of message \"bitOr:\" must be an integer");
  if ([operand compare:zero] == NSOrderedAscending)           FSExecError(@"argument of message \"bitOr:\" must be a positive integer"); 
  if ([[operand fractionPart] compare:zero] != NSOrderedSame) FSExecError(@"argument of message \"bitOr:\" must be an integer");
  
  /*
  NSNumber *uint_max = [NSNumber numberWithUnsignedInt:UINT_MAX];   
  if ([self compare:uint_max] != NSOrderedAscending)    FSExecError([NSString stringWithFormat:@"receiver of message \"bitOr:\" must be less or equal to %u",UINT_MAX]);
  if ([operand compare:uint_max] != NSOrderedAscending) FSExecError([NSString stringWithFormat:@"argument of message \"bitOr:\" must be less or equal to %u",UINT_MAX]);
  
  Due to a bug in NSNumber (support for unsigned types is broken, Mac OS X 10.3) , the code above does not work. We use the code below instead.
  */
  double value = [self doubleValue];
  double operandValue = [operand doubleValue];
  if (value        > UINT_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"bitOr:\" must be less or equal to %u",UINT_MAX]);
  if (operandValue > UINT_MAX) FSExecError([NSString stringWithFormat:@"argument of message \"bitOr:\" must be less or equal to %u",UINT_MAX]);

  return [FSNumber numberWithDouble:[self unsignedLongValue] | [operand unsignedLongValue]];  
}

- (NSNumber *)bitXor:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"bitXor:",1,operand,[NSNumber class]);
  NSNumber *zero = [NSNumber numberWithInt:0];
  if ([self compare:zero] == NSOrderedAscending)              FSExecError(@"receiver of message \"bitXor:\" must be a positive integer"); 
  if ([[self fractionPart] compare:zero] != NSOrderedSame)    FSExecError(@"receiver of message \"bitXor:\" must be an integer");
  if ([operand compare:zero] == NSOrderedAscending)           FSExecError(@"argument of message \"bitXor:\" must be a positive integer"); 
  if ([[operand fractionPart] compare:zero] != NSOrderedSame) FSExecError(@"argument of message \"bitXor:\" must be an integer");
  
  /*
  NSNumber *uint_max = [NSNumber numberWithUnsignedInt:UINT_MAX];   
  if ([self compare:uint_max] != NSOrderedAscending)    FSExecError([NSString stringWithFormat:@"receiver of message \"bitXor:\" must be less or equal to %u",UINT_MAX]);
  if ([operand compare:uint_max] != NSOrderedAscending) FSExecError([NSString stringWithFormat:@"argument of message \"bitXor:\" must be less or equal to %u",UINT_MAX]);
  
  Due to a bug in NSNumber (support for unsigned types is broken, Mac OS X 10.3) , the code above does not work. We use the code below instead.
  */
  double value = [self doubleValue];
  double operandValue = [operand doubleValue];
  if (value        > UINT_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"bitXor:\" must be less or equal to %u",UINT_MAX]);
  if (operandValue > UINT_MAX) FSExecError([NSString stringWithFormat:@"argument of message \"bitXor:\" must be less or equal to %u",UINT_MAX]);

  return [FSNumber numberWithDouble:[self unsignedLongValue] ^ [operand unsignedLongValue]];  
}

- (NSNumber *)ceiling { return [FSNumber numberWithDouble:ceil([self doubleValue])]; }

- (NSNumber *)clone { return [[self copy] autorelease]; }

- (NSNumber *)cos { return [FSNumber numberWithDouble:cos([self doubleValue])]; }

- (NSNumber *)cosh { return [FSNumber numberWithDouble:cosh([self doubleValue])]; } 

- (NSNumber *)erf  { return [FSNumber numberWithDouble:erf([self doubleValue])]; }

- (NSNumber *)erfc { return [FSNumber numberWithDouble:erfc([self doubleValue])]; }

- (NSNumber *)exp { return [FSNumber numberWithDouble:exp([self doubleValue])]; }  

- (NSNumber *)floor { return [FSNumber numberWithDouble:floor([self doubleValue])]; }  

- (NSNumber *)fractionPart
{
  double ip;
  return [FSNumber numberWithDouble:modf([self doubleValue],&ip)];
}

- (NSNumber *)integerPart
{
  double ip;
  modf([self doubleValue],&ip);
  return [FSNumber numberWithDouble:ip];
}

- (FSArray *)iota;    // APL iota. Index Origin = 0
{
  FSArray *r;
  double value = [self doubleValue];
  
  if (value > UINT_MAX)
    FSExecError([NSString stringWithFormat:@"receiver of message \"iota\" must be less or equal to %lu",(unsigned long)UINT_MAX]);
  if (value < 0)
    FSExecError(@"receiver of message \"iota\" must be non-negative");

  if (value < 1)
    return [FSArray array];
  else if (r = [[[FSArray alloc] initFrom:0 to:value-1 step:1] autorelease])
    return r;
  else
    FSExecError(@"not enough memory");
}  

- (NSNumber *)ln
{ 
  double value = [self doubleValue];
  if(value <= 0.0) FSExecError(@"receiver of message \"ln\" must be positive");
  return [FSNumber numberWithDouble:log(value)];
}

- (NSNumber *)log
{
  double value = [self doubleValue];
  if(value <= 0.0) FSExecError(@"receiver of message \"log\" must be positive");
  return [FSNumber numberWithDouble:log10(value)];
}


- (NSNumber *)max:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"max:",1,operand,[NSNumber class]);
  if ([self compare:operand] == NSOrderedDescending) return self;
  else return operand;
}  

- (NSNumber *)min:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"min:",1,operand,[NSNumber class]);
  if ([self compare:operand] == NSOrderedAscending) return self;
  else return operand;
}  

- (NSNumber *)negated { return [FSNumber numberWithDouble:-[self doubleValue]]; }

- (NSNumber *)operator_asterisk:(NSNumber *)operand 
{  
  FSVerifClassArgsNoNil(@"*",1,operand,[NSNumber class]);
  return [FSNumber numberWithDouble:[self doubleValue] * [operand doubleValue]];
}  

- (NSNumber *)operator_hyphen:(NSNumber *)operand
{  
  FSVerifClassArgsNoNil(@"-",1,operand,[NSNumber class]);
  return [FSNumber numberWithDouble:[self doubleValue] - [operand doubleValue]];
}  

#if TARGET_OS_IPHONE
- (CGPoint)operator_less_greater:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"<>",1,operand,[NSNumber class]);
  
  double selfValue = [self doubleValue];
  double operandValue = [operand doubleValue];
  
  if (selfValue    < -CGFLOAT_MAX || selfValue    > CGFLOAT_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"<>\" has a value of %g. Expected value must be in the range [%.15g, %.15g].",selfValue,(double)-CGFLOAT_MAX,(double)CGFLOAT_MAX]);
  if (operandValue < -CGFLOAT_MAX || operandValue > CGFLOAT_MAX) FSExecError([NSString stringWithFormat:@"argument of message \"<>\" has a value of %g. Expected value must be in the range [%.15g, %.15g].",selfValue,(double)-CGFLOAT_MAX,(double)CGFLOAT_MAX]);
  
  return CGPointMake(selfValue,operandValue); 
}
#else
- (NSPoint)operator_less_greater:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"<>",1,operand,[NSNumber class]);
  
  double selfValue = [self doubleValue];
  double operandValue = [operand doubleValue];
  
  if (selfValue    < -CGFLOAT_MAX || selfValue    > CGFLOAT_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"<>\" has a value of %g. Expected value must be in the range [%.15g, %.15g].",selfValue,(double)-CGFLOAT_MAX,(double)CGFLOAT_MAX]);
  if (operandValue < -CGFLOAT_MAX || operandValue > CGFLOAT_MAX) FSExecError([NSString stringWithFormat:@"argument of message \"<>\" has a value of %g. Expected value must be in the range [%.15g, %.15g].",selfValue,(double)-CGFLOAT_MAX,(double)CGFLOAT_MAX]);
  
  return NSMakePoint(selfValue,operandValue); 
}
#endif

- (NSNumber *)operator_plus:(id)operand
{
  if ([operand isKindOfClass:[NSNumber class]] || [operand isKindOfClass:[FSBoolean class]])
    return [FSNumber numberWithDouble:[self doubleValue] + [operand doubleValue]];
  else
    FSArgumentError(operand, 1, @"NSNumber or FSBoolean", @"+");
} 

- (NSNumber *)operator_slash:(NSNumber *)operand
{
  double operandValue;
  
  FSVerifClassArgsNoNil(@"/",1,operand,[NSNumber class]);
  operandValue = [operand doubleValue];
  if (operandValue == 0.0) FSExecError(@"division by zero");
  return [FSNumber numberWithDouble:[self doubleValue] / operandValue];
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (FSBoolean *)operator_greater:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@">",1,operand,[NSNumber class]);
  return ([self compare:operand] == NSOrderedDescending ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_greater_equal:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@">=",1,operand,[NSNumber class]);
  return ([self compare:operand] != NSOrderedAscending ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_less:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"<",1,operand,[NSNumber class]);
  return ([self compare:operand] == NSOrderedAscending ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_less_equal:(NSNumber *)operand
{
  FSVerifClassArgsNoNil(@"<=",1,operand,[NSNumber class]);
  return ([self compare:operand] != NSOrderedDescending ? fsTrue : fsFalse);
}    

- (NSNumber *)raisedTo:(NSNumber *)operand 
{
  double value, operandValue;
  
  FSVerifClassArgsNoNil(@"raisedTo:",1,operand,[NSNumber class]);
  
  operandValue = [operand doubleValue];
  value        = [self doubleValue];
  
  if (value < 0.0 && [operand hasFrac_bool])
    FSExecError(@"when the receiver of message \"raisedTo:\" is negative "
                @"the argument must be an integer"); 

  if (value == 0.0 && operandValue <= 0.0)
    FSExecError(@"when the receiver of message \"raisedTo:\" is zero "
                @"the argument must not be positive");  

  return [FSNumber numberWithDouble:pow(value, operandValue)];
}

- (NSNumber *)rand
{
  double value = [self doubleValue];
  if      (value > 2147483648) FSExecError([NSString stringWithFormat:@"receiver of message \"rand\" must be less or equal to 2 raisedTo:31 (i.e., 2147483648)"]);
  else if (value < 1)          FSExecError(@"receiver of message \"rand\" must not be less than 1");
                        
  return [FSNumber numberWithDouble:(random() % ((long)value))+1];
} 

- (NSNumber *)random
{
  double value = [self doubleValue];
  if      (value >= 2147483648) FSExecError([NSString stringWithFormat:@"receiver of message \"random\" must be less than 2 raisedTo:31 (i.e., 2147483648)"]);
  else if (value < 1)           FSExecError(@"receiver of message \"random\" must be greater or equal to 1");
                        
  return [FSNumber numberWithDouble:(random() % ((long)value))];
} 

- (FSArray *)random:(FSNumber *)operand
{
  FSVerifClassArgsNoNil(@"random:",1,operand,[NSNumber class]);
  
  double n = [operand doubleValue];
  double m = [self doubleValue];

  if (n > UINT_MAX) FSExecError([NSString stringWithFormat:@"argument of method \"random:\" must be less or equal to %lu",(unsigned long)UINT_MAX]);
  if (m < n) FSExecError(@"receiver of message \"random:\" must be greater or equal to the argument");
  if (floor(m) != m) FSExecError(@"receiver of message \"random:\" must be an integer");
  if (floor(n) != n) FSExecError(@"argument of method \"random:\" must be an integer");
  
  // We put n black balls and m-n white balls into a container. 
  // Then we randomly extract balls and put them away until the n black balls are out of the container.  
  
  ArrayRepDouble *rep = [[ArrayRepDouble alloc] initWithCapacity:n]; 
  if (rep == nil) FSExecError(@"not enough memory");

  FSArray *result = [[[FSArray alloc] initWithRepNoRetain:rep] autorelease];
  double blackBallCount = n;
  double whiteBallCount = m-n;
  double i = 0;
  
  while (blackBallCount > 0)
  {
    if (drand48() <= blackBallCount / (blackBallCount + whiteBallCount))
    {
      blackBallCount--;
      [result addObject:[FSNumber numberWithDouble:i]];
    }
    else whiteBallCount--;
    i++;
  }
  
  // Now we shuffle the result 
  if (n == 0) return result;
  for (NSUInteger j = n-1; j != 0; j--) [result exchangeObjectAtIndex:j withObjectAtIndex:(random() % (j+1))];
  
  return result;  
}

- (NSNumber *)rem:(NSNumber *)operand 
{  
  double operandValue;
  FSVerifClassArgsNoNil(@"rem:",1,operand,[NSNumber class]);
  operandValue = [operand doubleValue];
  if (operandValue == 0.0) FSExecError(@"argument of method \"rem:\" must not be zero");
  return [FSNumber numberWithDouble:fmod([self doubleValue],operandValue)];
}

- (void) seedRandom
{
  double value = [self doubleValue];
  if (value > ULONG_MAX) FSExecError([NSString stringWithFormat:@"receiver of message \"seedRandom\" must be less or equal to ULONG_MAX (i.e., %lu)",(unsigned long)ULONG_MAX]);
  
  srand48(value);
  srandom(value); 
}

- (NSNumber *)sin { return [FSNumber numberWithDouble:sin([self doubleValue])]; }

- (NSNumber *)sign
{
  double value = [self doubleValue];
  if      (value > 0) return [FSNumber numberWithDouble:1];
  else if (value < 0) return [FSNumber numberWithDouble:-1];
  else                return [FSNumber numberWithDouble:0];
}

- (NSNumber *)sinh { return [FSNumber numberWithDouble:sinh([self doubleValue])];}

- (NSNumber *)sqrt
{
  double value = [self doubleValue];
  if(value < 0.0) FSExecError(@"receiver of message \"sqrt\" must not be negative");
             
  return [FSNumber numberWithDouble:sqrt(value)];
}

- (NSNumber *)tan { return [FSNumber numberWithDouble:tan([self doubleValue])]; }

- (NSNumber *)tanh { return  [FSNumber numberWithDouble:tanh([self doubleValue])]; }

- (NSNumber *)truncated
{
  double value = [self doubleValue];
  return [FSNumber numberWithDouble:(value > 0 ? floor(value) : ceil(value))];  
}

- (NSString *)unicharToString
{
  unichar character;
  double value = [self doubleValue];
  
  if (value > 65535 || value < 0) 
    FSExecError(@"receiver of message \"unicharToString\" must be in the range [0,65535]");
  
  character = value;
  return [NSString stringWithCharacters:&character length:1];
}

- (void)timesRepeat:(FSBlock *)operation
{
  double value = [self doubleValue];
  
  FSVerifClassArgsNoNil(@"timesRepeat:",1,operation,[FSBlock class]);  
  if (value < 0) FSExecError(@"receiver of message \"timesRepeat:\" must not be negative");  
  if (floor(value) != value) FSExecError(@"receiver of message \"timesRepeat:\" must be an integer");
  if ([operation argumentCount] != 0) FSExecError(@"argument of method \"timesRepeat:\" must be a block with no argument");
  
  while (value-- > 0) [operation value];
}

- (void)to:(NSNumber *)stop do:(FSBlock *)operation 
{  
  FSVerifClassArgsNoNil(@"to:do:",2,stop,[NSNumber class],operation,[FSBlock class]);
  if ([operation argumentCount] > 1) FSExecError(@"argument 2 of method \"to:do:\" must be a block with zero or one argument");
  
  [operation evaluateWithDoubleFrom:[self doubleValue] to:[stop doubleValue] by:1];
}

- (void)to:(NSNumber *)stop by:(NSNumber *)step do:(FSBlock *)operation  
{  
  FSVerifClassArgsNoNil(@"to:by:do:",3,stop,[NSNumber class],step,[NSNumber class],operation,[FSBlock class]);
  
  if ([operation argumentCount] > 1) FSExecError(@"argument 3 of method \"to:by:do:\" must be a block with zero or one argument");
  if ([step doubleValue] == 0) FSExecError(@"argument 2 of method \"to:by:do:\" must not be zero");
  
  [operation evaluateWithDoubleFrom:[self doubleValue] to:[stop doubleValue] by:[step doubleValue]];
}

@end

@implementation NSNumber(FSNSNumberPrivate)

- (BOOL) hasFrac_bool
{
  double value = [self doubleValue];
  return (value != floor(value));
}  

@end
