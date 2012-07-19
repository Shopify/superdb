/*   FSCNPrecomputedObject.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNPrecomputedObject.h"
#import "FSMiscTools.h"

@implementation FSCNPrecomputedObject

-(void)dealloc
{
  [object release];
  [super dealloc];
}        

- (NSString *)description
{
  return [NSString stringWithFormat:@"Precomputed object: %@", printString(object)]; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:object forKey:@"object"];  
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  nodeType = OBJECT;  
  object = [[coder decodeObjectForKey:@"object"] retain];
  return self;
}

- (id)initWithObject:(id)theObject
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = OBJECT;
    object   = [theObject retain];
  }
  return self;
}

@end
