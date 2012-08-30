/*   Block.h Copyright (c) 1998-2009 Philippe Mougin.         */
/*   This software is open source. See the license.       */

#import "FSNSObject.h"
#import "BlockSignature.h"

@class BlockInspector, FSBoolean, FSMsgContext, BlockRep, FSSymbolTable, FSCNBase, FSInterpreter, FSInterpreterResult;

@interface Block:NSObject <NSCopying , NSCoding>
{
  NSUInteger retainCount;    
  BlockRep *blockRep;
  BlockInspector *inspector;
}

+ allocWithZone:(NSZone *)zone;
+ blockWithSelector:(SEL)theSelector;
+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable;  // May raise
+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable onError:(Block *)errorBlock; // May raise

- (NSArray *)argumentsNames;
- (void) compilIfNeeded; // May raise
- (id) compilOnError:(Block *)errorBlock; // May raise
- copy;
- copyWithZone:(NSZone *)zone;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (FSInterpreterResult *)executeWithArguments:(NSArray *)arguments;
- (id) initWithBlockRep:(BlockRep *)theBlockRep;
- (id)initWithCoder:(NSCoder *)aDecoder;
- initWithCode:(FSCNBase *)theCode symbolTable:(FSSymbolTable*)theSymbolTable signature:(struct BlockSignature)theSignature source:(NSString*)theSource isCompiled:(BOOL)is_comp isCompact:(BOOL)isCompactArg sel:(SEL)theSel selStr:(NSString*)theSelStr;
   // This method retains theCode, theSymbolTable and theSource. No copy.
- (BOOL) isCompact;  // May raise
- (FSMsgContext *)msgContext;
- (void) release;
- (id) retain;
- (NSUInteger) retainCount;
- (SEL) selector;
- (NSString *) selectorStr;
- (void)setInterpreter:(FSInterpreter *)theInterpreter;
- (void)showError:(NSString*)errorMessage; 
- (void)showError:(NSString*)errorMessage start:(NSInteger)firstCharacterIndex end:(NSInteger)lastCharacterIndex;
- (FSSymbolTable *) symbolTable;
- (id) valueArgs:(id*)args count:(NSUInteger)count;

////////////////////////////// USER METHODS ////////////////////////

- (NSInteger)argumentCount;
- (Block*) clone __attribute__((deprecated));
- (id) guardedValue:(id)arg1;
- (NSUInteger) hash;
- (void) inspect;
- (BOOL) isEqual:anObject;
- (id)onException:(Block *)handler;
- (FSBoolean *)operator_equal:(id)operand;
- (FSBoolean *)operator_tilde_equal:(id)operand;
- (void) return;
- (void) return:(id)rv;
- (void)setValue:(Block *)operand;
- (id) value;
- (id) value:(id)arg1;
- (id) value:(id)arg1 value:(id)arg2;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11;
- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11 value:(id)arg12;
- (id) valueWithArguments:(NSArray *)operand;
- (void) whileFalse;
- (void) whileFalse:(Block*)iterationBlock;
- (void) whileTrue;
- (void) whileTrue:(Block*)iterationBlock;

@end
