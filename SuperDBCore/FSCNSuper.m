/*   FSCNSuper.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNSuper.h"

@implementation FSCNSuper


- (void)dealloc
{
  [className release];
  [super dealloc];
}        


- (NSString *)description
{
  return @"keyword \"super\""; 
}


- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  nodeType = SUPER;
  className = [[coder decodeObjectForKey:@"className"] retain];
  isInClassMethod = [coder decodeBoolForKey:@"isInClassMethod"];
  return self;
}

- (id)initWithLocationInContext:(struct FSContextIndex)theLocationInContext className:(NSString *)theClassName isInClassMethod:(BOOL)incm
{
  self = [super initWithIdentifierString:@"self" locationInContext:theLocationInContext];
  
  if (self != nil) 
  {
    nodeType = SUPER;
    className = [theClassName retain];
    isInClassMethod = incm;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:className forKey:@"className"];
  [coder encodeBool:isInClassMethod forKey:@"isInClassMethod"];  
}  

@end
