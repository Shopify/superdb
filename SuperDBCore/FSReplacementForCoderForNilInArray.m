//  ReplacementForCoderForNilInArray.m Copyright (c) 2003-2009 Philippe Mougin.
//  This software is open source. See the license.

#import "FSReplacementForCoderForNilInArray.h"

void __attribute__ ((constructor)) initializeFSReplacementForCoderForNilInArray(void) 
{
  [NSKeyedUnarchiver setClass:[FSReplacementForCoderForNilInArray class] forClassName:@"ReplacementForCoderForNilInArray"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"ReplacementForCoderForNilInArray" asClassName:@"FSReplacementForCoderForNilInArray"];  
#endif
}

@implementation FSReplacementForCoderForNilInArray

- (void)encodeWithCoder:(NSCoder *)encoder {}

- (id)initWithCoder:(NSCoder *)decoder { return [super init]; }

@end
