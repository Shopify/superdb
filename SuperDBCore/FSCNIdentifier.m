/*   FSCNIdentifier.m Copyright (c) 2007-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNIdentifier.h"
#import "FSKeyedUnarchiver.h"

@implementation FSCNIdentifier

-(void)dealloc
{
  [identifierString release];
  [super dealloc];
}        

- (NSString *)description
{
  return [NSString stringWithFormat:@"Identifier \"%@\"", identifierString]; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:identifierString       forKey:@"identifierString"];  
  [coder encodeInt32:locationInContext.index forKey:@"locationInContext.index"];
  [coder encodeInt32:locationInContext.level forKey:@"locationInContext.level"]; 
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  nodeType = IDENTIFIER;
  
  identifierString = [[coder decodeObjectForKey:@"identifierString"] retain];
  
  if ([coder isKindOfClass:[FSKeyedUnarchiver class]])
  { 
    locationInContext = [[(FSKeyedUnarchiver*)coder  symbolTableForCompiledCodeNode] findOrInsertSymbol:identifierString];      
  }
  else
  {
    locationInContext.index = [coder decodeInt32ForKey:@"locationInContext.index"];
    locationInContext.level = [coder decodeInt32ForKey:@"locationInContext.level"]; 
  }
  return self;
}

- (id)initWithIdentifierString:(NSString *)theIdentifierString locationInContext:(struct FSContextIndex)theLocationInContext
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = IDENTIFIER;
    identifierString  = [theIdentifierString retain];
    locationInContext = theLocationInContext;
  }
  return self;
}

@end
