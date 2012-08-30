/*   Array.h Copyright (c) 1998-2009 Philippe Mougin.     */
/*   This software is open source. See the license.       */


#import <Foundation/Foundation.h>
#import "FSNSObject.h"
#import "FSArray.h"
#import "FSNSArray.h"
#import "FSNSMutableArray.h"

@class FSBlock, FSSystem ;
 
@interface Array: NSMutableArray
{
  NSUInteger retainCount;
  enum ArrayRepType type;
  id rep;  // internal representation
} 

///////////////////////////////////// USER METHODS

- (id)at:(id)index put:(id)elem;
- (Array *)distinctId;
- (BOOL)isEqual:(id)anObject;
- (Array *)replicate:(NSArray *)operand;
- (Array *)reverse;
- (Array *)rotatedBy:(NSNumber *)operand;
- (Array *)sort;

///////////////////////////////////// OTHER METHODS

+ (double) maxCount;
+ (id)arrayWithObject:(id)anObject;
+ (id)arrayWithObjects:(id *)objects count:(NSUInteger)count;

- (void)addObject:(id)anObject;
- (NSArray *)arrayByAddingObject:(id)anObject;
- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray;
- (NSString *)componentsJoinedByString:(NSString *)separator;
- (BOOL)containsObject:(id)anObject;
- copyWithZone:(NSZone *)zone;
- (NSUInteger)count;
- (NSString *)description;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level;
- (id)firstObjectCommonWithArray:(NSArray *)otherArray;
- (NSUInteger)indexOfObject:(id)anObject;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range;
- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;
- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range;
- init;
- initWithCapacity:(NSUInteger)aNumItems;  // designated initializer
- initWithObject:(id)object;
- initWithObjects:(id *)objects count:(NSUInteger)nb;
- (void)insertObject:anObject atIndex:(NSUInteger)index;
- (BOOL)isEqualToArray:(NSArray *)anArray;
- mutableCopyWithZone:(NSZone *)zone;
- objectAtIndex:(NSUInteger)index;
- (NSEnumerator *)objectEnumerator;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (id)retain;
- (NSUInteger)retainCount;
- (void)release;
- (NSEnumerator *)reverseObjectEnumerator;
- (void)setArray:(NSArray *)operand;
- (NSArray *)subarrayWithRange:(NSRange)range; // returns an instance of Array.

@end
