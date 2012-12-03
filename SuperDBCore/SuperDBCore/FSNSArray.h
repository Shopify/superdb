/* FSNSArray.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  
#import <Foundation/Foundation.h>

@class FSBlock, FSArray, FSSystem;
 
@interface NSArray(FSNSArray)

// User methods 
- (id)at:(id)index;
- (id)clone __attribute__((deprecated));
- (FSArray *)difference:(NSArray *)operand;
- (FSArray *)distinct;
- (FSArray *)distinctId;
- (void) do:(FSBlock *)operation;
- (FSArray *)index;
- (void)inspect; 
- (void)inspectIn:(FSSystem *)system __attribute__((deprecated));  // use inspectWithSystem: instead
- (void)inspectWithSystem:(FSSystem *)system;
- (void)inspectIn:(FSSystem *)system with:(NSArray *)blocks __attribute__((deprecated)); // use inspectWithSystem:blocks: instead
- (void)inspectWithSystem:(FSSystem *)system blocks:(NSArray *)blocks;
- (FSArray *)intersection:(NSArray *)operand;
- (id)operator_backslash:(FSBlock*)operand;
- (NSNumber *)operator_exclam:(id)anObject;
- (NSNumber *)operator_exclam_exclam:(id)anObject;
- (FSArray *)operator_greater_less:(id)operand;
- (FSArray *)operator_plus_plus:(NSArray *)operand;
- (FSArray *)prefixes;
- (NSString *)printString;
- (FSArray *)replicate:(NSArray *)operand;
- (FSArray *)reverse;
- (FSArray *)rotatedBy:(NSNumber *)operand;
- (FSArray *)scan:(FSBlock*)operand;
- (FSArray *)sort;
- (FSArray *)subpartsOfSize:(NSNumber *)operand;
- (FSArray *)transposedBy:(NSArray *)operand;
- (FSArray *)union:(NSArray *)operand;
- (FSArray *)where:(NSArray *)booleans;

@end
