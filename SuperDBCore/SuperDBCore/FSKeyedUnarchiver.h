/*   FSKeyedUnarchiver.h Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class FSSymbolTable;

@interface FSKeyedUnarchiver:NSKeyedUnarchiver
{
  FSSymbolTable *loaderEnvironmentSymbolTable;
  FSSymbolTable *symbolTableForCompiledCodeNode;
  NSString *source;
}

- (void)dealloc;
- (id)initForReadingWithData:(NSData *)theData loaderEnvironmentSymbolTable:(FSSymbolTable*)theLoaderEnvironmentSymbolTable symbolTableForCompiledCodeNode:theSymbolTableForCompiledCodeNode;
- (FSSymbolTable *)loaderEnvironmentSymbolTable;
- (void)setSource:(NSString*)theSource;
- (void)setSymbolTableForCompiledCodeNode:(FSSymbolTable *)theSymbolTableForCompiledCodeNode;
- (NSString *)source;
- (FSSymbolTable *)symbolTableForCompiledCodeNode;

@end
