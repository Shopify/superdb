/*   FSNewlyAllocatedObjectHolder.h Copyright (c) 2001-2009 Philippe Mougin.     */
/*   This software is open source. See the license.                              */
         
#import <Foundation/Foundation.h>

@interface FSNewlyAllocatedObjectHolder : NSObject 
{
  id object;
}

+ (id)newlyAllocatedObjectHolderWithObject:(id)theObject;

- (id)initWithObject:(id)theObject;
- (id)object;
- (NSString *)printString;

@end
