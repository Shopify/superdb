/*   FSNumber.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSObject.h"
#import "FSNSNumber.h"

@class FSArray;
@class NSString; 
@class FSBoolean;
@class FSBlock;
 
@interface FSNumber:NSNumber
{ 
@public
  NSUInteger retainCount;
  double value;
}

//   USER METHODS

+ new;

- (NSNumber *)abs;
- (NSNumber *)arcCos;
- (NSNumber *)arcCosh;
- (NSNumber *)arcSin;
- (NSNumber *)arcSinh;
- (NSNumber *)arcTan;
- (NSNumber *)arcTanh;
- (NSDate *)asDate;
- (FSBoolean *)between:(NSNumber *)inf and:(NSNumber *)sup;
- (NSNumber *)bitAnd:(NSNumber *)operand; 
- (NSNumber *)bitOr:(NSNumber *)operand; 
- (NSNumber *)bitXor:(NSNumber *)operand; 
- (NSNumber *)ceiling;
- (NSNumber *)clone __attribute__((deprecated));
- (NSNumber *)cos;
- (NSNumber *)cosh;
- (NSNumber *)erf;
- (NSNumber *)erfc; 
- (NSNumber *)exp;
- (NSNumber *)floor;
- (NSNumber *)fractionPart;
- (NSNumber *)integerPart;
- (NSNumber *)ln;
- (NSNumber *)log;
- (NSNumber *)max:(NSNumber *)operand;
- (NSNumber *)min:(NSNumber *)operand; 
- (NSNumber *)negated;
- (NSNumber *)operator_asterisk:(NSNumber *)operand ;
- (NSNumber *)operator_hyphen:(NSNumber *)operand;
#if TARGET_OS_IPHONE
- (CGPoint)operator_less_greater:(NSNumber *)operand;
#else
- (NSPoint)operator_less_greater:(NSNumber *)operand;
#endif
- (NSNumber *)operator_plus:(id)operand;
- (NSNumber *)operator_slash:(NSNumber *)operand;
- (FSBoolean *)operator_equal:(id)operand;
- (FSBoolean *)operator_tilde_equal:(id)operand;
- (FSBoolean *)operator_greater:(NSNumber *)operand;
- (FSBoolean *)operator_greater_equal:(NSNumber *)operand;
- (FSBoolean *)operator_less:(id)operand;  
- (FSBoolean *)operator_less_equal:(NSNumber *)operand;
- (NSNumber *)raisedTo:(NSNumber *)operand;
- (NSNumber *)random;
- (NSNumber *)rem:(NSNumber *)operand;
- (NSNumber *)sign;
- (NSNumber *)sin;
- (NSNumber *)sinh;
- (NSNumber *)sqrt;
- (NSNumber *)tan;
- (NSNumber *)tanh;
- (NSNumber *)truncated;

//    SYSTEM METHODS 

+ numberWithDouble:(double)val;

- copyWithZone:(NSZone *)zone;
- (void) dealloc;
- (double) doubleValue;
- (BOOL) hasFrac_bool; // deprecated
//- (unsigned int) hash;
- (id) initWithCoder:(NSCoder *)aDecoder;
- (id)initWithChar:(char)val;
- (id)initWithUnsignedChar:(unsigned char)val;
- (id)initWithShort:(short)val;
- (id)initWithUnsignedShort:(unsigned short)val;
- (id)initWithInt:(int)val;
- (id)initWithUnsignedInt:(unsigned int)val;
- (id)initWithLong:(long)val;
- (id)initWithUnsignedLong:(unsigned long)val;
- (id)initWithFloat:(float)val;
- (id)initWithDouble:(double)val; // designated initializer
- (id)initWithBool:(BOOL)val;
- (BOOL) isEqual:anObject; 
- (void) release;
- (id) retain;
- (NSUInteger) retainCount;

// NSValue Class cluster primitives methods.
- (void)getValue:(void *)buffer;
- (const char *)objCType; 

@end
