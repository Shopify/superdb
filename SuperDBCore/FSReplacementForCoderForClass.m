/*   ReplacementForCoderForClass.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSReplacementForCoderForClass.h"
#import <Foundation/Foundation.h>

void __attribute__ ((constructor)) initializeFSReplacementForCoderForClass(void) 
{
  [NSKeyedUnarchiver setClass:[FSReplacementForCoderForClass class] forClassName:@"ReplacementForCoderForClass"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"ReplacementForCoderForClass" asClassName:@"FSReplacementForCoderForClass"];  
#endif
}

@implementation FSReplacementForCoderForClass

- awakeAfterUsingCoder:(NSCoder *)aCoder
{
  id r;
  
  [self autorelease];
  r = NSClassFromString(className);
  if (r == nil)
  {
    NSLog(@"class %@ not linked !!!",className);
    return [NSNull null];
  }
  else return r;      
}

- (void)dealloc
{
  //printf("\n ReplacementForCoderForClass dealloc");
  [className release];
  [super dealloc];
}  

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) 
  {
    [coder encodeObject:className forKey:@"className"];
  }
  else
  {
    [coder encodeObject:className];
  }  
} 
 
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding]) 
  {
    className = [[coder decodeObjectForKey:@"className"] retain];
  }
  else
  {
    className = [[coder decodeObject] retain];
  }  
  return self;
}

- initWithClass:(Class)theClass
{
  if ((self = [super init]))
  {
    className = [NSStringFromClass(theClass) retain];
    return self;
  }
  return nil;  
}
  
@end
