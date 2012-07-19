/*   FSCNBlock.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"

@class BlockRep;


@interface FSCNBlock : FSCNBase 
{
  @public
    BlockRep *blockRep;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithBlockRep:(BlockRep *)theBlockRep;

@end
