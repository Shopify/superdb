/*   ArrayRepId.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.    */

/*

 Provides the class for the internal representation of FSArray of ids.

*/

#import <Foundation/Foundation.h>
#import "FSNSObject.h"
#import "ArrayRep.h"
 
@class FSBlock;

@interface ArrayRepId: NSMutableArray <ArrayRep>
{
  NSUInteger retainCount;  // optimized reference counting
@public
  __strong id *t;          // The actual array of ids
  NSUInteger count;        // the number of element in the array
  NSUInteger capacity;     // the size of the memory block pointed by t
}


///////////////////////////////////// USER METHODS SUPPORT


- (id)at:(id)index put:(id)elem;
- indexWithArray:(FSArray *)index; 
- (FSArray *)rotatedBy:(NSNumber *)operand;

///////////////////////////////////// OTHER METHODS

- (void)addObject:(id)anObject;
- (void)addObjectsFromFSArray:(FSArray *)otherArray;
- (ArrayRepId *) asArrayRepId;
- copyWithZone:(NSZone *)zone;
- (NSUInteger)count;
- (void *)dataPtr;
- (void)dealloc;
- (NSString *)descriptionLimited:(NSUInteger)nbElem;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- init;
//- initFrom:(unsigned)from to:(unsigned)to step:(unsigned)step;
- initFilledWith:(id)elem count:(NSUInteger)nb; // contract: a return value of nil means not enough memory
- initWithCapacity:(NSUInteger)aNumItems;  // designated initializer
                                         // contract: a return value of nil means not enough memory
- initWithObjects:(id *)objects count:(NSUInteger)nb;
- initWithObjectsNoCopy:(id *)tab count:(NSUInteger)nb;
- (void)insertObject:anObject atIndex:(NSUInteger)index;
- objectAtIndex:(NSUInteger)index;
- (void)removeLastElem;
- (void)removeLastObject;
- (void)removeElemAtIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (NSArray *)subarrayWithRange:(NSRange)range;
- (enum ArrayRepType)repType;
- (FSArray *)where:(NSArray *)booleans; // precondition: booleans is actualy an array and is of same size as the receiver
@end
