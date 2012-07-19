/*   FSCNKeywordMessage.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNKeywordMessage.h"

@implementation FSCNKeywordMessage

- (void)dealloc
{
  for (NSUInteger i = 0; i < argumentCount; i++) [arguments[i] release];
  free(arguments);
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:[NSArray arrayWithObjects:arguments count:argumentCount] forKey:@"arguments"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = KEYWORD_MESSAGE;

  NSArray *args = [coder decodeObjectForKey:@"arguments"];
  argumentCount = [args count];
  arguments     = NSAllocateCollectable(argumentCount * sizeof(id), NSScannedOption);
  [args getObjects:arguments];
  [args makeObjectsPerformSelector:@selector(retain)]; 
  return self;
}

- (id)initWithReceiver:(FSCNBase *)theReceiver selectorString:(NSString *)theSelectorString pattern:(FSPattern *)thePattern arguments:(NSArray *)args
{
  self = [super initWithReceiver:theReceiver selectorString:theSelectorString pattern:thePattern];
  if (self != nil) 
  {
    nodeType      = KEYWORD_MESSAGE;
    argumentCount = [args count];
    arguments     = NSAllocateCollectable(argumentCount * sizeof(id), NSScannedOption);
    [args getObjects:arguments];
    [args makeObjectsPerformSelector:@selector(retain)]; 
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  
  for (NSUInteger i = 0; i < argumentCount; i++) [arguments[i] translateCharRange:translation];
}


@end
