/*   FSCNMessage.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"
#import "FSMsgContext.h"
#import "FSPattern.h"

@interface FSCNMessage : FSCNBase 
{
  @public
    FSCNBase   *receiver;
    SEL         selector;
    NSString   *selectorString;  // We need to keep the selector string because, in GC mode, SELs for retain, release, etc. are all represented by a special unusable SEL (i.e. "<ignored selector>")   
    FSPattern  *pattern;
    FSMsgContext *msgContext;
}

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern; // theSelectorString is the representation of the real selector (e.g., "operator_plus" instead of "+") 
- (void)translateCharRange:(int32_t)translation;

@end
