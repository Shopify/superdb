/*   FSCNCascade.m Copyright (c) 2008-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNCascade.h"

@implementation FSCNCascade

- (void)dealloc
{
  [receiver release];
  for (NSUInteger i = 0; i < messageCount; i++) [messages[i] release];
  free(messages);
  [super dealloc];
}

- (NSString *)description
{
  return @"Cascade"; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:receiver forKey:@"receiver"];
  [coder encodeObject:[NSArray arrayWithObjects:messages count:messageCount] forKey:@"messages"];
}  

- (id)initWithCoder:(NSCoder *)coder
{
  self     = [super initWithCoder:coder];
  nodeType = CASCADE;
  receiver = [[coder decodeObjectForKey:@"receiver"] retain];

  NSArray *msgs = [coder decodeObjectForKey:@"messages"];
  messageCount  = [msgs count];
  messages      = NSAllocateCollectable(messageCount * sizeof(id), NSScannedOption);
  [msgs getObjects:messages];
  [msgs makeObjectsPerformSelector:@selector(retain)]; 

  return self;
}

- (id)initWithReceiver:(FSCNBase *)theReceiver messages:(NSArray *)msgs
{
  self = [super init];
  if (self != nil) 
  {
    nodeType = CASCADE;
    receiver = [theReceiver retain];
    messageCount = [msgs count];
    messages     = NSAllocateCollectable(messageCount * sizeof(id), NSScannedOption);
    [msgs getObjects:messages];
    [msgs makeObjectsPerformSelector:@selector(retain)]; 
  }
  return self;
}

- (void)translateCharRange:(int32_t)translation
{
  [super translateCharRange:translation];
  [receiver translateCharRange:translation];
  for (NSUInteger i = 0; i < messageCount; i++) [messages[i] translateCharRange:translation];
}

@end
