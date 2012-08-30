/* FSNSDictionary.h Copyright (c) 2000-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 
 
#import <Foundation/Foundation.h>

@class FSSystem;

@interface NSDictionary(FSNSDictionary)

- (id)at:(id)aKey;
- (void)inspect;
- (void)inspectIn:(FSSystem *)system __attribute__((deprecated));  // use inspectWithSystem: instead
- (void)inspectWithSystem:(FSSystem *)system;
- (void)inspectIn:(FSSystem *)system with:(NSArray *)blocks __attribute__((deprecated)); // use inspectWithSystem:blocks: instead
- (void)inspectWithSystem:(FSSystem *)system blocks:(NSArray *)blocks;
- (NSString *)printString;

@end
