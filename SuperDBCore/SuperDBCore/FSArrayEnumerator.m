//  FSArrayEnumerator.m Copyright (c) 2003-2009 Philippe Mougin.
//  This software is open source. See the license.

#import "FSArrayEnumerator.h"
#import "FSArray.h"

@implementation FSArrayEnumerator

- (void) dealloc
{
  [array release];
  [super dealloc];
}

- (FSArrayEnumerator *)initWithArray:(FSArray *)theArray reverse:(BOOL)reverse
{
  if ((self = [super init]))
  {
    NSUInteger count = [theArray count];
    iterationCompleted = (count == 0);
    array = [theArray retain];
    next = reverse ? count-1 : 0;
    increment = reverse ? -1 : 1;
    last = reverse ? 0 : count-1;
    return self;
  }
  return nil;
}

- (id)nextObject
{
  if (iterationCompleted) 
    return nil;
  else
  {
    id r = [array objectAtIndex:next];
    iterationCompleted = (next == last);
    next += increment;
    return r;
  }
}

- (FSArray *)allObjects
{
  if (iterationCompleted) 
    return [FSArray array];
  else
  {
    iterationCompleted = YES;
    if (increment == 1)
      return (FSArray *)[array subarrayWithRange:NSMakeRange(next, (last-next)+1)];
    else
      return (FSArray *)[array subarrayWithRange:NSMakeRange(0, next+1)];
  }
}

@end
