/*   FSCNPrecomputedObject.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"

@interface FSCNPrecomputedObject : FSCNBase 
{
  @public
    id object;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithObject:(id)theObject;

@end
