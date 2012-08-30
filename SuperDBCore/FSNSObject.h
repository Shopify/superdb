
/* FSNSObject.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */

#import <Foundation/Foundation.h>

@class FSArray, FSBoolean, NSString, NSConnection, FSBlock, FSAssociation;

@protocol FSNSObject

// USER METHODS 
- (id)applyBlock:(FSBlock *)block;
- (id)classOrMetaclass;
- (FSArray *)enlist;
- (FSArray *)enlist:(NSNumber *)operand; 
- (FSBoolean *)operator_equal_equal:(id)operand;
- (FSAssociation *)operator_hyphen_greater:(id)operand;
- (FSBoolean *)operator_tilde_tilde:(id)operand; 
- (NSString *)printString;
@end

@interface NSObject(FSNSObject) <FSNSObject>

// USER METHODS

- (id)applyBlock:(FSBlock *)block;
- (FSArray *)enlist;
- (FSArray *)enlist:(NSNumber *)operand; 
- (FSBoolean *)operator_equal_equal:(id)operand;
- (FSAssociation *)operator_hyphen_greater:(id)operand;
- (FSBoolean *)operator_tilde_tilde:(id)operand;
- (NSString *)printString;
- (void)save; // may raise
- (void)save:(NSString *)operand; // may raise
- (void)throw __attribute__((deprecated)); 
- (NSConnection *)vend:(NSString *)operand __attribute__((deprecated));

// OTHER METHODS

+ replacementObjectForCoder:(NSCoder *)encoder;
- (id)classOrMetaclass;


@end