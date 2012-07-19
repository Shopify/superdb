/*   FSCNMessage.h Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNMessage.h"
#import "FSCompiler.h"

@implementation FSCNMessage

- (void)dealloc
{
  [receiver       release];
  [selectorString release];
  [pattern        release]; 
  [msgContext     release];
  [super dealloc];
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"Message send with selector \"%@\"", [FSCompiler stringFromSelector:selector]]; 
}


- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:receiver       forKey:@"receiver"];
  [coder encodeObject:selectorString forKey:@"selectorString"];
  [coder encodeObject:pattern        forKey:@"pattern"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self           = [super initWithCoder:coder];
  receiver       = [[coder decodeObjectForKey:@"receiver"] retain];
  selectorString = [[coder decodeObjectForKey:@"selectorString"] retain];
  selector       = NSSelectorFromString(selectorString);
  pattern        = [[coder decodeObjectForKey:@"pattern"] retain];
  msgContext     = [[FSMsgContext alloc] init];
  return self;
}

- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern
{
  self = [super init];
  if (self != nil) 
  {
    receiver       = [theReceiver retain];
    selectorString = [theSelectorString retain];
    selector       = NSSelectorFromString(selectorString);
    pattern        = [thePattern retain];
    msgContext     = [[FSMsgContext alloc] init];  
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  [receiver translateCharRange:translation];
}

@end
