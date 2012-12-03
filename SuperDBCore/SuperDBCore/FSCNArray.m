/*   FSCNArray.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNArray.h"

@implementation FSCNArray

- (void)dealloc
{
  for (NSUInteger i = 0; i < count; i++) [elements[i] release];
  free(elements);
  [super dealloc];
}

- (NSString *)description
{
  return @"Array literal"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:[NSArray arrayWithObjects:elements count:count] forKey:@"elements"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = ARRAY;
  NSArray *theElements = [coder decodeObjectForKey:@"elements"];
  count = [theElements count];
  elements = NSAllocateCollectable(count * sizeof(id), NSScannedOption);
  [theElements getObjects:elements];
  [theElements makeObjectsPerformSelector:@selector(retain)]; 

  return self;
}

- (id)initWithElements:(NSArray *)theElements
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = ARRAY;
    count = [theElements count];
    elements = NSAllocateCollectable(count * sizeof(id), NSScannedOption);
    [theElements getObjects:elements];
    [theElements makeObjectsPerformSelector:@selector(retain)]; 
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];

  for (NSUInteger i = 0; i < count; i++) [elements[i] translateCharRange:translation];
}

@end
