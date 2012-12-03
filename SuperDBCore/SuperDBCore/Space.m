/*   Space.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "Space.h"
#import "FScriptFunctions.h"
#import <Foundation/Foundation.h>
#import "FSUnarchiver.h"

@implementation Space

////////////////////////  USER METHODS  ////////////////////////////

/*- (void) inspect
{
  [SpaceInspector spaceInspectorWithSpace:self];
}
*/

////////////////////////  SYSTEM METHODS ////////////////////////////

- (void)dealloc
{
  //printf("\n Space dealloc\n");
  [localSymbolTable release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{  
  if ([coder allowsKeyedCoding]) 
  {
    [coder encodeObject:localSymbolTable forKey:@"localSymbolTable"];
  }
  else
  {
    [coder encodeObject:localSymbolTable];
  }  
} 
 
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding]) 
  {
    localSymbolTable = [[coder decodeObjectForKey:@"localSymbolTable"] retain];
  }
  else
  {
    localSymbolTable = [[coder decodeObject] retain];
  }  
  return self;
}

- initSymbolTableLocale:(FSSymbolTable*)symb_loc
{
  if ((self = [super init]))
  {
    localSymbolTable = [symb_loc retain];
    return self;
  }
  return nil;  
}

- (FSSymbolTable*)localSymbolTable
{ return localSymbolTable;}

  
@end
