/* ArrayRepDouble.h Copyright (c) 1998-2009 Philippe Mougin. */
/* This software is open source. See the license.        */

#import <Foundation/Foundation.h>
#import "ArrayRep.h"

@interface ArrayRepDouble : NSObject <ArrayRep>
{
  NSUInteger retainCount;
@public
  double *t;      // the doubles
  NSUInteger count;
  NSUInteger capacity;  
}


+ arrayRepDoubleWithCapacity:(NSUInteger)aNumItems;

- (void)addDouble:(double)aDouble;
- (void)addDoublesFromFSArray:(FSArray *)otherArray;
- (NSString *)descriptionLimited:(NSUInteger)nbElem;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- init;
- initFilledWithDouble:(double)elem count:(NSUInteger)nb; // contract: a return value of nil means not enough memory
- initFrom:(NSUInteger)from to:(NSUInteger)to step:(NSUInteger)step; // contract: a return value of nil means not enough memory
- initWithCapacity:(NSUInteger)aNumItems; // contract: a return value of nil means not enough memory
- initWithDoubles:(double *)elems count:(NSUInteger)nb;
- initWithDoublesNoCopy:(double *)tab count:(NSUInteger)nb;
- (void)insertDouble:(double)aDouble atIndex:(NSUInteger)index;
- copyWithZone:(NSZone *)zone;
- (double *)doublesPtr;
- (void)replaceDoubleAtIndex:(NSUInteger)index withDouble:(double)aDouble;
- (enum ArrayRepType)repType;
- (FSArray *)where:(NSArray *)booleans; // precondition: booleans is actualy an array and is of same size as the receiver
@end
