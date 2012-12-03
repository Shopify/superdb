/* FSReturnSignal.h Copyright (c) 2006 Philippe Mougin. */ 
/* This software is open source. See the license.            */

#import <Foundation/Foundation.h>

@class FSBlock, FSSymbolTable;

@interface FSReturnSignal : NSException 
{
  FSBlock *block;
  FSSymbolTable *symbolTable;
  id result;
}

+ (FSReturnSignal *)returnSignalWithBlock:(FSBlock *)theBlock result:(id)theResult;
+ (FSReturnSignal *)returnSignalWithSymbolTable:(FSSymbolTable *)theSymbolTable result:(id)theResult;

- (FSBlock *) block;
- (void) dealloc;
- (FSReturnSignal *) initWithBlock:(FSBlock *)theBlock result:(id)theResult;
- (FSReturnSignal *) initWithSymbolTable:(FSSymbolTable *)theSymbolTable result:(id)theResult;

- (id) result;
- (FSSymbolTable *)symbolTable;

@end
