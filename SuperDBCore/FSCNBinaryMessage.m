/*   FSCNBinaryMessage.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBinaryMessage.h"


@implementation FSCNBinaryMessage

- (void)dealloc
{
  [argument release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:argument forKey:@"argument"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self       = [super initWithCoder:coder];
  nodeType   = BINARY_MESSAGE;
  argument   = [[coder decodeObjectForKey:@"argument"] retain];
  return self;
}

- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern argument:(FSCNBase *)theArgument
{
  self = [super initWithReceiver:theReceiver selectorString:theSelectorString pattern:thePattern];
  if (self != nil) 
  {
    nodeType = BINARY_MESSAGE;
    argument = [theArgument retain];
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  [argument translateCharRange:translation];
}

@end
