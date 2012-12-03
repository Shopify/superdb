/*   Number.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import "Number_fscript.h"
#import "NumberPrivate.h"
#import "FSNSNumber.h"
#import "FScriptFunctions.h"
#import "FSArray.h"  
#import "FSBooleanPrivate.h"
#import <Foundation/Foundation.h>
#import <math.h>
#import "FSBlock.h"
#import "BlockPrivate.h"
#import "FSNumber.h"

@implementation Number  

///////////////////////////////   USER METHODS

+ new
{
  return [[self alloc] initWithDouble:0];
}

- (NSNumber *)abs
{ 
  assert(0);
}

- (NSNumber *)arcCos
{
  assert(0);
}

- (NSNumber *)arcCosh
{
  assert(0);
}

- (NSNumber *)arcSin
{
  assert(0);
}

- (NSNumber *)arcSinh
{
  assert(0);
}

- (NSNumber *)arcTan
{
  assert(0);
}

- (NSNumber *)arcTanh
{
  assert(0);
}

- (NSDate *)asDate
{
  assert(0);
}

- (FSBoolean *)between:(NSNumber *)a and:(NSNumber *)b
{
  assert(0);
}

- (NSNumber *)bitAnd:(NSNumber *)operand 
{
  assert(0);
}

- (NSNumber *)bitOr:(NSNumber *)operand 
{
  assert(0);
}

- (NSNumber *)bitXor:(NSNumber *)operand 
{
  assert(0);
}       

- (NSNumber *)ceiling
{
  assert(0);
}

- (NSNumber *)clone 
{ 
  assert(0);
}

- (NSNumber *)cos
{
  assert(0);
}

- (NSNumber *)cosh
{
  assert(0);
}

- (NSNumber *)erf
{
  assert(0);
}

- (NSNumber *)erfc
{
  assert(0);
}

- (NSNumber *)exp
{
  assert(0);
}  

- (NSNumber *)floor
{
  assert(0);
}  

- (NSNumber *)fractionPart
{
  assert(0);
}

- (NSNumber *)integerPart
{
  assert(0);
}

- (NSNumber *)ln
{ 
  assert(0);
}

- (NSNumber *)log
{
  assert(0);
}

- (NSNumber *)max:(NSNumber *)operand
{
  assert(0);
}  

- (NSNumber *)min:(NSNumber *)operand
{
  assert(0);
}  

- (NSNumber *) negated
{
  assert(0);
}

- (NSNumber *)operator_asterisk:(NSNumber *)operand 
{  
  assert(0);
}  

- (NSNumber *)operator_hyphen:(NSNumber *)operand
{
  assert(0);
}        

#if TARGET_OS_IPHONE
- (CGPoint)operator_less_greater:(NSNumber *)operand
{
  assert(0);
}
#else
- (NSPoint)operator_less_greater:(NSNumber *)operand
{
  assert(0);
}
#endif

- (NSNumber *)operator_plus:(id)operand
{
  assert(0);
} 
         
- (NSNumber *)operator_slash:(NSNumber *)operand
{
  assert(0);
}

- (FSBoolean *)operator_equal:(id)operand  
{ 
  assert(0);
}

- (FSBoolean *)operator_tilde_equal:(id)operand
{ 
  assert(0);
}

- (FSBoolean *)operator_greater:(NSNumber *)operand
{ 
  assert(0);
}

- (FSBoolean *)operator_greater_equal:(NSNumber *)operand 
{
  assert(0);
}    

- (FSBoolean *)operator_less:(id)operand
{
  assert(0);
} 
    
- (FSBoolean *)operator_less_equal:(NSNumber *)operand  
{
  assert(0);
} 

- (NSNumber *)raisedTo:(NSNumber *)operand 
{
  assert(0);
}  

- (NSNumber *)random
{
  assert(0);
} 
  
- (NSNumber *)rem:(NSNumber *)operand 
{  
  assert(0);
}

- (NSNumber *)sin
{
  assert(0);
}

- (NSNumber *)sign
{
  assert(0);
}

- (NSNumber *)sinh
{
  assert(0);
}

- (NSNumber *)sqrt
{
  assert(0);
}

- (NSNumber *)tan
{
  assert(0);
}

- (NSNumber *)tanh
{
  assert(0);
}

- (NSNumber *)truncated
{
  assert(0);
}

/*
- (void) testperf
{
   NSUInteger nb = 2000000;
   NSInteger *t = malloc(sizeof(double) * nb);
   NSUInteger i;
   NSDate *s;   
   NSDate *e; 
   double acu;
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

   for (i=0; i < nb; i++) t[i] = i;

   s = [NSDate date];
   
   acu = t[0];

   for (i=1; i < nb; i++) acu += t[i];

   e = [NSDate date];
  
    NSLog([NSString stringWithFormat:@"result = %.20g , time =%.20g",acu,[e timeIntervalSinceReferenceDate] - [s timeIntervalSinceReferenceDate]]);

   free(t);
   
   [pool release];
}
*/

/////////////////////////////////   SYSTEM METHODS  
             
+ (id) alloc
{
  return [self allocWithZone:nil];
}             
                                       
+ allocWithZone:(NSZone *)zone
{
  return (id)[FSNumber allocWithZone:zone];
}


+ numberWithDouble:(double)val
{
  return [[[self alloc] initWithDouble:val] autorelease];
}  

- copy                        
{
  assert(0);
}

- copyWithZone:(NSZone *)zone 
{
  assert(0);
}


/*- (NSString *) description
{
  return [NSString stringWithFormat:@"%.16g",value];
} */

- (double)doubleValue
{
  assert(0);
}    
  
- (BOOL) hasFrac_bool
{
  assert(0);
}  

- (id)initWithCoder:(NSCoder *)coder // this method is here for backward compatibility with old archives (when Number was not a subclass of NSNumber)
{
  assert(0);
}

- (id)initWithBool:(BOOL)val 
{
  assert(0);
}

- (id)initWithChar:(char)val 
{
  assert(0);
}

- initWithDouble:(double)val // designated initializer
{
  assert(0);
}

- (id)initWithFloat:(float)val { assert(0); }
- (id)initWithInt:(int)val { assert(0); }
- (id)initWithLong:(long)val { assert(0); }
- (id)initWithShort:(short)val { assert(0); }
- (id)initWithUnsignedChar:(unsigned char)val { assert(0); }
- (id)initWithUnsignedInt:(unsigned int)val { assert(0); }
- (id)initWithUnsignedLong:(unsigned long)val { assert(0); }
- (id)initWithUnsignedShort:(unsigned short)val { assert(0); }
   
- (BOOL) isEqual:anObject
{
  assert(0);
}
   
- (id)retain  
{   
  assert(0);
}

- (NSUInteger)retainCount  
{ 
  assert(0);
}

- (void)release  
{ 
  assert(0);
}  


///////////////// NSValue Class cluster primitives methods are implemented here

- (void)getValue:(void *)buffer
{
  assert(0);
}

- (const char *)objCType 
{
  assert(0);
}

@end
