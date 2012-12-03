/*   FSCNBinaryMessage.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMessage.h"

@interface FSCNBinaryMessage : FSCNMessage 
{
  @public
    FSCNBase *argument;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern argument:(FSCNBase *)theArgument;
- (void)translateCharRange:(int32_t)translation;

@end
