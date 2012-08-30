/*   NamedNumber.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNamedNumber.h"


@implementation FSNamedNumber

+ namedNumberWithDouble:(double)val name:(NSString *)theName
{
  return [[[self alloc] initWithDouble:val name:theName] autorelease]; 
}
 
- (void) dealloc
{
  [name release];
  [super dealloc];
}

- (NSString *)description
{
  if (name) return name;
  else      return [super description];
}  

- (double) doubleValue
{
  return value;
}

- initWithDouble:(double)val name:(NSString *)theName  //designated initializer
{
  if ((self = [super init]))
  {
    value = val;
    name = [theName retain];
    return self;
  }
  return nil;
}


///////////////// NSValue Class cluster primitives methods are implemented here

- (void)getValue:(void *)buffer
{
  *(double *)buffer = value;
}

- (const char *)objCType 
{
  return @encode(typeof(value));
}


@end
