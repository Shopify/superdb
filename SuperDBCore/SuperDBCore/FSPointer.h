/*   FSPointer.h Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.         */  

#import <Foundation/Foundation.h>
#import <stddef.h>

@class FSGenericPointer; 
@class FSObjectPointer;
@class FSBoolean;
 
@interface FSPointer : NSObject
{
  NSUInteger retainCount;
  __strong void *cPointer;
}
  
+ (FSGenericPointer *) allocateCollectable:(NSUInteger)size;
+ (FSGenericPointer *) allocateCollectable:(NSUInteger)size options:(NSUInteger)options;
+ (FSGenericPointer *) malloc:(size_t)size;
+ (FSObjectPointer *)  objectPointer;
+ (FSObjectPointer *)  objectPointer:(size_t)count;

- (NSNumber *) address;
- (void *) cPointer;
- (BOOL) isEqual:(id)anObject;
- (FSBoolean *)operator_equal:(id)operand;
- (FSBoolean *)operator_tilde_equal:(id)operand;


@end
