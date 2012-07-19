/* FSNSDictionary.m Copyright (c) 2000-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSDictionary.h"
#import "FSBlock.h"
#import "FSMiscTools.h"
#import "FScriptFunctions.h"
#import "FSSystemPrivate.h"

@implementation NSDictionary(FSNSDictionary)

- (id)at:(id)aKey
{
  return [self objectForKey:aKey];
}


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

- (NSString *)printString
{
  NSMutableString *result = [NSMutableString stringWithString:@"#{ "];
  BOOL firstEntry = YES;

  for (id key in self)
  {
    if (firstEntry) firstEntry = NO;
    else            [result appendString:@",\n   "];
      
    [result appendString:printString(key)];
    [result appendString:@" -> "];
    [result appendString:printString([self objectForKey:key])];
  }
  
  if      ([self count] > 1)  [result appendString:@"\n"];
  else if ([self count] == 1) [result appendString:@" "];
  
  [result appendString:@"}"];
  
  return result;
}

@end
