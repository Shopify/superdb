/*   FSKeyedUnarchiver.m Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSKeyedUnarchiver.h"
#import "FSSymbolTable.h"

@implementation FSKeyedUnarchiver

- (void)dealloc
{
  [loaderEnvironmentSymbolTable release];
  [symbolTableForCompiledCodeNode release];
  [source release];
  //NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ START Unarchiver dealloc");
  [super dealloc];
  //NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ END Unarchiver dealloc");
}


/*- (void)decodeValueOfObjCType:(const char *)valueType at:(void *)data
{
  if (strcmp(valueType,@encode(NSPoint)) == 0)
  {
    //((NSPoint *)data)->x = 10;
    //((NSPoint *)data)->y = 88;

    //((NSPoint *)data)->x = [self decodeFloatForKey:@"x"];
    //((NSPoint *)data)->y = [self decodeFloatForKey:@"y"];
  }
  //  *(NSPoint *)data = [self decodePointForKey:@"Point"];
  else
  [super decodeValueOfObjCType:valueType at:data];
}*/

- (id)initForReadingWithData:(NSData *)theData loaderEnvironmentSymbolTable:(FSSymbolTable*)theLoaderEnvironmentSymbolTable symbolTableForCompiledCodeNode:theSymbolTableForCompiledCodeNode
{
  if ((self = [super initForReadingWithData:theData]))
  {
    loaderEnvironmentSymbolTable = [theLoaderEnvironmentSymbolTable retain];
    symbolTableForCompiledCodeNode = [theSymbolTableForCompiledCodeNode retain];
    source = nil;    
    return self;
  }
  return nil;
}

- (FSSymbolTable *)loaderEnvironmentSymbolTable {return loaderEnvironmentSymbolTable;}

- (void)setSource:(NSString*)theSource
{
  [source autorelease];
  source = [theSource retain];
}

- (void)setSymbolTableForCompiledCodeNode:(FSSymbolTable *)theSymbolTableForCompiledCodeNode
{
  [symbolTableForCompiledCodeNode autorelease];
  symbolTableForCompiledCodeNode = [theSymbolTableForCompiledCodeNode retain];
}  

- (NSString *)source
{ return source; }

- (FSSymbolTable *)symbolTableForCompiledCodeNode
{ return symbolTableForCompiledCodeNode; }

@end
