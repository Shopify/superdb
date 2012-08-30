/*   FSUnarchiver.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSUnarchiver.h"
#import "FSSymbolTable.h"

@implementation FSUnarchiver

- (void)dealloc
{
  [loaderEnvironmentSymbolTable release];
  [symbolTableForCompiledCodeNode release];
  [source release];
  //NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ START Unarchiver dealloc");
  [super dealloc];
  //NSLog(@"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ END Unarchiver dealloc");
}

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
