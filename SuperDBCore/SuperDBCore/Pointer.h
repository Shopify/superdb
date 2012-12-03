/*   Pointer.h Copyright (c) 2002-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>
#import <stddef.h>

@interface Pointer : NSObject <NSCopying>
{
  void *cPointer;
  char *type;
  char fsEncodedType;
}

- (BOOL) isEqual:anObject; 



/////////////////////////// USER METHODS ////////////////////////////

+ (Pointer *) malloc:(size_t)size;

- (Pointer *) asPointerForType:(NSString *)theType;
- (id) at:(id)i;
- (id) at:(id)i put:(id)elem;
- (id) clone __attribute__((deprecated));
- (void) free;

@end
