/*   FSCNBase.m Copyright (c) 2007-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */

#import "FSCNBase.h"


@implementation FSCNBase
   
- (void)encodeWithCoder:(NSCoder *)coder
{
  if ( [coder allowsKeyedCoding] ) 
  {
    [coder encodeInt32:firstCharIndex forKey:@"firstCharIndex"];
    [coder encodeInt32:lastCharIndex  forKey:@"lastCharIndex"];
  }
  else [NSException raise:NSInvalidArchiveOperationException format:@"FSCNBase only supports keyed coding"];
} 
 
- (id)initWithCoder:(NSCoder *)coder
{ 
  self = [super init];
  
  if ( [coder allowsKeyedCoding] ) 
  {
    firstCharIndex = [coder decodeInt32ForKey:@"firstCharIndex"];
    lastCharIndex  = [coder decodeInt32ForKey:@"lastCharIndex"];
  }
  else [NSException raise:NSInvalidArchiveOperationException format:@"FSCNBase only supports keyed coding"];

  return self;
}       
       
- init
{
  if ((self = [super init]))
  {
    firstCharIndex = -1;
    lastCharIndex = -1;
    return self;
  }
  return nil;    
}

- (void)setFirstCharIndex:(int32_t)first lastCharIndex:(int32_t)last
{
  firstCharIndex = first;
  lastCharIndex  = last;
}  

-(void)translateCharRange:(int32_t)translation
{  
  firstCharIndex += translation; 
  lastCharIndex += translation;
}                  

@end