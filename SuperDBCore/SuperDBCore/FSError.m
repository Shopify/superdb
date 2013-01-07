/* FSError.m Copyright (c) 2002-2006 Philippe Mougin.  */
/* This software is open source. See the license. */ 

#import "FSError.h"
#import "FSBoolean.h"

// ignoring these warnings until it can be fixed, for build servers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-w"
 
@implementation FSError

+ (FSError *) errorWithDescription:(NSString*)desc { return [[self alloc] initWithDescription:desc]; }

- (id)copyWithZone:(NSZone *)zone { return [self retain]; }

- (NSString *)description { return description; }

- (void) dealloc
{ 
  [description release];
  [super dealloc];
}

- initWithDescription:(NSString*)desc
{
  if ((self = [super init]))
  {
    description = [desc retain];
    return self;
  }
  return nil;
}

- (FSBoolean *)operator_less:(id)operand
{
  if ([operand isKindOfClass:[self class]]) return [FSBoolean fsFalse];
  else                                      return [FSBoolean fsTrue];
}


@end
#pragma clang diagnostic pop