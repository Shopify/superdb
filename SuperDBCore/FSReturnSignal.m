/* FSReturnSignal.m Copyright (c) 2006 Philippe Mougin. */ 
/* This software is open source. See the license.            */

#import "FSReturnSignal.h"

@implementation FSReturnSignal

+ (FSReturnSignal *)returnSignalWithBlock:(FSBlock *)theBlock result:(id)theResult
{
  return [[[self alloc] initWithBlock:theBlock result:(id)theResult] autorelease];
}

+ (FSReturnSignal *)returnSignalWithSymbolTable:(FSSymbolTable *)theSymbolTable result:(id)theResult
{
  return [[[self alloc] initWithSymbolTable:theSymbolTable result:(id)theResult] autorelease];
}

- (FSBlock *)block
{
  return block;
}

- (void) dealloc 
{
  [block release];
  [symbolTable release];
  [result release];
  [super dealloc];
}

- (FSReturnSignal *)initWithBlock:(FSBlock *)theBlock result:(id)theResult
{
  self = [super initWithName:@"FSReturnSignal" reason:@"" userInfo:nil];
  if (self != nil) 
  {
    block = [theBlock retain];
    result = [theResult retain];
  }
  return self;
}

- (FSReturnSignal *) initWithSymbolTable:(FSSymbolTable *)theSymbolTable result:(id)theResult
{
  self = [super initWithName:@"FSReturnSignal" reason:@"" userInfo:nil];
  if (self != nil) 
  {
    symbolTable = [theSymbolTable retain];
    result = [theResult retain];
  }
  return self;
}

- (id) result
{
  return result;
}

- (FSSymbolTable *)symbolTable
{
  return symbolTable;
}

@end
