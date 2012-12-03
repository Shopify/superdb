/*   FSCNReturn.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNReturn.h"


@implementation FSCNReturn

- (void)dealloc
{
  [expression release];
  [super dealloc];
}

- (NSString *)description
{
  return @"Return statement"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:expression forKey:@"expression"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self       = [super initWithCoder:coder];
  nodeType   = RETURN;
  expression = [[coder decodeObjectForKey:@"expression"] retain];
  return self;
}

- (id)initWithExpression:(FSCNBase *)theExpression
{
  self = [super init];
  if (self != nil) 
  {
    nodeType   = RETURN;
    expression = [theExpression retain];
  }
  return self;
}

- (void)translateCharRange:(long)translation
{
  [super translateCharRange:translation];
  [expression translateCharRange:translation];
}


@end
