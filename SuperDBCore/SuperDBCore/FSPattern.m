/*   FSPattern.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSPattern.h"
#import <Foundation/Foundation.h>
#import "FSArray.h"
#import "FSNumber.h"

@implementation FSPattern

+ patternWithDeep:(int)theDeep level:(FSArray *)theLevel nextPattern:(FSPattern*)theNextPatter
{
  return [[[self alloc] initWithDeep:theDeep level:theLevel nextPattern:theNextPatter] autorelease];
}  

+ patternFromIntermediateRepresentation:(NSArray *)ap
{
  NSInteger nb = [ap count];
  NSInteger level_count;
  NSInteger patternTab_count;
  NSInteger deep,i,j;
  NSMutableArray *patternTab;
  FSArray *level;
  FSNumber *l;
  FSNumber *zero = [FSNumber numberWithDouble:0];
  BOOL again;
  
  j = 0;
  patternTab = [NSMutableArray array];        
  again = YES;    
  
  while (again)
  {
    again = NO;
    level = [FSArray array];
    for (i = 0; i < nb; i++)
    {
      id e = [ap objectAtIndex:i]; // e may be an NSArray or [NSNull null]
      if (e == [NSNull null] || (NSInteger)[e count] < j+1)
        l = zero;
      else
      { 
        l = [e objectAtIndex:j];
        again = YES;
      }  
      [level addObject:l];     
    }
    
    
    for (i = 0, level_count = [level count]; i < level_count; i++) 
    {
      NSInteger k;
      long lcou = [[level objectAtIndex:i] doubleValue];
      if (lcou > 1)
      {
        long lcou2 ; 
        long lcou2_min;
        lcou2_min = 0;
        for (k = 0; k < level_count; k++)
        {
          lcou2 = [[level objectAtIndex:k] doubleValue];
          if (lcou2 < lcou && lcou2 > lcou2_min)
            lcou2_min = lcou2;
        }
        if (lcou-lcou2_min > 1)
        {
          for (k = 0; k < level_count; k++)
          {
            long lcou3 = [[level objectAtIndex:k] doubleValue];
            if (lcou3 >= lcou)
              [level replaceObjectAtIndex:k withObject:[FSNumber numberWithDouble:1+lcou3-(lcou-lcou2_min)]];
          }
        }   
      }
    }
    
    deep = 0;
    for (i = 0, level_count = [level count]; i < level_count; i++) 
    {
      if ([[level objectAtIndex:i] doubleValue] > deep)
        deep = [[level objectAtIndex:i] doubleValue];
    }
        
    [patternTab addObject:[FSPattern patternWithDeep:deep level:level nextPattern:nil]];
    
    j++;
  }
  
  for (i=0,patternTab_count=[patternTab count]-2 ; i < patternTab_count; i++)
    [[patternTab objectAtIndex:i] setNextPattern:[patternTab objectAtIndex:i+1]];
  
  return [patternTab objectAtIndex:0];  
}

- (NSString *)description
{
  unsigned i;
  NSMutableString *r;

  r = [NSMutableString stringWithFormat:@"->(FSPATTERN: deep = %d, level = ", deep];
  for (i = 0; i < levelCount-1; i++)
  {
    [r appendFormat:@"%d/",level[i]]; 
  }
  if (levelCount != 0) [r appendFormat:@"%d)",level[i]];

  if (nextPattern) [r appendString:[nextPattern description]]; 
  return r;
}

- initWithDeep:(int)theDeep level:(FSArray *)theLevel nextPattern:(FSPattern*)theNextPattern
{
  if ((self = [super init]))
  {
    unsigned int i;
    deep = theDeep;
    levelCount = [theLevel count];
    level = NSAllocateCollectable(sizeof(int)*levelCount, 0);
    for (i = 0; i < levelCount; i++)
      level[i] = [[theLevel objectAtIndex:i] doubleValue];
    nextPattern = [theNextPattern retain];
    return self;
  }
  return nil;
}

- (int)deep { return deep; }

- (BOOL)isDoubleLoop
{
  unsigned int i;
  
  if (levelCount <  2 || level[0] != 1 || level[1] != 1 || nextPattern) return NO;
  for (i = 2; i < levelCount; i++) if (level[i] != 0) return NO; 
  return YES;
}

- (BOOL)isSimpleLoopOnReceiver
{
  unsigned int i;
  //return NO;
  if (levelCount == 0 || level[0] != 1 || nextPattern) return NO;
  for (i = 1; i < levelCount; i++) if (level[i] != 0) return NO; 
  return YES;
}

- (int *)level { return level; }

- (unsigned int)levelCount { return levelCount; }

- (FSPattern *)nextPattern { return nextPattern; }

- (void) setNextPattern:(FSPattern *)theNextPattern
{
  [nextPattern autorelease];
  nextPattern = [theNextPattern retain];
}  

- (void)dealloc
{
  free(level);
  [nextPattern release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) 
  {
    NSMutableArray *_level;
    unsigned i;
    
    [coder encodeInt:deep forKey:@"deep"];
        
    _level = [NSMutableArray arrayWithCapacity:levelCount];
    for (i = 0; i < levelCount; i++) [_level addObject:[NSNumber numberWithInt:level[i]]];
    [coder encodeObject:_level forKey: @"level"];   
    
    [coder encodeObject:nextPattern forKey:@"nextPattern"];
  }
  else
  {
    [coder encodeValueOfObjCType:@encode(typeof(deep)) at:&deep];
    [coder encodeValueOfObjCType:@encode(typeof(levelCount)) at:&levelCount];
    [coder encodeArrayOfObjCType:@encode(int) count:levelCount at:level];
    [coder encodeObject:nextPattern];
  }  
}     

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  
  if ([coder allowsKeyedCoding]) 
  {
    NSArray *_level;
    unsigned i;
    
    deep = [coder decodeIntForKey:@"deep"];

    _level = [coder decodeObjectForKey:@"level"];
    levelCount = [_level count];
    level = NSAllocateCollectable(sizeof(int)*levelCount, 0);
    for (i = 0; i < levelCount; i++) level[i] = [[_level objectAtIndex:i] intValue];
    
    nextPattern = [[coder decodeObjectForKey:@"nextPattern"] retain];   
  }
  else
  {
    [coder decodeValueOfObjCType:@encode(typeof(deep)) at:&deep];
    [coder decodeValueOfObjCType:@encode(typeof(levelCount)) at:&levelCount];
    level = NSAllocateCollectable(sizeof(int)*levelCount, 0);
    [coder decodeArrayOfObjCType:@encode(int) count:levelCount at:level];
    nextPattern = [[coder decodeObject] retain];
  }    
  return self;
}


@end
