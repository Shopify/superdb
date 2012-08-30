/* FSNSSet.m Copyright (c) 2000-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSSet.h"
#import "FSBlock.h"
#import "FSMiscTools.h"
#import "FScriptFunctions.h"
#import "FSSystemPrivate.h"

@implementation NSSet(FSNSSet)

- (void) inspect
{
  [self inspectWithSystem:nil];
}

- (void)inspectWithSystem:(FSSystem *)system
{
  FSVerifClassArgs(@"inspectWithSystem:",1,system,[FSSystem class],(NSInteger)1);
  [self inspectWithSystem:system blocks:nil];
}

- (void)inspectWithSystem:(FSSystem *)system blocks:(NSArray *)blocks;
{
  inspectCollection(self, system, blocks);
}

- (void) inspectIn:(FSSystem *)system
{
  FSVerifClassArgsNoNil(@"inspectIn:",1,system,[FSSystem class]);
  [self inspectWithSystem:system];
}

- (void) inspectIn:(FSSystem *)system with:(NSArray *)blocks
{
  [self inspectWithSystem:system blocks:blocks];
}

@end
