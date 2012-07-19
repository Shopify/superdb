/*   FSGlobalScope.m Copyright (c) 2009 Philippe Mougin.   */
/*   This software is open source. See the license.        */  

#import "FSGlobalScope.h"
#import "FSNSFileHandle.h"

FSGlobalScope *FSSharedGlobalScope;

void __attribute__ ((constructor)) initializeFSGlobalScope(void) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  FSSharedGlobalScope = [[FSGlobalScope alloc] init];
  
  [FSSharedGlobalScope setObject:[NSFileHandle fileHandleWithStandardOutput] forSymbol:@"stdout"];
  [FSSharedGlobalScope setObject:[NSFileHandle fileHandleWithStandardError]  forSymbol:@"stderr"];
  [FSSharedGlobalScope setObject:[NSFileHandle fileHandleWithStandardInput]  forSymbol:@"stdin"];

  [pool release];
}

@implementation FSGlobalScope

+ (FSGlobalScope *) sharedGlobalScope
{
  return FSSharedGlobalScope;
}

- (id) init
{
  self = [super init];
  if (self != nil) 
  {
    globals = [[NSMutableDictionary alloc]  init];
  }
  return self;
}

- (id) objectForSymbol:(NSString *)symbol found:(BOOL *)found // foud may be passed as NULL
{
  id object;
  
  @synchronized(self)
  {
    object = [globals objectForKey:symbol]; 
  }
  
  *found = object ? YES : NO;
  
  return object;
}

- (void) setObject:(id)object forSymbol:(NSString *)symbol    // object must ne non-nil (current implementation does not support storing nil in the global scope)

{
  NSParameterAssert(object != nil);
  
  @synchronized(self)
  {
    [globals setObject:object forKey:symbol]; 
  }
}


@end
