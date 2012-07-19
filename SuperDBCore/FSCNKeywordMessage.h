/*   FSCNKeywordMessage.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMessage.h"

@interface FSCNKeywordMessage : FSCNMessage 
{
  @public
    char argumentCount;
    __strong FSCNBase **arguments;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern arguments:(NSArray *)args;
- (void)translateCharRange:(int32_t)translation;

@end
