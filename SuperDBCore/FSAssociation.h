/*   FSAssociation.h Copyright (c) 2009 Philippe Mougin.   */
/*   This software is open source. See the license.        */  

#import <Foundation/Foundation.h>

@class FSBoolean;

@interface FSAssociation : NSObject <NSCoding>
{
  id key;
  id value;
}

+ (id) associationWithKey:(id)theKey value:(id)theValue;

- (NSString *) description;
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;
- (id) initWithKey:(id)theKey value:(id)theValue;
- (BOOL) isEqual:(id)anObject;
- (id) key;
- (FSBoolean *) operator_equal:(id)operand;
- (FSBoolean *) operator_tilde_equal:(id)operand;
- (id) value;

@end
