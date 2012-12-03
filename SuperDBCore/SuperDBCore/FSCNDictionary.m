/*   FSCNDictionary.m Copyright (c) 2009 Philippe Mougin. */
/*   This software is open source. See the license.       */

#import "FSCNDictionary.h"

@implementation FSCNDictionary

- (void)dealloc
{
  for (NSUInteger i = 0; i < count; i++) [entries[i] release];
  free(entries);
  [super dealloc];
}

- (NSString *)description
{
  return @"Dictionary literal"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:[NSArray arrayWithObjects:entries count:count] forKey:@"elements"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = DICTIONARY;
  NSArray *theElements = [coder decodeObjectForKey:@"elements"];
  count = [theElements count];
  entries = NSAllocateCollectable(count * sizeof(id), NSScannedOption);
  [theElements getObjects:entries];
  [theElements makeObjectsPerformSelector:@selector(retain)]; 

  return self;
}

- (id)initWithEntries:(NSArray *)theElements
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = DICTIONARY;
    count = [theElements count];
    entries = NSAllocateCollectable(count * sizeof(id), NSScannedOption);
    [theElements getObjects:entries];
    [theElements makeObjectsPerformSelector:@selector(retain)]; 
  }
  return self;
}

- (void)translateCharRange:(long)translation
{
  [super translateCharRange:translation];

  for (NSUInteger i = 0; i < count; i++) [entries[i] translateCharRange:translation];
}

@end

