/* FSNSString.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#ifndef __FScript_FSNSString_H__
#define __FScript_FSNSString_H__

#import <Foundation/Foundation.h>

@class FSBlock;
@class FSArray;
@class FSBoolean;

@interface NSString (FSNSString)

- (FSArray *) asArray;
- (FSArray *) asArrayOfCharacters;
- (FSBlock *) asBlock;
- (FSBlock *) asBlockOnError:(FSBlock *)errorBlock;
- (id) asClass;
- (NSDate *) asDate;
- (NSString *)at:(NSNumber *)operand;
- (NSString *)clone __attribute__((deprecated));
- (id) connect __attribute__((deprecated));
- (id) connectOnHost:(NSString *)operand __attribute__((deprecated));
- (NSString *)max:(NSString *)operand;
- (NSString *)min:(NSString *)operand;
- (FSBoolean *)operator_equal:(id)operand;
- (FSBoolean *)operator_tilde_equal:(id)operand;  
- (FSBoolean *)operator_greater:(NSString *)operand;
- (FSBoolean *)operator_greater_equal:(NSString *)operand;
- (FSBoolean *)operator_less:(id)operand;
- (FSBoolean *)operator_less_equal:(NSString *)operand;
- (NSString *)operator_plus_plus:(NSString *)operand;
- (NSString *)printString;
- (NSString *)reverse;

@end

#endif /* __FScript_FSNSString_H__ */
