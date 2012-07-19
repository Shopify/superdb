/*   FSCNCascade.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMessage.h"

@interface FSCNCascade : FSCNBase 
{
  @public
    FSCNBase *receiver;
    unsigned messageCount;
    __strong FSCNMessage **messages;
}

- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithReceiver:(FSCNBase *)theReceiver messages:(NSArray *)msgs;
- (void)translateCharRange:(int32_t)translation;

@end
