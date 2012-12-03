/*   FSCNArray.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"


@interface FSCNArray : FSCNBase 
{
  @public
    unsigned count;
    __strong FSCNBase **elements;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithElements:(NSArray *)theElements;
- (void)translateCharRange:(int32_t)translation;

@end
