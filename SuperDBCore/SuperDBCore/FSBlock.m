
/*   FSBlock.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "FSBlock.h"
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
#import "FSNumber.h"
#import "FSVoid.h"
#import "FSMiscTools.h"
#import "FSNSString.h"
#import "FSInterpreterResultPrivate.h"
#import "FSReturnSignal.h"
#import "Block_fscript.h"

#if !TARGET_OS_IPHONE
# import "BlockInspector.h"
#endif

void __attribute__ ((constructor)) initializeFSBlock(void) 
{
  [NSKeyedUnarchiver setClass:[FSBlock class] forClassName:@"Block"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"Block" asClassName:@"FSBlock"];  
#endif
}


NSString *FS_Block_keyOfSetValueForKeyMessage(FSBlock *s) 
{
  if (s == nil) return nil;
  
  @try
  {
    [s compilIfNeeded];
  }
  @catch (id exception)
  {
    return nil;
  }
  
  return [[s blockRep] keyOfSetValueForKeyMessage];
}

@implementation FSBlock

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

+ (id) alloc
{
   return NSAllocateObject(self, 0, NULL);
}             
                                       
+ allocWithZone:(NSZone *)zone
{
  return NSAllocateObject(self, 0, NULL);
}

+ blockWithSelector:(SEL)theSelector
{
  return [[@"#" stringByAppendingString:[FSCompiler stringFromSelector:theSelector]] asBlock]; 
}

+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable
{
  return [self blockWithSource:source parentSymbolTable:parentSymbolTable onError:nil];
}  

+ blockWithSource:(NSString *)source parentSymbolTable:(FSSymbolTable *)parentSymbolTable onError:(FSBlock *)errorBlock
{

  struct BlockSignature signature = {0,NO}; 
  FSBlock *r = [[[self alloc] initWithCode:nil symbolTable:parentSymbolTable signature:signature source:[[source copy] autorelease] isCompiled:NO isCompact:NO sel:(SEL)0 selStr:nil] autorelease];
  return [r compilOnError:errorBlock];
} 

+ (void)initialize
{
    static BOOL tooLate = NO;
    if ( !tooLate ) {
        tooLate = YES;
    }
} 

- (NSArray *)argumentsNames
{
  return [blockRep argumentsNames];
}

- (id)ast
{
  [self compilIfNeeded];
  return [blockRep ast];
}

- (void) compilIfNeeded {[self compilOnError:nil];}  // May raise

- (id)compilOnError:(FSBlock *)errorBlock // May raise
{ 
  [self sync];
  return [blockRep compilForBlock:self onError:errorBlock];
}    

- copy
{ return [self copyWithZone:NULL]; }

- copyWithZone:(NSZone *)zone
{
  [self compilIfNeeded];
  
  // Blocks can share the same BlockRep only if they have no local symbols.
  if ([blockRep signature].hasLocals)
  {
    // The block has local symbols
    BlockRep *new = [blockRep copyWithZone:zone];
    FSBlock *r =[[FSBlock allocWithZone:zone] initWithBlockRep:new];
    
    [new release];
    return r;
  }
  else 
  { 
    //NSLog(@"no copy of %@",self);
    return [[FSBlock allocWithZone:zone] initWithBlockRep:blockRep];
  }
}

- (void)dealloc
{
  //NSLog(@"FSBlock dealloc"); 
  [blockRep useRelease];
  [blockRep release];
  [inspector release];
  [super dealloc];
}  

- (void)encodeWithCoder:(NSCoder *)coder
{  
  [self sync];

  if ( [coder allowsKeyedCoding] ) 
  {
    [coder encodeObject:blockRep forKey:@"FSBlock blockRep"];
  }
  else
  {
    [coder encodeObject:blockRep];
  }  
} 

- (FSInterpreterResult *)executeWithArguments:(NSArray *)arguments
{
  [self sync];
  if (![arguments isKindOfClass:[NSArray class]])
    [NSException raise:NSInvalidArgumentException format:@"argument of method \"executeWithArguments:\" must be an NSArray"];

  return [blockRep executeWithArguments:arguments block:self];
}

- (NSUInteger) hash
{
  BOOL isCompact = NO;
  
  @try
  {
    isCompact = [self isCompact]; // will cause the block to be compiled if needed and thus may raise.
  }
  @catch (id exception) {}
    
  if (isCompact) return [[blockRep selectorStr] hash];
  else return [super hash];
}

- (id) initWithBlockRep:(BlockRep *)theBlockRep
{
  if ((self = [super init]))
  {
    retainCount = 1;
    blockRep = [[theBlockRep retain] useRetain];
    inspector = nil;
    return self;
  }
  return nil;    
}   
 
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  retainCount = 1;  // It is important that this initialization is made before decoding 
                    // the blockRep because in decoding blockRep, some retain may be sent to this block
  if ( [coder allowsKeyedCoding] ) 
  {
    blockRep  = [[[coder decodeObjectForKey:@"FSBlock blockRep"] retain] useRetain];
    
    if (blockRep == nil)
      // Use the old key name
      blockRep  = [[[coder decodeObjectForKey:@"Block blockRep"] retain] useRetain];
  }
  else
  {
    blockRep  = [[[coder decodeObject] retain] useRetain];
  }  
  inspector = nil;
  return self;
}  

- initWithCode:(FSCNBase *)theCode symbolTable:(FSSymbolTable*)theSymbolTable signature:(struct BlockSignature)theSignature source:(NSString*)theSource isCompiled:(BOOL)is_comp isCompact:(BOOL)isCompactArg sel:(SEL)theSel selStr:(NSString*)theSelStr
{
  if ((self = [super init]))
  {
    blockRep = [[BlockRep alloc] initWithCode:theCode symbolTable:theSymbolTable signature:theSignature source:theSource isCompiled:is_comp isCompact:isCompactArg sel:theSel selStr:theSelStr];
    [blockRep useRetain];
    inspector = nil;
    retainCount = 1;
    return self;
  }
  return nil;    
}

- (BOOL) isCompact
{
  [self compilIfNeeded]; // may raise
  return [blockRep isCompact];
}

- (BOOL) isEqual:anObject
{
  BOOL r = NO;
  
  if (self == anObject) 
    return YES;
  else if ([anObject isKindOfClass:[FSBlock class]])
  {    
    @try
    {
      r = [self isCompact] && [(FSBlock *)anObject isCompact] &&   // may raise
          [blockRep selector] == [((FSBlock *)anObject)->blockRep selector];
    }
    @catch (id exception) {}
  }
  return r;
}


- (BOOL)isKindOfClass:(Class)aClass // For backward compatibility with code referencing the old Block class, we pretend to be a Block
{
  if (aClass == [Block class]) 
    return YES;
  else
    return [super isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass // For backward compatibility with code referencing the old Block class, we pretend to be a Block
{
  if (aClass == [Block class]) 
    return YES;
  else
    return [super isMemberOfClass:aClass];
}

- (FSMsgContext *)msgContext 
{
  [self compilIfNeeded]; // may raise
  return [blockRep msgContext]; 
}

- (id)retain
{
  retainCount++;
  return self;
}

- (NSUInteger)retainCount
{
  return retainCount;
}

- (void)release
{
  if (--retainCount == 0)  [self dealloc];
}

- (SEL) selector
{
  [self compilIfNeeded]; // may raise
  return [blockRep selector];
}

- (NSString *)selectorStr 
{ 
  [self compilIfNeeded]; // may raise
  return [blockRep selectorStr]; 
}

- (void) setInterpreter:(FSInterpreter *)theInterpreter
{
  [blockRep setInterpreter:theInterpreter];
}

- (void)showError:(NSString*)errorMessage 
{ 
  [[self inspector] showError:errorMessage]; 
}

- (void)showError:(NSString*)errorMessage start:(NSInteger)firstCharacterIndex end:(NSInteger)lastCharacterIndex
{
  
  [[self inspector] showError:errorMessage start:firstCharacterIndex end:lastCharacterIndex];
}

-(FSSymbolTable *) symbolTable
{ return [blockRep symbolTable];}

-(id) valueArgs:(id*)args count:(NSUInteger)count
{  
  [self compilIfNeeded];  
  return [blockRep valueArgs:args count:count block:self];
}


//////////////////////////////// USER METHODS ////////////////////////////

- (NSInteger) argumentCount { [self compilIfNeeded]; return [blockRep argumentCount];}

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
  FSVerifClassArgsNoNil(@"blockFromString:",1,source,[NSString class]);
  
  [self compilIfNeeded];
  return [FSBlock blockWithSource:source parentSymbolTable:[blockRep symbolTable]];
}

- blockFromString:(NSString *)source onError:(FSBlock *)errorBlock // May raise
{
  FSVerifClassArgsNoNil(@"blockFromString:onError",2,source,[NSString class],errorBlock,[FSBlock class]);
  
  [self compilIfNeeded];
  return [FSBlock blockWithSource:source parentSymbolTable:[blockRep symbolTable] onError:errorBlock];
}

- (FSBlock *) clone
{ return [[self copy] autorelease]; }

- (NSString *)description
{
  [self sync];
  return [[[blockRep source] copy] autorelease]; 
}

- (id) guardedValue:(id)arg1
{
  FSInterpreterResult *interpreterResult = [self executeWithArguments:[FSArray arrayWithObject:arg1]]; // We use an FSArray instead of NSArray because arg1 might be nil
  
  if ([interpreterResult isOk])
  {
    return [interpreterResult result];
  }
  else
  {
    [self showError:[interpreterResult errorMessage]]; // usefull if the call stack is empty
    [interpreterResult inspectBlocksInCallStack];
    return nil;
  }
}

- (void) inspect
{
#if !TARGET_OS_IPHONE
  [[self inspector] activate]; 
#endif
}

- (id)onException:(FSBlock *)handler
{
  FSVerifClassArgs(@"onException:",1,handler,[FSBlock class],(NSInteger)1);
  if ([self argumentCount] != 0) FSExecError(@"receiver of message \"onException:\" must be a block with no argument");
  if ([handler argumentCount] > 1) FSExecError(@"argument of method \"onException:\" must be a block with zero or one argument (the actual argument will be the exception)");

  @try
  {
    return [self value];
  }
  @catch (FSReturnSignal *returnSignal)
  {
    @throw;
  }  
  @catch (id exception)
  {
    return [handler value:exception]; 
  }
  
  assert(0);  // we'll never reach this code.
  return nil; // to disable a warning
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (void) return { [self return:[FSVoid fsVoid]]; } 

- (void) return:(id)rv 
{
  @throw [FSReturnSignal returnSignalWithBlock:self result:rv];
}

- (void) setValue:(FSBlock*)val
{
  BlockRep *oldRep;
  
  FSVerifClassArgsNoNil(@"setValue:",1,val,[FSBlock class]);
  
  if (val == self) return;
  
  [val compilIfNeeded];
  oldRep = blockRep;
  
  // Blocks can share the same BlockRep only if they have no local symbols. 
  if ([[val blockRep] signature].hasLocals)  
    // The block val has local symbols 
    blockRep = [[[val blockRep] copyWithZone:[self zone]] useRetain];
  else
    blockRep = [[[val blockRep] retain] useRetain];
  
  [oldRep useRelease];
  [oldRep release];

  [inspector update];
  [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"BlockDidChangeNotification" object:self] postingStyle:NSPostWhenIdle];
}

- (id) value
{ return [self valueArgs:(id*)nil count:1];}

- (id) value:(id)arg1
{ 
  id args[2] = {arg1,nil};
  return [self valueArgs:args count:2];
}

- (id) value:(id)arg1 value:(id)arg2
{ 
  id args[3] = {arg1,nil,arg2};
  return [self valueArgs:args count:3];
}  

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3
{ 
  id args[4] = {arg1,nil,arg2,arg3};
  return [self valueArgs:args count:4];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4
{ 
  id args[5] = {arg1,nil,arg2,arg3,arg4};
  return [self valueArgs:args count:5];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5
{ 
  id args[6] = {arg1,nil,arg2,arg3,arg4,arg5};
  return [self valueArgs:args count:6];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6
{ 
  id args[7] = {arg1,nil,arg2,arg3,arg4,arg5,arg6};
  return [self valueArgs:args count:7];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7
{ 
  id args[8] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7};
  return [self valueArgs:args count:8];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8
{ 
  id args[9] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7,arg8};
  return [self valueArgs:args count:9];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9
{ 
  id args[10] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9};
  return [self valueArgs:args count:10];
}

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10
{ 
  id args[11] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10};
  return [self valueArgs:args count:11];
} 

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11
{ 
  id args[12] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11};
  return [self valueArgs:args count:12];
} 

- (id) value:(id)arg1 value:(id)arg2 value:(id)arg3 value:(id)arg4 value:(id)arg5 value:(id)arg6 value:(id)arg7 value:(id)arg8 value:(id)arg9 value:(id)arg10 value:(id)arg11 value:(id)arg12
{ 
  id args[13] = {arg1,nil,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12};
  return [self valueArgs:args count:13];
} 

- (id) valueWithArguments:(NSArray *)operand
{ 
  VERIF_OP_NSARRAY(@"valueWithArguments:");
  [self compilIfNeeded];
  return [blockRep valueWithArguments:operand block:self];
}

- (void) whileFalse
{ 
  NSAutoreleasePool *pool;
  short i;
  BOOL cond = NO; // initialization of cond in order to avoid a warning
  id resEval; 
 
  [self compilIfNeeded]; 
   
  if ([self argumentCount] != 0) FSExecError(@"method \"whileFalse\" must be sent to a block with no arguments");
   
  while (1)
  {
    pool = [[NSAutoreleasePool alloc] init];
    i = 0;
 
    while (i < 300 && (cond = ((resEval = [self body_notCompact_valueArgs:(id*)nil count:1]) == fsFalse || ([resEval isKindOfClass:[FSBoolean class]] && ![resEval isTrue]))))
    {
      i++;
    }
    [pool release];
    if (!cond) break;
  }        
}  

- (void) whileFalse:(FSBlock*)iterationBlock
{
  NSAutoreleasePool *pool;
  short i;
  BOOL cond = NO; //initialization of cond in order to avoid a warning
  id resEval; 

  FSVerifClassArgsNoNil(@"whileFalse:",1,iterationBlock,[FSBlock class]);
  
  [self compilIfNeeded];
   
  if ([self argumentCount] != 0) 
    FSExecError(@"method \"whileFalse:\" must be called on a block with no arguments");
  
  if ([iterationBlock argumentCount] != 0)
    FSExecError(@"argument 1 of method \"whileFalse:\" must be a block with no arguments");    
  
  while (1)
  {
    pool = [[NSAutoreleasePool alloc] init];
    i = 0;
 
    while (i < 300 && (cond = ((resEval = [self body_notCompact_valueArgs:(id*)nil count:1]) == fsFalse || ([resEval isKindOfClass:[FSBoolean class]] && ![resEval isTrue]))))
    {
      i++;
      [iterationBlock body_notCompact_valueArgs:(id*)nil count:1];
    }
    [pool release];
    if (!cond) break;
  }
}  

- (void) whileTrue
{ 
  NSAutoreleasePool *pool;
  short i;
  BOOL cond = NO; // initialization of cond in order to avoid a warning
  id resEval; 
  
  [self compilIfNeeded];
   
  if ([self argumentCount] != 0) FSExecError(@"method \"whileTrue\" must be sent to a block with no arguments");
   
  while (1)
  {
    pool = [[NSAutoreleasePool alloc] init];
    i = 0;
 
    while (i < 300 && (cond = ((resEval = [self body_notCompact_valueArgs:(id*)nil count:1]) == fsTrue || ([resEval isKindOfClass:[FSBoolean class]] && [resEval isTrue]))))
    {
      i++;
    }
    [pool release];
    if (!cond) break;
  }        
}  

- (void) whileTrue:(FSBlock*)iterationBlock
{
  NSAutoreleasePool *pool;
  short i;
  BOOL cond = NO; // initialization of cond in order to avoid a warning
  id resEval; 

  FSVerifClassArgsNoNil(@"whileTrue:",1,iterationBlock,[FSBlock class]);
  
  [self compilIfNeeded];
   
  if ([self argumentCount] != 0)
    FSExecError(@"method \"whileTrue:\" must be called on a block with no arguments");
  
  if ([iterationBlock argumentCount] != 0)
    FSExecError(@"argument 1 of method \"whileTrue:\" must be a block with no arguments");    
  
  while (1)
  {
    pool = [[NSAutoreleasePool alloc] init];
    i = 0;
 
    while (i < 300 && (cond = ((resEval = [self body_notCompact_valueArgs:(id*)nil count:1]) == fsTrue || ([resEval isKindOfClass:[FSBoolean class]] && [resEval isTrue]))))
    {
      i++;
      [iterationBlock body_notCompact_valueArgs:(id*)nil count:1];
    }
    [pool release];
    if (!cond) break;
  }
  /*while ([self body_notCompact_valueArgs:(id*)nil count:1] == fsTrue)
  {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //short i = 0;
    [iterationBlock body_notCompact_valueArgs:(id*)nil count:1];
    [pool release];
    // i++;
    //if (i == 30)
    //{
    //  if (NXUserAborted()) FSUserAborted();
    //  else i = 0; 
    //} 
  } */        
}  

@end

@implementation FSBlock (FSBlockPrivate)

- (BlockRep *)blockRep        { return blockRep;}

-(id)body_compact_valueArgs:(id*)args count:(NSUInteger)count
{
  return [blockRep body_compact_valueArgs:args count:count block:self];
} 
   
-(id)body_notCompact_valueArgs:(id*)args count:(NSUInteger)count
{
  return [blockRep body_notCompact_valueArgs:args count:count block:self];
}  

- (FSBlockCompilationResult *) compilation // Compil the receiver if needed. Return the result of the compilation. 
{
  [self sync];
  return [blockRep compilForBlock:self];
}

- (void)evaluateWithDoubleFrom:(double)start to:(double)stop by:(double)step 
// precondition:  step != 0
{
  FSNumber *args[2];   // In fact an array with the special layout needed for methods 
                       // body_compact_valueArgs:count:block: and body_notCompact_valueArgs:count:block:
  double newValue;                   
  NSAutoreleasePool *pool = nil; 
  
  if ((start < stop && step < 0) || (start > stop && step > 0)) return;

  if (start == stop)
  {
    [self value:[FSNumber numberWithDouble:start]];
    return;
  }
  
  [self compilIfNeeded];

  @try
  {
    args[0] = [[FSNumber alloc] initWithDouble:start];
    
    while (1)
    {
      short i = 0;

      pool = [[NSAutoreleasePool alloc] init];
    
      if ([blockRep isCompact])
      {
        if (start < stop)
        {
          while (i < 1000 && args[0]->value <= stop)
          {
            [blockRep body_compact_valueArgs:args count:2 block:self];  // may raise
            i++;
            newValue = args[0]->value + step;
            [args[0] release];
            args[0] = [[FSNumber alloc] initWithDouble:newValue];
          }
          if (args[0]->value > stop)
          {
            [args[0] release];
            break;
          }
        }
        else if (start > stop)
        {
          while (i < 1000 && args[0]->value >= stop)
          {
            [blockRep body_compact_valueArgs:args count:2 block:self];  // may raise
            i++;
            newValue = args[0]->value + step;
            [args[0] release];
            args[0] = [[FSNumber alloc] initWithDouble:newValue];
          }
          if (args[0]->value < stop)
          {
            [args[0] release];
            break;
          }
        }    
      }
      else
      {
        if (start < stop)
        {  
          while (i < 1000 && args[0]->value <= stop)
          {
            [blockRep body_notCompact_valueArgs:args count:2 block:self];  // may raise
            i++;
            newValue = args[0]->value + step;
            [args[0] release];
            args[0] = [[FSNumber alloc] initWithDouble:newValue];
          }
          if (args[0]->value > stop)
          {
            [args[0] release];
            break;
          }
        }  
        else if (start > stop)
        {  
          while (i < 1000 && args[0]->value >= stop)
          {
            [blockRep body_notCompact_valueArgs:args count:2 block:self];  // may raise
            i++;
            newValue = args[0]->value + step;
            [args[0] release];
            args[0] = [[FSNumber alloc] initWithDouble:newValue];
          }
          if (args[0]->value < stop)
          {
            [args[0] release];
            break;
          }          
        }  
      } 
      [pool release]; 
    }
  }  
  @catch (id exception)
  {
    [exception retain];
    [pool release];
    [args[0] release];
    [exception autorelease]; 
    @throw;
  }          
}

#if TARGET_OS_IPHONE
- (id) inspector {
  return nil;
}
#else
- (BlockInspector *)inspector 
{ 
  if (!inspector) inspector = [[BlockInspector alloc] initWithBlock:self];
  return inspector;
}
#endif

- (SEL)messageToArgumentSelector
{
  @try
  {
    [self compilIfNeeded];
  }
  @catch (id exception)
  {
    return (SEL)0;
  }

  return [blockRep messageToArgumentSelector];
}

-(FSBlock *) totalCopy
{
  BlockRep *new;
  FSBlock *r;
  
  [self sync];
  
  new = [blockRep copy];
  r =[[FSBlock alloc] initWithBlockRep:new];
  [new release];
  return r;
}
  
- (void) setNewRepAfterCompilation:(BlockRep*)newRep
{
  [newRep retain]; [newRep useRetain];
  [blockRep useRelease]; [blockRep release];
  blockRep = newRep;
}  
  
- sync
{
#if !TARGET_OS_IPHONE
  if ([inspector edited])
  {
    BlockRep * new = [blockRep copy];
    [new newSource:[inspector source]];
    [blockRep useRelease]; 
    [blockRep release];
    blockRep = new;
    [blockRep useRetain];
    [inspector setEdited:NO]; 
  }    
#endif
  return self;
}       

@end
