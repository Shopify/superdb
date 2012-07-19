/*   FSCNAssignment.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNAssignment.h"

@implementation FSCNAssignment

- (void)dealloc
{
  [left release];
  [right release];
  [super dealloc];
}

- (NSString *)description
{
  return @"Assignment"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:left  forKey:@"left"];
  [coder encodeObject:right forKey:@"right"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = ASSIGNMENT;
  left     = [[coder decodeObjectForKey:@"left"] retain];
  right    = [[coder decodeObjectForKey:@"right"] retain];
  return self;
}

- (id)initWithLeft:(FSCNBase *)l right:(FSCNBase *)r 
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = ASSIGNMENT;
    left     = [l retain];
    right    = [r retain];
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  [left translateCharRange:translation];
  [right translateCharRange:translation];
}

@end