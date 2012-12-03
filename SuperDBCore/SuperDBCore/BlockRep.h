/*   BlockRep.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.  */  

#import "FSNSObject.h"
#import "BlockSignature.h"
#import "FSSymbolTable.h"

@class FSSymbolTable;
@class NSMutableString;
@class FSArray;
@class BlockInspector;
@class NSExcepion;
@class FSMsgContext;
@class FSBlock;
@class FSInterpreter;
@class FSBlockCompilationResult;
@class FSInterpreterResult;
@class FSCNBase;

@interface BlockRep:NSObject <NSCopying , NSCoding>
{
  NSUInteger retainCount;
  struct BlockSignature signature;
  FSCNBase *ac;
  FSSymbolTable *symbol_table;
  NSString *source;
  BOOL is_compiled;
  NSInteger useCount;
  
  FSInterpreter *interpreter; // This is designed to be used only when a block is cretated externaly to an existing FSInterpreter. It will be nil in other cases.  
                              // This can be done by using the "asBlock" method on an NSString (see FSNSString category).
                              // In such a case, the block needs to create its own enclosing environment (wich will notably includes a "sys" object).
                              // This reference to the FSInterpreter is needed in order to release the interpreter when the block is deallocated.
  BOOL isCompact;
  SEL sel;
  NSString *selStr;
  FSMsgContext *msgContext;
}

+ (void)initialize; 

- (NSInteger)argumentCount;
- (NSArray *)argumentsNames;
- (FSCNBase *)ast;
- (id)body_compact_valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block;
- (id)body_notCompact_valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block;
- (FSBlockCompilationResult *)compilForBlock:(FSBlock *)block;   // May cause self to be deallocated.
- (id)compilForBlock:(FSBlock *)block onError:(FSBlock *)errorBlock; // May raise. May cause self to be deallocated.
- copyWithZone:(NSZone *)zone;
- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (FSInterpreterResult *)executeWithArguments:(NSArray *)arguments block:(FSBlock *)block;
- (id)initWithCoder:(NSCoder *)aDecoder;

- initWithCode:(FSCNBase *)theCode symbolTable:(FSSymbolTable*)theSymbolTable signature:(struct BlockSignature)theSignature source:(NSString*)theSource isCompiled:(BOOL)is_comp isCompact:(BOOL)isCompactArg sel:(SEL)theSel selStr:(NSString*)theSelStr;
// If you pass NO for is_comp, you must pass the *parent* symbol table for theSybolTableArgument
// This method retains theCode, theSymbolTable and theSource. No copy.

- (BOOL)isCompact;
- (NSString *)keyOfSetValueForKeyMessage; 
- (SEL)messageToArgumentSelector;
- (FSMsgContext *)msgContext;
- (void)newSource:(NSString *)theNewSource;

- (FSBlock *)newBlockWithParentSymbolTable:(FSSymbolTable *)parent;

- (void) release;
- (id) retain;
- (NSUInteger) retainCount;

- (SEL)selector;
- (NSString *)selectorStr;
- (void) setInterpreter:(FSInterpreter *)theInterpreter;
- (struct BlockSignature) signature;
- (NSString *)source;

- (FSSymbolTable *) symbolTable;

- (void) useRelease;
- (id) useRetain;
- (NSInteger) useCount;

- (id) valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block;
- (id) valueWithArguments:(NSArray *)arguments block:(FSBlock *)block;

@end


