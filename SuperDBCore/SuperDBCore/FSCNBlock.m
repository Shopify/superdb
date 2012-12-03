/*   FSCNBlock.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBlock.h"
#import "BlockRep.h"

@implementation FSCNBlock

-(void)dealloc
{
  [blockRep release];
  [super dealloc];
}        

- (NSString *)description
{
  return [NSString stringWithFormat:@"Block literal: %@", [blockRep source]]; 
}


- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:blockRep forKey:@"blockRep"];  
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  nodeType = BLOCK;  
  blockRep = [[coder decodeObjectForKey:@"blockRep"] retain];
  return self;
}

- (id)initWithBlockRep:(BlockRep *)theBlockRep
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = BLOCK;
    blockRep = [theBlockRep retain];
  }
  return self;
}

@end
