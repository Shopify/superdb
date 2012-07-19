/*   FSCNReturn.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"


@interface FSCNReturn : FSCNBase 
{
  @public
    FSCNBase *expression;
}

- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithExpression:(FSCNBase *)theExpression;
- (void)translateCharRange:(long)translation;

@end
