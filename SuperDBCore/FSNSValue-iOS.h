/* FSNSValue.h Copyright (c) 2003-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class FSBoolean;

@interface NSValue (FSNSValue) 

///////////////////////////////// USER METHODS /////////////////////////

// Common

- (id)clone __attribute__((deprecated));
- (FSBoolean *)operator_equal:(id)operand;
- (FSBoolean *)operator_tilde_equal:(id)operand;
- (NSString *)printString;

// CGPoint

- (CGRect)corner:(CGPoint)operand;
- (CGRect)extent:(CGPoint)operand;
- (CGFloat)x;
- (CGFloat)y;

// NSRange

+ (NSRange)rangeWithLocation:(NSUInteger)location length:(NSUInteger)length;
- (NSUInteger)length;
- (NSUInteger)location;

// CGRect

- (CGPoint)corner;
- (CGPoint)extent;
- (CGPoint)origin;

// CGSize

+ (CGSize)sizeWithWidth:(CGFloat)width height:(CGFloat)height;
- (CGFloat)height;
- (CGFloat)width;


@end
