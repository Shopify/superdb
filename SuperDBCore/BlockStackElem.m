/*   BlockStackElem.m Copyright (c) 2001-2009 Philippe Mougin.  */
/*   This software is open source. See the license.    */  

#import "BlockStackElem.h"
#import "FSBlock.h"

@implementation BlockStackElem

+ (BlockStackElem *)blockStackElemWithBlock:(FSBlock *)theBlock errorStr:(NSString *)theErrorStr firstCharIndex:(NSInteger)first lastCharIndex:(NSInteger)last
{
  return [[[self alloc] initWithBlock:theBlock errorStr:theErrorStr firstCharIndex:first lastCharIndex:last] autorelease];
}

- (FSBlock *)block {return block;}

- (void)dealloc
{
  [block release];
  [errorStr release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:firstCharIndex forKey:@"firstCharIndex"];
  [coder encodeInteger:lastCharIndex forKey:@"lastCharIndex"];
  [coder encodeObject:errorStr forKey:@"errorStr"];
  [coder encodeObject:block forKey:@"block"];
} 

- (NSString *)errorStr {return errorStr;}

- (NSInteger) firstCharIndex {return firstCharIndex;}

- (BlockStackElem *)initWithBlock:(FSBlock *)theBlock errorStr:(NSString *)theErrorStr firstCharIndex:(NSInteger)first lastCharIndex:(NSInteger)last
{
  // NSLog([NSString stringWithFormat:@"---- BlockStackElem initWithBlock:%@ errorStr:%@ firstCharIndex:%d lastCharIndex:%d", theBlock, theErrorStr, first, last]);
  
  if ((self = [super init]))
  {
    block = [theBlock retain];
    errorStr = [theErrorStr retain];
    firstCharIndex = first;
    lastCharIndex = last;
    return self;
  }
  return nil;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  
  if ( [coder allowsKeyedCoding] ) 
  {
    firstCharIndex = [coder decodeIntegerForKey:@"firstCharIndex"];
    lastCharIndex  = [coder decodeIntegerForKey:@"lastCharIndex"];
    errorStr       = [[coder decodeObjectForKey:@"errorStr"] retain];
    block          = [[coder decodeObjectForKey:@"block"] retain];
  }
  else
  {
    int temp;
    [coder decodeValueOfObjCType:@encode(int) at:&temp];
	firstCharIndex = temp;
    [coder decodeValueOfObjCType:@encode(int) at:&temp];
	lastCharIndex = temp;
    errorStr = [[coder decodeObject] retain];
    block = [[coder decodeObject] retain];
  }  
  
  return self;
}

- (NSInteger) lastCharIndex {return lastCharIndex;}

@end
