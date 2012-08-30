/* FSNSNumber.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.       */  

#import <Foundation/Foundation.h>

@class FSBoolean, FSNumber, FSBlock, FSArray;

@interface NSObject(FSNSNumber)

- (NSNumber *)abs;
- (NSNumber *)arcCos;
- (NSNumber *)arcCosh;
- (NSNumber *)arcSin;
- (NSNumber *)arcSinh;
- (NSNumber *)arcTan;
- (NSNumber *)arcTanh;
- (NSDate *)asDate;
- (FSBoolean *)between:(NSNumber *)a and:(NSNumber *)b;
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
- (FSArray *)iota;    // APL iota. Index origin = 0
- (NSNumber *)ln;
- (NSNumber *)log;
- (NSNumber *)max:(NSNumber *)operand;
- (NSNumber *)min:(NSNumber *)operand;
- (NSNumber *)negated;
- (NSNumber *)operator_asterisk:(NSNumber *)operand;
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
- (FSArray *)random:(FSNumber *)operand;
- (void)seedRandom;
- (NSNumber *)rem:(NSNumber *)operand;
- (NSNumber *)sin;
- (NSNumber *)sign; 
- (NSNumber *)sinh;
- (NSNumber *)sqrt;
- (NSNumber *)tan;
- (NSNumber *)tanh;
- (NSNumber *)truncated;
- (NSString *)unicharToString;
- (void)timesRepeat:(FSBlock *)operation;
- (void)to:(NSNumber *)stop do:(FSBlock *)operation;
- (void)to:(NSNumber *)stop by:(NSNumber *)step do:(FSBlock *)operation;

@end
