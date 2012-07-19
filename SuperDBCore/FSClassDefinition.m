/*   FSClassDefinition.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSClassDefinition.h"

@implementation FSClassDefinition

+ classDefinition
{
  return [[[self alloc] init] autorelease];
}

- (void) dealloc
{
  [ivarNames release];
  [methodHolders release];
  [super dealloc];
}

- (id)init
{
  self = [super init];
  if (self != nil) 
  {
    methodHolders = [[NSMutableArray alloc] init];
    ivarNames     = [[NSSet alloc] init];
  }
  return self;
}

- (NSSet *)ivarNames
{
  return ivarNames;
}

- (NSMutableArray *)methodHolders
{
  return methodHolders;
}

- (void)setIvarNames:(NSSet *)theIvarNames
{
  [theIvarNames retain];
  [ivarNames release];
  ivarNames = theIvarNames;
}

@end
