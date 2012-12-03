/* StrBuffer.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCommandHistory.h"

@implementation FSCommandHistory 

- addStr:(NSString *)str 
{ 
  if ([array count] != 0)
  {
    head = (head+1) % [array count];
    if (head == queue) queue = (queue+1) % [array count];  
    [array replaceObjectAtIndex:head withObject:str];
    [self goToLast];
  } 
  return self;  
}    
  
- (void)dealloc
{
  [array release];
  [super dealloc];
}     

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:array forKey:@"array"];
  [coder encodeInteger:head forKey:@"head"];
  [coder encodeInteger:queue forKey:@"queue"];
  [coder encodeInteger:cursor forKey:@"cursor"];
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding]) 
  {
    array = [[coder decodeObjectForKey:@"array"] retain];
    head  = [coder decodeIntegerForKey:@"head"];
    queue = [coder decodeIntegerForKey:@"queue"];
    cursor= [coder decodeIntegerForKey:@"cursor"];
  }
  else
  {
    int intHead, intQueue, intCursor;
    array = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(int) at:&intHead];
	head = intHead;
    [coder decodeValueOfObjCType:@encode(int) at:&intQueue];
	queue = intQueue;
    [coder decodeValueOfObjCType:@encode(int) at:&intCursor];
	cursor = intCursor;
  }  
  return self;
}

- goToFirst
{
  cursor = head;
  return self;
}

- goToLast
{
  cursor = queue;
  return self;
}

- goToNext
{
  if ([array count] != 0)
  {
    if   (cursor == head) cursor = queue;
    else                  cursor = (cursor+1) % [array count];
  }  
  return self;
}

- goToPrevious
{
  if([array count] != 0)
  {
    if   (cursor == queue)  cursor = head;
    else                    cursor = (cursor-1+[array count]) % [array count];
  } 
  return self;
}  
  
- (NSString *)getMostRecentlyInsertedStr
{
  if ([array count] != 0) return [array objectAtIndex:head];
  else                    return(@"");
}

- (NSString *)getStr
{
  if ([array count] != 0) return [array objectAtIndex:cursor];
  else                    return(@"");    
}  

- init {return [self initWithUIntSize:0];}

- initWithUIntSize:(NSUInteger)size
{
  if ((self = [super init]))
  {
    array = [[NSMutableArray alloc] initWithCapacity:size];
    head = 0; queue =0;
    for (; size > 0; size--) [array addObject:@""];
    return self;
  }
  return nil;  
}  
      
- (NSInteger)size {return [array count];}

@end
