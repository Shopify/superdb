/* ArrayPrivate.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSArray.h"
#import "ArrayRep.h"

/////////////////////////////////////

//enum ArrayRepType {FS_ID, DOUBLE, EMPTY, BOOLEAN , FETCH_REQUEST}; // These enums are used in a char instance variable of FSArray, so there must be less than 127 possible values (!) or char will have to be changed to something larger.

@interface FSArray(ArrayPrivate)

+ (FSArray *)arrayWithRep:(id)theRep;

- (id)arrayRep;
- (void)becomeArrayOfId;
- (void *)dataPtr;
- initFrom:(NSUInteger)from to:(NSUInteger)to step:(NSUInteger)step;
- initFilledWith:(id)elem count:(NSUInteger)nb;
- (FSArray *)initWithRep:(id)theRep;
- (FSArray *)initWithRepNoRetain:(id)theRep;
- (enum ArrayRepType)type;

@end
