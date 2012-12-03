/*   FSCNMethod.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"
#import "FSMethod.h"

@interface FSCNMethod : FSCNBase 
{
  @public
    FSMethod *method;
    BOOL isClassMethod;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithMethod:(FSMethod *)theMethod isClassMethod:(BOOL)classMethod;
- (void)translateCharRange:(long)translation;

@end
