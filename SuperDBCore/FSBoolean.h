/*   FSBoolean.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSObject.h"

@class True;
@class False;
@class FSBlock;

@interface FSBoolean : NSObject <NSCopying,NSCoding>
{}

+ (FSBoolean *) booleanWithBool:(BOOL)theBool;
+ (FSBoolean *) fsFalse;
+ (FSBoolean *) fsTrue;
- (FSBoolean *) and:(FSBlock *)operand;
- (id) autorelease;
- (FSBoolean *) clone __attribute__((deprecated));
- (id) copy;
- (id) copyWithZone:(NSZone *)zone;
- (NSUInteger) hash;
- (id) ifFalse:(FSBlock *)falseBlock;
- (id) ifFalse:(FSBlock *)falseBlock ifTrue:(FSBlock *)trueBlock;
- (id) ifTrue:(FSBlock *)trueBlock;
- (id) ifTrue:(FSBlock *)trueBlock ifFalse:(FSBlock *)falseBlock;
- (FSBoolean *) not;
- (FSBoolean *) operator_ampersand:(FSBoolean *)operand;
- (FSBoolean *) operator_bar:(FSBoolean *)operand;
- (FSBoolean *) operator_less:(id)operand;
- (NSNumber *)  operator_plus:(id)operand;
- (FSBoolean *) operator_equal:(id)operand;
- (FSBoolean *) operator_tilde_equal:(id)operand;
- (FSBoolean *) or:(FSBlock *)operand;
- (void) release;
- (id) retain;
- (NSUInteger) retainCount;
@end

@interface True: FSBoolean
{}
@end

@interface False: FSBoolean
{}
@end
