/*   FSNewlyAllocatedObjectHolder.m Copyright (c) 2001-2009 Philippe Mougin.     */
/*   This software is open source. See the license.                              */

#import "FSNewlyAllocatedObjectHolder.h"


@implementation FSNewlyAllocatedObjectHolder

+ (id)newlyAllocatedObjectHolderWithObject:(id)theObject
{
  return [[[self alloc] initWithObject:theObject] autorelease];
}

- (id)initWithObject:(id)theObject
{
  if ((self = [super init]))
  {
    object = theObject;
    return self;
  }
  return nil;
}

- (id)object {return object;}

- (NSString *)printString
{
  return [[@"Holder for a newly allocated " stringByAppendingString:NSStringFromClass(object->isa)] stringByAppendingString:@". Don't forget to initialize it (use an init... method) and to use the object returned by the init... method instead of this holder." ];
}

@end
