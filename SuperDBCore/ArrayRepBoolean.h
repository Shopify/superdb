/* ArrayRepBoolean.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.       */

#import <Foundation/Foundation.h>
#import "ArrayRep.h"

@interface ArrayRepBoolean : NSObject <ArrayRep>
{
  NSUInteger retainCount;
@public
  char *t;     // the booleans, represented by an array of char
  NSUInteger count;
  NSUInteger capacity;  
}


- (void)addBoolean:(char)aBoolean;
- (char *)booleansPtr;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- init;
- initFilledWithBoolean:(char)elem count:(NSUInteger)nb; // contract: a return value of nil means not enough memory
- initWithCapacity:(NSUInteger)aNumItems; // contract: a return value of nil means not enough memory
- initWithBooleans:(char *)elems count:(NSUInteger)nb;
- initWithBooleansNoCopy:(char *)tab count:(NSUInteger)nb;
- copyWithZone:(NSZone *)zone;
- (void)replaceBooleanAtIndex:(NSUInteger)index withBoolean:(char)aBoolean;
- (enum ArrayRepType)repType;


@end
