/* ArrayRep.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class FSArray;
@class ArrayRepId;
@class FSBlock;

@protocol ArrayRep <NSCopying> 

@required
- (ArrayRepId *) asArrayRepId;
- (enum ArrayRepType)repType;

@optional
- (NSUInteger)count;
- (NSString *)descriptionLimited:(NSUInteger)nbElem;
- (FSArray *) distinctId; 
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- indexWithArray:(FSArray *)index;
- (id)operator_backslash:(FSBlock*)bl; // precond: ![bl isProxy] && count != 0 
- (void)removeLastElem;
- (void)removeElemAtIndex:(NSUInteger)index;
- (FSArray *)replicateWithArray:(FSArray *)operand;
- (FSArray *)reverse;
- (FSArray *)rotatedBy:(NSNumber *)operand;
- (FSArray *)sort;
- (NSArray *)subarrayWithRange:(NSRange)range;

@end
