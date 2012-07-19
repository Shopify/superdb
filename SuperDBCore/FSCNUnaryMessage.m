/*   FSCNUnaryMessage.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNUnaryMessage.h"

@implementation FSCNUnaryMessage

- (id)initWithCoder:(NSCoder *)coder
{
  self       = [super initWithCoder:coder];
  nodeType   = UNARY_MESSAGE;
  return self;
}

- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern
{
  self = [super initWithReceiver:theReceiver selectorString:theSelectorString pattern:thePattern];
  if (self != nil) 
  {
    nodeType = UNARY_MESSAGE;
  }
  return self;
}


@end
