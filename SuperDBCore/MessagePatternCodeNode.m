/*   MessagePatternCodeNode.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "MessagePatternCodeNode.h"
#import <Foundation/Foundation.h>
#import "FSNumber.h"
#import "FSPattern.h"
#import "FSArray.h"

@implementation MessagePatternCodeNode

-(void)dealloc
{
  [pattern release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{  
  [super encodeWithCoder:coder];
  if ([coder allowsKeyedCoding]) 
  {
    [coder encodeObject:pattern forKey:@"pattern"];
  }
  else
  {
    [coder encodeObject:pattern];
  }  
}     

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if ([coder allowsKeyedCoding]) 
  {
    pattern = [[coder decodeObjectForKey:@"pattern"] retain];
  }
  else
  {
    pattern = [[coder decodeObject] retain];
  }  
  return self;
}

- setMessageWithReceiver:(CompiledCodeNode *) theReceiver 
                selector:(NSString *)  theSelector
                operatorSymbols:(NSString*) theOperatorSymbols
                pattern:(FSPattern *) thePattern
{  
  pattern = [thePattern retain];    
  return [super setMessageWithReceiver:theReceiver selector:theSelector operatorSymbols:theOperatorSymbols];
}  

- (FSPattern *)pattern 
{ return pattern; }

@end
