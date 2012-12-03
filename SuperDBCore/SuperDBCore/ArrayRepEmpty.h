/*   ArrayRepEmpty.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.       */ 

/*

 Provides the class for the internal representation of empty FSArray.

*/

#import <Foundation/Foundation.h>
#import "ArrayRep.h"

@class ArrayRepDouble;
@class ArrayRepBoolean;

@interface ArrayRepEmpty : NSObject <ArrayRep>
{
  NSUInteger retainCount;  // optimized reference counting
@public
  NSUInteger capacity;     // used when generating a not empty FSArray representation from this empty one. Equal to the capacity given at creation time using the standard NSArray initializer
}

- (ArrayRepDouble *)  asArrayRepDouble;
- (ArrayRepBoolean *) asArrayRepBoolean;
- init;
- initWithCapacity:(NSUInteger)aNumItems;

@end
