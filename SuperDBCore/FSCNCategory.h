/*   FSCNCategory.h Copyright (c) 2008-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCNBase.h"

@interface FSCNCategory : FSCNBase
{
  @public
    NSString *className;
    NSArray  *methods;
}

- (NSString *) className;
- (void) dealloc;
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;
- (id) initWithClassName:(NSString *)theClassName methods:(NSArray *)theMethods;
- (void)translateCharRange:(long)translation;

@end
