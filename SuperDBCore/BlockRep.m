
/*   BlockRep.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "BlockRep.h"
#import "FSExecEngine.h"
#import "FSCompiler.h" 
#import "FSArray.h"
#import <Foundation/Foundation.h> 
#import "FSBoolean.h"
#import "FScriptFunctions.h"
#import "FSUnarchiver.h" 
#import "FSKeyedUnarchiver.h"
#import "FSBlock.h"
#import "BlockPrivate.h"
#import "FSNumber.h"
#import "BlockStackElem.h"
#import "FSVoid.h"
#import "FSInterpreter.h"
#import "FSMiscTools.h"
#import "FSBlockCompilationResult.h"
#import "FSInterpreterResultPrivate.h"
#import "ArrayPrivate.h"
#import "FSReturnSignal.h"
#import "FSCNIdentifier.h"
#import "FSCNBlock.h"
#import "FSCNBase.h"
#import "FSCNKeywordMessage.h"
#import "FSCNPrecomputedObject.h"

@implementation BlockRep

+ (void)initialize 
{
    static BOOL tooLate = NO;
    if ( !tooLate ) 
    {
      [FSVoid initialize]; // to have the fsVoid static variable initialized
      [FSBoolean initialize]; // to have the fsTrue and fsFalse static variables initialized
      tooLate = YES;
    }
}

- (NSInteger) argumentCount { return signature.argumentCount;}
  
- (NSArray *)argumentsNames
{
  if ([self isCompact])
  {
    if ([self argumentCount] > 1) 
    {
      NSUInteger i, count;
      NSMutableArray *selectorComponents = [[[selStr componentsSeparatedByString:@":"] mutableCopy] autorelease];
     
      NSMutableCharacterSet *letterUnderscoreDollarCharacterSet = (NSMutableCharacterSet *)[NSMutableCharacterSet letterCharacterSet];
      [letterUnderscoreDollarCharacterSet addCharactersInString:@"_"];
      [letterUnderscoreDollarCharacterSet addCharactersInString:@"$"];

      if ([letterUnderscoreDollarCharacterSet characterIsMember:[[selectorComponents objectAtIndex:0] characterAtIndex:0]])
        for (i = 0, count = [selectorComponents count]; i < count; i++)
          [selectorComponents replaceObjectAtIndex:i withObject:[[selectorComponents objectAtIndex:i] stringByAppendingString:@":"]];
      
      return [[NSArray arrayWithObject:@"receiver"] arrayByAddingObjectsFromArray:selectorComponents];
    }
    else if (sel == (SEL)0) return [NSArray array];
    else                    return [NSArray arrayWithObject:@"receiver"];                      
  }
  else
  {
    NSMutableArray *r = [NSMutableArray array];
    NSInteger argumentCount = [self argumentCount];
    struct FSContextIndex contextIndex = {0,0}; 

    while (contextIndex.index < argumentCount)
    {
      [r addObject:[symbol_table symbolForIndex:contextIndex]];
      contextIndex.index++;
    }
    return r;
  }
}

- (FSCNBase *)ast
{
  return ac;
}

- (FSBlockCompilationResult *) compilForBlock:(FSBlock *)block   // May cause self to be deallocated.
{
  /* NOTE: There is a problem in this method. Since we compil
     with a new symbol table, the subblocks that might point to the
     old one will not point to the new one. This gives, in certain
     situations, a strange semantic to the block concept!
     To fix this problem one migth think we just have to compil
     with the old symbol table, but doing so raise at least another
     problem: the local symbols of the new block may differ from the
     old, so subblocks may not reach the good values of the symbols 
     they are referencing, due to the representation of identifiers
     in compiled code node objects.
  */

  FSCompilationResult *compilationResult;

  if (is_compiled) return [FSBlockCompilationResult blockCompilationResultWithType:FSOKBlockCompilationResultType errorMessage:nil errorFirstCharacterIndex:0 errorLastCharacterIndex:0];
 
  if (signature.hasLocals)
    compilationResult = [[FSCompiler compiler] compileCodeForBlock:[source UTF8String] withParentSymbolTable:[symbol_table parent]];
  else
    compilationResult = [[FSCompiler compiler] compileCodeForBlock:[source UTF8String] withParentSymbolTable:symbol_table];

  switch(compilationResult->type)
  {
  case ERROR : return [FSBlockCompilationResult blockCompilationResultWithType:FSErrorBlockCompilationResultType errorMessage:compilationResult->errorMessage errorFirstCharacterIndex:compilationResult->errorFirstCharacterIndex errorLastCharacterIndex:compilationResult->errorLastCharacterIndex];
  case OK :
    {        
      BlockRep *newRep = ((FSCNBlock *)(compilationResult->code))->blockRep;        
      [newRep setInterpreter:interpreter];
      [block setNewRepAfterCompilation:newRep]; // Note: this may cause self to be deallocated
      return [FSBlockCompilationResult blockCompilationResultWithType:FSOKBlockCompilationResultType errorMessage:nil errorFirstCharacterIndex:0 errorLastCharacterIndex:0];
      break;
    }           
  } // end_switch  
  {assert(0); return nil;} //W
}

- (id) compilForBlock:(FSBlock *)block onError:(FSBlock *)errorBlock // May raise. May cause self to be deallocated.
{
  /* NOTE: There is a problem in this method. Since we compil
     with a new symbol table, the subblocks that might point to the
     old one will not point to the new one. This gives, in certain
     situations, a strange semantic to the block concept !
     To fix this problem one migth think we just have to compil
     with the old symbol table, but doing so raise at least another
     problem: the local symbols of the new block may differ from the
     old, so subblocks may not reach the good values of the symbols 
     they are referencing, due to the representation of identifiers
     in compiled code node objects.
  */

  FSBlockCompilationResult *compilationResult = [self compilForBlock:block]; // may cause self to be deallocated
  
  switch(compilationResult->type)
  {
  case ERROR :
    if (errorBlock) return [errorBlock value:compilationResult->errorMessage value:[FSNumber numberWithDouble:compilationResult->errorFirstCharacterIndex] value:[FSNumber numberWithDouble:compilationResult->errorLastCharacterIndex]];
    else
    {
      NSMutableDictionary *userInfo       = [NSMutableDictionary dictionaryWithCapacity:1];
      NSMutableArray      *blockStack     = [NSMutableArray array]; // This blockStack will represent the call stack of blocks.           
      BlockStackElem      *blockStackElem = [BlockStackElem blockStackElemWithBlock:block errorStr:compilationResult->errorMessage firstCharIndex:compilationResult->errorFirstCharacterIndex lastCharIndex:compilationResult->errorLastCharacterIndex];

      [blockStack addObject:blockStackElem];
      [userInfo setObject:blockStack forKey:@"FScriptBlockStack"]; 
      
	  @throw [NSException exceptionWithName:FSExecutionErrorException reason:[NSString stringWithFormat:@"syntax error in a block: %@", compilationResult->errorMessage] userInfo:userInfo];      
	}             
  case OK : return block;
  } // end_switch  
    
  {assert(0); return nil;} //W
}

- copyWithZone:(NSZone *)zone
{
  FSSymbolTable *s;
  BlockRep *r;
  
  if (signature.hasLocals) s = [symbol_table copyWithZone:zone];
  else                     s = symbol_table;
  
  r = [[BlockRep allocWithZone:zone] initWithCode:ac symbolTable:s signature:signature source:source isCompiled:is_compiled isCompact:isCompact sel:sel selStr:[[selStr copyWithZone:zone] autorelease]];
  [r setInterpreter:interpreter]; // The current policy is to share the interpreter
  if (signature.hasLocals) [s release];
  
  return r;  
}

- (void)dealloc
{
  //NSLog(@"BlockRep dealloc");
  if (useCount) FSExecError(@"F-Script internal error: dealloc for a blockRep with a positive useCount !!!");
  [ac release];
  [symbol_table release];
  [source release];
  [interpreter release];
  if (isCompact)
  {
    [selStr release];
    [msgContext release];
  }
  [super dealloc];
}  

- (void)encodeWithCoder:(NSCoder *)coder
{  
    [coder encodeInt:signature.argumentCount forKey:@"signature.argumentCount"];
    [coder encodeBool:signature.hasLocals forKey:@"signature.hasLocals"];
    if (signature.hasLocals) [coder encodeObject:symbol_table forKey:@"symbolTable"];
    else                     [coder encodeConditionalObject:symbol_table forKey:@"symbolTable"]; 
    [coder encodeObject:source forKey:@"source"];
    [coder encodeBool:is_compiled forKey:@"isCompiled"];
    [coder encodeObject:interpreter forKey:@"interpreter"];
    [coder encodeBool:isCompact forKey:@"isCompact"];
    if (is_compiled) [coder encodeObject:ac forKey:@"compiledCode"];  
} 
 
- (FSInterpreterResult *)executeWithArguments:(NSArray *)arguments block:(FSBlock *)block
{
  FSBlockCompilationResult *compilationResult = [self compilForBlock:block];
  id value;
  
  switch (compilationResult->type)
  {
  case FSOKBlockCompilationResultType: break;
  case FSErrorBlockCompilationResultType: 
    if (compilationResult->errorLastCharacterIndex == -1)
      return [FSInterpreterResult interpreterResultWithStatus:FS_SYNTAX_ERROR result:nil errorRange:NSMakeRange(0,0) errorMessage:compilationResult->errorMessage callStack:nil];
    else
      return [FSInterpreterResult interpreterResultWithStatus:FS_SYNTAX_ERROR result:nil errorRange:NSMakeRange(compilationResult->errorFirstCharacterIndex, 1+compilationResult->errorLastCharacterIndex - compilationResult->errorFirstCharacterIndex) errorMessage:compilationResult->errorMessage callStack:nil];
    break;
  }    
  
  @try
  {
    value = [self valueWithArguments:arguments block:block];
  }
  @catch (FSReturnSignal *returnSignal)
  {
    return [FSInterpreterResult interpreterResultWithStatus:FS_EXECUTION_ERROR result:nil errorRange:NSMakeRange(0,0) errorMessage:FSErrorMessageFromException(returnSignal) callStack:nil]; 
  }
  @catch (NSException *exception)
  {
    NSDictionary   *userInfo   = [exception userInfo];
    NSArray        *blockStack = [userInfo objectForKey:@"FScriptBlockStack"];
    
    if (blockStack)
    {
      if ([blockStack count] == 0)
      { 
        // The exception is probably coming from an invalid number of arguments provided for block evaluation.   
        @throw;
        assert(0); return nil;
      }
      else
      {
        BlockStackElem *blockStackElem = [blockStack objectAtIndex:0];
        return [FSInterpreterResult interpreterResultWithStatus:FS_EXECUTION_ERROR result:nil errorRange:NSMakeRange([blockStackElem firstCharIndex], 1+[blockStackElem lastCharIndex]-[blockStackElem firstCharIndex]) errorMessage:[blockStackElem errorStr] callStack:blockStack];
      }
    }
    else
    {
      // The exception is probably coming from an invalid number of arguments provided for block evaluation.   
      @throw;
      assert(0); return nil;
    }  
  }
  @catch(id exception)
  {
    return [FSInterpreterResult interpreterResultWithStatus:FS_EXECUTION_ERROR result:nil errorRange:NSMakeRange(0,0) errorMessage:FSErrorMessageFromException(exception) callStack:nil];
  }
  
  return [FSInterpreterResult interpreterResultWithStatus:FS_OK result:value errorRange:NSMakeRange(0,0) errorMessage:nil callStack:nil];
} 
 
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  retainCount = 1;
  useCount = 0;
  
  if ( [coder allowsKeyedCoding] ) 
  {
    signature.argumentCount = [coder decodeIntForKey:@"signature.argumentCount"];
    signature.hasLocals = [coder decodeBoolForKey:@"signature.hasLocals"];
    symbol_table = [[coder decodeObjectForKey:@"symbolTable"] retain];
    source       = [[coder decodeObjectForKey:@"source"] retain];
    is_compiled  = [coder decodeBoolForKey:@"isCompiled"];
    interpreter  = [[coder decodeObjectForKey:@"interpreter"] retain];
    isCompact    = [coder decodeBoolForKey:@"isCompact"];

    if (symbol_table == nil && [coder isKindOfClass:[FSKeyedUnarchiver class]]) // symbol_table == nil implies block has no locals (but note that "block has no locals" does not implies "symbol_table == nil")
      symbol_table = [[(FSKeyedUnarchiver *)coder loaderEnvironmentSymbolTable] retain]; 
    
    if (is_compiled)
    {
      if ([coder isKindOfClass:[FSKeyedUnarchiver class]])
      {
        FSSymbolTable *oldst = [(FSKeyedUnarchiver*)coder symbolTableForCompiledCodeNode];
        NSString *oldSource = [(FSKeyedUnarchiver*)coder source];
        if (oldst != nil) // if it's not a top-level block (because this case is already managed in FSSymbolTable::initWithCoder:). As a side note: in this method, we use the fact that only an "F-Script instanciated" block, wich is not in a compiled code node, can have a binding to another block. If it was not the case, the problem would be that a bound block would be decoded in the symbolTable context of the block that has a binding to it...
        {
          if (signature.hasLocals) [symbol_table setParent:oldst];
          else 
          {
            [symbol_table release];
            symbol_table = [oldst retain]; 
          }  
        }  
  
        [(FSKeyedUnarchiver*)coder setSymbolTableForCompiledCodeNode:symbol_table];
        [(FSKeyedUnarchiver*)coder setSource:source]; 
        ac = [[coder decodeObjectForKey:@"compiledCode"] retain];
        [(FSKeyedUnarchiver*)coder setSymbolTableForCompiledCodeNode:oldst];
        [(FSKeyedUnarchiver*)coder setSource:oldSource];
      }        
      else
        ac = [[coder decodeObjectForKey:@"compiledCode"] retain];
    }
    else
      ac = nil;     
  }
  else
  {
    struct  
    {
      int bindingCount;
      int argumentCount;
      BOOL hasLocals;
    } sign;

    [coder decodeValueOfObjCType:@encode(typeof(sign)) at:&sign];
    signature.argumentCount = sign.argumentCount;
    signature.hasLocals = sign.hasLocals;
    
    symbol_table = [[coder decodeObject] retain];
    source       = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(typeof(is_compiled)) at:&is_compiled];
    interpreter = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(typeof(isCompact)) at:&isCompact];
    
	if (symbol_table == nil && [coder isKindOfClass:[FSUnarchiver class]]) // symbol_table == nil implies block has no locals (but note that "block has no locals" does not implies "symbol_table == nil")
      symbol_table = [[(FSUnarchiver *)coder loaderEnvironmentSymbolTable] retain]; 
  
    if (is_compiled)
    {
      if ([coder isKindOfClass:[FSUnarchiver class]])
      {
        FSSymbolTable *oldst = [(FSUnarchiver*)coder symbolTableForCompiledCodeNode];
        NSString *oldSource = [(FSUnarchiver*)coder source];
        if (oldst != nil) // if it's not a top-level block (because this case is already managed in FSSymbolTable::initWithCoder:). As a side note: in this method, we use the fact that only an "F-Script instanciated" block, wich is not in a compiled code node, can have a binding to another block. If it was not the case, the problem would be that a bound block would be decoded in the symbolTable context of the block that has a binding to it...
        {
          if (signature.hasLocals) [symbol_table setParent:oldst];
          else 
          {
            [symbol_table release];
            symbol_table = [oldst retain]; 
          }  
        }  
  
        [(FSUnarchiver*)coder setSymbolTableForCompiledCodeNode:symbol_table];
        [(FSUnarchiver*)coder setSource:source]; 
        ac = [[coder decodeObject] retain];
        [(FSUnarchiver*)coder setSymbolTableForCompiledCodeNode:oldst];
        [(FSUnarchiver*)coder setSource:oldSource];
      }        
      else
        ac = [[coder decodeObject] retain];
    }
    else
      ac = nil;      
  }  

  if (isCompact)
  {
    selStr = [[source substringFromIndex:1] retain];
    sel = [FSCompiler selectorFromString:selStr];
    msgContext = [[FSMsgContext alloc] init];  
  }
                                  
  //NSLog([ac description]);
  return self;
}


// If you pass NO for is_comp, you must pass the *parent* symbol table for theSybolTableArgument
// This method retains theCode, theSymbolTable and theSource. No copy.
- initWithCode:(FSCNBase *)theCode symbolTable:(FSSymbolTable*)theSymbolTable signature:(struct BlockSignature)theSignature source:(NSString*)theSource isCompiled:(BOOL)is_comp isCompact:(BOOL)isCompactArg sel:(SEL)theSel selStr:(NSString*)theSelStr;
{
  if ((self = [super init]))
  {
    retainCount   = 1;
    useCount      = 0;
    ac            = [theCode retain];
    symbol_table  = [theSymbolTable retain];
    signature     = theSignature;
    source        = [theSource retain];
    is_compiled   = is_comp;                              
    isCompact     = isCompactArg;
    sel           = theSel;
    
    if (isCompact)
    {
      selStr = [theSelStr retain];
      msgContext = [[FSMsgContext alloc] init];  
    }
    return self;
  }
  return nil;    
}

- (BOOL)isCompact { return isCompact; }

- (NSString *)keyOfSetValueForKeyMessage
{
  if (   ![self isCompact]
      && [self argumentCount] == 1
      && ac->nodeType == KEYWORD_MESSAGE
      && ((FSCNKeywordMessage *)ac)->receiver->nodeType == IDENTIFIER
      && ((FSCNKeywordMessage *)ac)->selector == @selector(valueForKey:) 
      && ((FSCNKeywordMessage *)ac)->pattern == nil
      && [((FSCNIdentifier *)(((FSCNKeywordMessage *)ac)->receiver))->identifierString isEqualToString:[[self argumentsNames] objectAtIndex:0]]
      && ((FSCNKeywordMessage *)ac)->arguments[0]->nodeType == OBJECT
      && [((FSCNPrecomputedObject *)((FSCNKeywordMessage *)ac)->arguments[0])->object isKindOfClass:[NSString class]])
  {    
    return ((FSCNPrecomputedObject *)((FSCNKeywordMessage *)ac)->arguments[0])->object;
  }
  else return nil;   
}

- (SEL)messageToArgumentSelector 
{
  if ([self argumentCount] == 1) 
  {
    if ([self isCompact]) return [self selector];
    else
    {            
      if (   (ac->nodeType == UNARY_MESSAGE || ac->nodeType == BINARY_MESSAGE || ac->nodeType == KEYWORD_MESSAGE)
          && ((FSCNMessage *)ac)->receiver->nodeType == IDENTIFIER
          && ((FSCNMessage *)ac)->pattern == nil
          && [((FSCNIdentifier *)(((FSCNMessage *)ac)->receiver))->identifierString isEqualToString:[[self argumentsNames] objectAtIndex:0]])
      {    
        return ((FSCNMessage *)ac)->selector;
      }   
    } 
  }
  return (SEL)0;
}


-(FSMsgContext *)msgContext { return msgContext; }

- (void)newSource:(NSString *)theNewSource
{
  NSString *oldSource = source; 
  source = [theNewSource copy];
  [oldSource release];
  is_compiled = NO;
}

- (FSBlock *)newBlockWithParentSymbolTable:(FSSymbolTable *)parent
{
  // Blocks can share the same BlockRep only if they have no local symbols.
  // Note that this method must be called on a block which is already compiled 
  if (!signature.hasLocals)
  {
    if (symbol_table == parent) return [[[FSBlock alloc] initWithBlockRep:self] autorelease];
    else if (useCount == 0) 
    {
      [parent retain]; 
      [symbol_table release]; 
      symbol_table = parent ; 
      return [[[FSBlock alloc] initWithBlockRep:self] autorelease];
    }
  }
  
  {
    FSBlock *r;
    FSSymbolTable *s;
    BlockRep *new;
  
    if (signature.hasLocals)
    { 
      s = [symbol_table copy]; 
      [s setParent:parent]; 
    }
    else s = parent;

    new = [[BlockRep alloc] initWithCode:ac symbolTable:s  signature:signature source:source isCompiled:is_compiled isCompact:isCompact sel:sel selStr:[[selStr copy] autorelease]]; 
    if (signature.hasLocals) [s release];
    r = [[[FSBlock alloc] initWithBlockRep:new] autorelease];
    [new release];
    return r;
  }
}

- (id)retain { retainCount++; return self;}

- (NSUInteger)retainCount { return retainCount;}

- (void)release { if (--retainCount == 0)  [self dealloc];}

- (SEL)selector { return sel; }

- (NSString *)selectorStr { return selStr; }

- (void) setInterpreter:(FSInterpreter *)theInterpreter
{
  [theInterpreter retain];
  [interpreter release];
  interpreter = theInterpreter; 
}

- (struct BlockSignature) signature { return signature; }

- (NSString *)source { return source; }

-(FSSymbolTable *) symbolTable { return symbol_table;}

- (void) useRelease {useCount--; if (useCount < 0) FSExecError(@"F-Script internal Error: negative useCount for a BlockRep !");} 
- (id) useRetain    {useCount++; return self;}
- (NSInteger) useCount {return useCount;}

-(id)body_compact_valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block // May raise
{
  id r;
  
  [[block retain] autorelease]; 
  // To ensure the block is not deallocated while running (not a good thing!).
  // Such a situation may arise with this kind of F-Script code: b := [ b:= nil]. b value.
     
  @try
  {
    if (sel == (SEL)0) 
    { 
      sel = [FSCompiler selectorFromString:selStr]; 
      if (sel == (SEL)0) FSExecError(@"The #<null selector> block cannot be evaluated");
    }    
    args[1] = (id)sel;
    r = sendMsgNoPattern(args[0], sel, count, args, msgContext, nil);   // May raise    
  }
  @catch (FSReturnSignal *returnSignal)
  {
    if ([returnSignal block] == block) 
      r = [returnSignal result];
    else 
    {
      @throw; 
      assert(0); return nil; 
    }
  }
  @catch (NSException *exception)
  {
    NSMutableDictionary *userInfo;
    NSMutableArray *blockStack;
    
    if (!(userInfo = [[exception userInfo] mutableCopy])) 
      userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if (!(blockStack = [userInfo objectForKey:@"FScriptBlockStack"]))
    { // This blockStack will represent the callStack of blocks. We construct it in order to be able to have it when the exception is returned to the top level FSInterpreter (in order for example to provide it in the FSInterpreterResult) or to a block exception handler (see method -onException: of class Block to see how to use an exception handler at the F-Script language level)
      blockStack = [NSMutableArray array];
      [userInfo setObject:blockStack forKey:@"FScriptBlockStack"]; 
    }  
    
    [blockStack addObject:[BlockStackElem blockStackElemWithBlock:block errorStr:FSErrorMessageFromException(exception) firstCharIndex:0 lastCharIndex:[selStr length]]];

    @throw [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo]; // We do this to ensure the exception has a user info dictionnary (this may not be the case of the original exception)
  }  

  return r;
}

-(id)body_notCompact_valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block // May raise
{
  NSUInteger i,nb;
  struct res_exec execResult;
  FSSymbolTable *heap;
  struct FSContextIndex index;
      
  if (signature.hasLocals) 
  {
    heap = [[symbol_table copy] autorelease]; 
    [heap setToNilSymbolsFrom:signature.argumentCount];
  }
  else heap = symbol_table;
    
  index.level = 0;
  index.index = 0;

  if (signature.argumentCount > 0)
  {
    [heap setObject:args[0] forIndex:index];  
    for(i = 2, nb = signature.argumentCount+1 ; i < nb; i++)
    {
      index.index++;
      [heap setObject:args[i] forIndex:index];
    }  
  } 
  
  [[block retain] autorelease]; 
  // To ensure the block is not deallocated while running (not a good thing!).
  // Such a situation may arise with this kind of F-Script code: b := [ b:= nil]. b value.

  execResult = executeForBlock(ac, heap, block); // may raise 

  if (execResult.errorStr) @throw execResult.exception;
  else                     return execResult.result;
  
  {assert(0); return nil;} // to suppress a compiler warning
}  

-(id) valueArgs:(id*)args count:(NSUInteger)count block:(FSBlock *)block
{          
  if (count-1 < signature.argumentCount)
  {
    NSString *plural = (count-1 <= 1 ? @"" : @"s");
    FSExecError([NSString stringWithFormat:@"%lu argument%@ given for block evaluation, %lu expected", (unsigned long)(count-1), plural, (unsigned long)(signature.argumentCount)]);
  }
    
  if (isCompact) return [self body_compact_valueArgs:args count:count block:block];
  else           return [self body_notCompact_valueArgs:args count:count block:block];    
}  

- (id) valueWithArguments:(NSArray *)arguments block:(FSBlock *)block
{ 
  NSUInteger i;
  NSUInteger nb = [arguments count];
  
  if (nb == 0)
  {
    return [self valueArgs:NULL count:nb+1 block:block]; 
  }
  else
  {
    id args[nb+1];
  
    if (![arguments isKindOfClass:[FSArray class]] || [arguments isProxy])
    {
      args[0] = [arguments objectAtIndex:0];
      for (i = 1; i < nb; i++)  args[i+1] = [arguments objectAtIndex:i];
    }
    else 
    {
      id *argumentsData = [(FSArray *)arguments dataPtr];
      args[0] = argumentsData[0];
      for (i = 1; i < nb; i++) args[i+1] = argumentsData[i];
    }
    return [self valueArgs:args count:nb+1 block:block];
  }   
}

@end
