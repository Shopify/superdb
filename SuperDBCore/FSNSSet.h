/* FSNSSet.h Copyright (c) 2004-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 
 
#import <Foundation/Foundation.h>

@class FSSystem;

@interface NSSet(FSNSSet)

- (void) inspect;
- (void)inspectIn:(FSSystem *)system __attribute__((deprecated));  // use inspectWithSystem: instead
- (void)inspectWithSystem:(FSSystem *)system;
- (void)inspectIn:(FSSystem *)system with:(NSArray *)blocks __attribute__((deprecated)); // use inspectWithSystem:blocks: instead
- (void)inspectWithSystem:(FSSystem *)system blocks:(NSArray *)blocks;

@end
