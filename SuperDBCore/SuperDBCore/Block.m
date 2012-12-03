
/*   Block.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "Block_fscript.h"
#import "BlockPrivate.h"
#import "BlockRep.h"
#import "FSExecEngine.h"
#import "FSCompiler.h"
#import "FSArray.h"
#import "FSNSArrayPrivate.h" 
#import "ArrayPrivate.h"
#import <Foundation/Foundation.h>
#import "FSBooleanPrivate.h"
#import "FScriptFunctions.h"
#import "Number_fscript.h"
#import "FSVoid.h"
#import "FSMiscTools.h"
#import "FSNSString.h"
#import "FSInterpreterResultPrivate.h"
#import "FSReturnSignal.h"

void __attribute__ ((constructor)) initializeBlock(void) 
{
  [NSKeyedUnarchiver setClass:[Block class] forClassName:@"Block"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"Block" asClassName:@"Block"];  
#endif
}


@implementation Block

/////////////////// Experimental
/*-(NSString *)generateApplication:(NSString *)applicationName
 {
 NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"blockExec" ofType:@"app"];
 NSString *destinationPath = [[NSHomeDirectory() stringByAppendingPathComponent:applicationName] stringByAppendingPathExtension:@"app"];
 NSString *blockSourceCodePath = [[[destinationPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:@"block.txt"];
 
 [[NSFileManager defaultManager] copyPath:sourcePath toPath:destinationPath handler:nil];
 [[self printString] writeToFile:blockSourceCodePath atomically:YES];
 
 return nil;
 }*/
///////////////////


+ (id)alloc
{
  return [self allocWithZone:nil];
}

+ (id)allocWithZone:(NSZone *)zone
{
  return (id)[FSBlock allocWithZone:zone];
}

+ blockWithSelector:(SEL)theSelector
{
  return [[@"#" stringByAppendingString:[FSCompiler stringFromSelector:theSelector]] asBlock]; 
}

+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable
{
  return [self blockWithSource:source parentSymbolTable:parentSymbolTable onError:nil];
}  

+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable onError:(Block *)errorBlock
{
  struct BlockSignature signature = {0,NO}; 
  Block *r = [[[self alloc] initWithCode:nil symbolTable:parentSymbolTable signature:signature source:[[source copy] autorelease] isCompiled:NO isCompact:NO sel:(SEL)0 selStr:nil] autorelease];
  return [r compilOnError:errorBlock];
} 


- (NSArray *)argumentsNames
{
  assert(0);
}

- (id)ast
{
  assert(0);
}

- (void) compilIfNeeded {assert(0);}  // May raise

- (id)compilOnError:(Block *)errorBlock // May raise
{ 
  assert(0);
}    

- copy
{ 
  assert(0);
}

- copyWithZone:(NSZone *)zone
{
  assert(0);
}


- (void)encodeWithCoder:(NSCoder *)coder
{  
  assert(0);
} 

- (FSInterpreterResult *)executeWithArguments:(NSArray *)arguments
{
  assert(0);
}

- (NSUInteger) hash
{
  assert(0);
}

- (id) initWithBlockRep:(BlockRep *)theBlockRep
{
  assert(0);
}   

- (id)initWithCoder:(NSCoder *)coder
{
  assert(0);
}  

- initWithCode:(FSCNBase *)theCode symbolTable:(FSSymbolTable*)theSymbolTable signature:(struct BlockSignature)theSignature source:(NSString*)theSource isCompiled:(BOOL)is_comp isCompact:(BOOL)isCompactArg sel:(SEL)theSel selStr:(NSString*)theSelStr
{
  assert(0);
}

- (BOOL) isCompact
{
  assert(0);
}

- (BOOL) isEqual:anObject
{
  assert(0);
}

- (FSMsgContext *)msgContext 
{
  assert(0);
}

- (id)retain
{
  assert(0);
}

- (NSUInteger)retainCount
{
  assert(0);
}

- (void)release
{
  assert(0);
}

- (SEL) selector
{
  assert(0);
}

- (NSString *)selectorStr 
{ 
  assert(0);
}

- (void) setInterpreter:(FSInterpreter *)theInterpreter
{
  assert(0);
}

- (void)showError:(NSString*)errorMessage 
{ 
  assert(0);
}

- (void)showError:(NSString*)errorMessage start:(NSInteger)firstCharacterIndex end:(NSInteger)lastCharacterIndex
{
  assert(0);
}

-(FSSymbolTable *) symbolTable
{ 
  assert(0);
}

-(id) valueArgs:(id*)args count:(NSUInteger)count
{  
  assert(0);
}


//////////////////////////////// USER METHODS ////////////////////////////

- (NSInteger) argumentCount 
{ 
  assert(0);
}

/*- (void) bind:(NSString *)name to:(id)anObject
 {
 if (![name isKindOfClass:[NSString class]]) FSArgumentError(name,1,@"NSString",@"bind:to:");
 
 [self compilIfNeeded];
 [blockRep bind:name to:anObject];
 }
 
 - (id) binding:(NSString*)name
 {
 if (![name isKindOfClass:[NSString class]]) FSArgumentError(name,1,@"NSString",@"binding:");
 
 [self compilIfNeeded];
 return [blockRep binding:name];
 }*/

- blockFromString:(NSString *)source  // May raise
{
  assert(0);
}

- blockFromString:(NSString *)source onError:(Block *)errorBlock // May raise
{
  assert(0);
}

- (Block *) clone
{ 
  assert(0);
}

- (NSString *)description
{
  assert(0);
}

- (id) guardedValue:(id)arg1
{
  assert(0);
}

- (void) inspect
{
  assert(0);
}

- (id)onException:(Block *)handler
{
  assert(0);
}

- (FSBoolean *)operator_equal:(id)operand
{
  assert(0);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  assert(0);
}

- (void) return 
{ 
  assert(0);
} 

- (void) return:(id)rv 
{
  assert(0);
}

- (void) setValue:(Block*)val
{
  assert(0);
}

- (id) value
{ 
  assert(0);
}

- (id) value:(id)arg1
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2
{ 
  assert(0);
}  

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9
{ 
  assert(0);
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10
{ 
  assert(0);
} 

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11
{ 
  assert(0);
} 

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11 value:(id)arg12
{ 
  assert(0);
} 

- (id) valueWithArguments:(NSArray *)operand
{ 
  assert(0);
}

- (void) whileFalse
{ 
  assert(0);
}  

- (void) whileFalse:(Block*)iterationBlock
{
  assert(0);
}  

- (void) whileTrue
{ 
  assert(0);
}  

- (void) whileTrue:(Block*)iterationBlock
{
  assert(0);
}  

@end

@implementation Block (BlockPrivate)

- (BlockRep *)blockRep        
{
  assert(0);
}

-(id)body_compact_valueArgs:(id*)args count:(NSUInteger)count
{
  assert(0);
} 

-(id)body_notCompact_valueArgs:(id*)args count:(NSUInteger)count
{
  assert(0);
}  

- (FSBlockCompilationResult *) compilation // Compil the receiver if needed. Return the result of the compilation. 
{
  assert(0);
}

- (void)evaluateWithDoubleFrom:(double)start to:(double)stop by:(double)step 
// precondition:  step != 0
{
  assert(0);
}

- (BlockInspector *)inspector 
{ 
  assert(0);
}

- (SEL)messageToArgumentSelector
{
  assert(0);
}

-(Block *) totalCopy
{
  assert(0);
}

- (void) setNewRepAfterCompilation:(BlockRep*)newRep
{
  assert(0);
}  

- sync
{
  assert(0);
}       

@end
