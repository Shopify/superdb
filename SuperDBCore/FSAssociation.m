/*   FSAssociation.m Copyright (c) 2009 Philippe Mougin.   */
/*   This software is open source. See the license.        */  

#import "FSAssociation.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
  
@implementation FSAssociation

+ (id) associationWithKey:(id)theKey value:(id)theValue
{
  return [[[self alloc] initWithKey:theKey value:theValue] autorelease];
}

- (NSString *) description
{
  return [NSString stringWithFormat:@"%@ -> %@", key, value];
}

- (void) encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:key forKey:@"key"];
  [coder encodeObject:value forKey:@"value"];
}  

- (id) initWithCoder:(NSCoder *)coder
{
  self  = [super init];
  key   = [[coder decodeObjectForKey:@"key"] retain];
  value = [[coder decodeObjectForKey:@"value"] retain];
  return self;
}

- (id) initWithKey:(id)theKey value:(id)theValue
{
  self = [super init];
  if (self != nil) 
  {
    key   = [theKey retain];
    value = [theValue retain];
  }
  return self;
}

- (NSUInteger) hash
{
  return [key hash];
}

- (BOOL) isEqual:(id)anObject
{
  return ([anObject isKindOfClass:[FSAssociation class]] && [key isEqual:[anObject key]] && [value isEqual:[anObject value]]);
}

- (id) key
{
  return key;
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (id) value
{
  return value;
}

@end
