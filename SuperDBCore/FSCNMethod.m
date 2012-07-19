//  FSCNMethod.m
/*   FSCNMethod.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMethod.h"
#import "FSCompiler.h"

@implementation FSCNMethod

-(void)dealloc
{
  [method release];
  [super dealloc];
}        

- (NSString *)description
{
  if (isClassMethod) return [NSString stringWithFormat:@"Method \"+ %@\"", [FSCompiler stringFromSelector:method->selector]]; 
  else               return [NSString stringWithFormat:@"Method \"- %@\"", [FSCompiler stringFromSelector:method->selector]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:method        forKey:@"method"];
  [coder encodeBool:  isClassMethod forKey:@"isClassMethod"];  
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  nodeType = METHOD;  
  method        = [[coder decodeObjectForKey:@"method"] retain];
  isClassMethod = [coder decodeBoolForKey:@"isClassMethod"];
  return self;
}

- (id)initWithMethod:(FSMethod *)theMethod isClassMethod:(BOOL)classMethod
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = METHOD;
    method   = [theMethod retain];
    isClassMethod = classMethod;
  }
  return self;
}

- (void)translateCharRange:(long)translation
{
  [super translateCharRange:translation];
  
  // We do not translate the code nodes in method->code as they are handled differently: they are already 
  // translated in order for the location information to be relative to the begining of the method body 
}

@end
