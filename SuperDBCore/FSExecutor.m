/*   Executor.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.   */  

#import "build_config.h"
#import "FSExecutor.h"
#import "FSCompiler.h"
#import <objc/objc.h>
#import "FScriptFunctions.h"
#import "string.h"
#import "FSSymbolTable.h"
#import "FSExecEngine.h"
#import <Foundation/Foundation.h>
#import "FSArray.h"
#import "FSCompilationResult.h"
#import "FSBoolean.h"
#import "FSSystem.h"
#import "FSInterpreterResultPrivate.h"
#import "Space.h"
#import "BlockStackElem.h"
#import "FSBlock.h"
#import "BlockPrivate.h"
#import "FSNumber.h"
#import "FSVoid.h"
#import "FSMiscTools.h"
#import "FSReturnSignal.h"

void __attribute__ ((constructor)) initializeFSExecutor(void) 
{
  [NSKeyedUnarchiver setClass:[FSExecutor class] forClassName:@"Executor"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"Executor" asClassName:@"FSExecutor"];  
#endif
}

@implementation FSExecutor

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    [self setVersion:1];
    [FSVoid initialize]; // to have the fsVoid global variable initialized
    [FSBoolean initialize]; // to have the fsTrue and fsFalse global variables initialized
    //[NSAutoreleasePool enableFreedObjectCheck:YES];
    tooLate = YES;
  }
}

- (FSArray *) allDefinedSymbols
{
  return [localSymbolTable allDefinedSymbols];
}

- (void) breakCycles
{
  // Break the potential cycles caused by localSymbolTable
  // for example: localSymbolTable --> a block --> a symbolTable -(parent)-> localSymbolTable
  
  [localSymbolTable removeAllObjects];
}

- (void) dealloc
{
  //NSLog(@"Executor dealloc");
  
  [journalName release];
  [journal release];
  [localSymbolTable release];
  [compiler release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeConditionalObject:interpreter forKey:@"interpreter"];
  [coder encodeBool:should_journal forKey:@"shouldJournal"];
  [coder encodeObject:localSymbolTable forKey:@"symbolTable"];  
}
  
-(FSInterpreterResult *)execute:(NSString *)command
{
  FSCompilationResult *compilationResult;
  struct res_exec execResult;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  FSInterpreterResult *r;
  
  if (should_journal && journal)
  {
    [journal writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];
    [journal writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [journal synchronizeFile];
  }

  compilationResult = [compiler compileCode:[command UTF8String] withParentSymbolTable:localSymbolTable];

  switch(compilationResult->type)
  {
  case ERROR :
    if (compilationResult->errorLastCharacterIndex == -1)
      r = [FSInterpreterResult interpreterResultWithStatus:FS_SYNTAX_ERROR result:nil errorRange:NSMakeRange(0,0) errorMessage:compilationResult->errorMessage callStack:nil];
    else
      r = [FSInterpreterResult interpreterResultWithStatus:FS_SYNTAX_ERROR result:nil errorRange:NSMakeRange(compilationResult->errorFirstCharacterIndex, 1+compilationResult->errorLastCharacterIndex - compilationResult->errorFirstCharacterIndex) errorMessage:compilationResult->errorMessage callStack:nil];
  
    break;
 
  case OK :
  {    
    if (verboseLevel >= 5) NSLog(@"before execute()");
    
    @try
    {
      execResult = execute(compilationResult->code, localSymbolTable); // may raise
      
      if (execResult.errorStr)
      {
        id callStack = [execResult.exception isKindOfClass:[NSException class]] ? [[execResult.exception userInfo] objectForKey:@"FScriptBlockStack"] : nil;
        r = [FSInterpreterResult interpreterResultWithStatus:FS_EXECUTION_ERROR result:nil errorRange:NSMakeRange(execResult.errorFirstCharIndex, 1+execResult.errorLastCharIndex - execResult.errorFirstCharIndex) errorMessage:execResult.errorStr callStack:callStack];              
      }
      else
        r = [FSInterpreterResult interpreterResultWithStatus:FS_OK result:execResult.result errorRange:NSMakeRange(0,0) errorMessage:nil callStack:nil];    
    }
    @catch (FSReturnSignal *returnSignal)
    {
      r = [FSInterpreterResult interpreterResultWithStatus:FS_EXECUTION_ERROR result:nil errorRange:NSMakeRange(0,0) errorMessage:@"invalid return" callStack:nil];
    }  
    break;
  }
  default : 
    r = nil;  // Should not happend. It's here to avoid a compiler warning.
    assert(0);
  } 
  
  [r retain];  // to move r out of pool
  if (verboseLevel >= 5) NSLog(@"before [pool release]");
  [pool release];    
  if (verboseLevel >= 5) NSLog(@"after [pool release]\n-------------------------------");
  return [r autorelease];
}

- initWithInterpreter:(FSInterpreter *)theInterpreter
{
  if ((self = [super init]))
  {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    interpreter = theInterpreter; // WARNING : no retain in order to avoid a cycle
    should_journal = NO;
    verboseLevel = 0;

    localSymbolTable = [[FSSymbolTable alloc] initWithParent:nil tryToAttachWhenDecoding:NO];
    [localSymbolTable insertSymbol:@"sys" object:[FSSystem system:self]];
     
    compiler = [[FSCompiler alloc] init];
    [pool release];
    
    return self;
  }
  return nil;    
}

- (id)initWithCoder:(NSCoder *)coder
{
  struct FSContextIndex ind;

  self = [super init];
  verboseLevel = 0;
  
  if ([coder allowsKeyedCoding]) 
  {
    interpreter = [coder decodeObjectForKey:@"interpreter"]; // WARNING : no retain in order to avoid a cycle  
    should_journal =[coder decodeBoolForKey:@"shouldJournal"];
    localSymbolTable = [[coder decodeObjectForKey:@"symbolTable"] retain];
  }
  else
  {
    interpreter = [coder decodeObject]; // WARNING : no retain in order to avoid a cycle  
    [coder decodeValueOfObjCType:@encode(typeof(should_journal)) at:&should_journal];

    if ([coder versionForClassName:@"Executor"] == 0)
    { 
	  int temp;
      [coder decodeObject]; // In version 0 we stored the journal Name. 
      [coder decodeValueOfObjCType:@encode(typeof(verboseLevel)) at:&temp];
    }
  
    localSymbolTable = [[coder decodeObject] retain];
  }  
  
  ind = [localSymbolTable indexOfSymbol:@"sys"];
  if (ind.index != -1)
    [localSymbolTable setObject:[FSSystem system:self] forIndex:ind];
  else    
    [localSymbolTable insertSymbol:@"sys" object:[FSSystem system:self]];
  
  compiler = [[FSCompiler alloc] init];
  return self;
}

- (void)installFlightTutorial // Flight tutorial installation. May raise.
{
  NSString *path;
  NSString *tutorialInstalation;
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  BOOL shouldJournal = [self shouldJournal];

  if ((path = [bundle pathForResource:@"FlightTutorial" ofType:@"txt"]))
  {
    FSInterpreterResult *res;
    NSStringEncoding usedEncoding;
    NSError *error;
    
    tutorialInstalation = [NSString stringWithContentsOfFile:path usedEncoding:&usedEncoding error:&error];
    if (!tutorialInstalation)
    {
      NSLog(@"Unable to read the flight tutorial instalation file: %@", [error localizedDescription]);
    }
    [self setShouldJournal:NO]; 
    res = [self execute:tutorialInstalation];
    [self setShouldJournal:shouldJournal];
    if (![res isOK]) [[NSException exceptionWithName:@"FSInternalError" reason:[NSString stringWithFormat:@"Error during Flight tutorial installation: %@",[res errorMessage]] userInfo:nil] raise];
  }
}

-(FSInterpreter *)interpreter // Will return nil if the associated interpreter no longer exists
{ return interpreter; }

- (void)interpreterIsDeallocating
{
  interpreter = nil; // WARNING: no retain/release on this pointer in order to avoid a cycle  
}

- (id)objectForSymbol:(NSString *)symbol found:(BOOL *)found // foud may be passed as NULL
{
  return [localSymbolTable objectForSymbol:symbol found:found];
}

- performOpenFile:(NSString *)file
{
  NSString *fname = [file lastPathComponent];
  NSUInteger nb = [fname length];
        
  while (nb != ([fname = [fname stringByDeletingPathExtension] length]))
    nb = [fname length]; // remove all extensions
      
  return self;
}  

- (BOOL)setJournalName:(NSString *)filename
{
  NSString *oldJournalName = journalName;
  NSFileHandle *oldJournal = journal;
  NSDictionary *fileAttributes;
  NSUInteger maxLength = 80000000; // The journal file will be truncated if it is bigger than 80 Mo.
  
  if (!filename) return NO;

  if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) [[NSFileManager defaultManager] createFileAtPath:filename contents:[NSData data] attributes:nil];
  
  fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:NULL];
  
  if ([[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue] > maxLength)
  {
    NSData *journalData = [NSData dataWithContentsOfFile:filename];
    NSData *truncatedJournalData = [journalData subdataWithRange:NSMakeRange([journalData length]-(maxLength/2), (maxLength/2))];
    [truncatedJournalData writeToFile:filename atomically:YES];
  }  
  
  journal = [[NSFileHandle fileHandleForWritingAtPath:filename] retain];
  [journal seekToEndOfFile];
  
  if (journal)
  {
    [oldJournal release];
    journalName = [filename copy];
    [oldJournalName release];
    return YES;
  }
  else return NO;    
}

- (void)setShouldJournal:(BOOL)shouldJournal { should_journal = shouldJournal; }  

-(void)setObject:(id)object forSymbol:(NSString *)symbol
{
  [localSymbolTable setObject:object forSymbol:symbol];
}

- (void) setVerboseLevel:(NSInteger)theVerboseLevel {verboseLevel = theVerboseLevel;}

- (BOOL)shouldJournal
{ return should_journal; }

// ULSYSTEM PROTOCOL (informal)

- (void)setSpace:(Space*)space // must be called from an interpreter execution (a user command) because of intruction (A)
{
  struct FSContextIndex ind;
  
  [localSymbolTable autorelease];  // There is a problem here: a symbolTable can have several retain cycles involving Blocks and the parent pointer of their symbolTables. So this autorelease may not avoid a memory leak.
  [self breakCycles]; // This solve the problem discussed above, but create another one: the symbolTable is now empty, so objects that migth access it may not like it (ex: a block wich is executed may get a "symbol not defined" error).  
 
  localSymbolTable = [[space localSymbolTable] retain];
  
  ind = [localSymbolTable indexOfSymbol:@"sys"];
  
  if (ind.index != -1) [localSymbolTable setObject:[FSSystem system:self] forIndex:ind];
  else                 [localSymbolTable insertSymbol:@"sys" object:[FSSystem system:self]];
    
  [(FSBlock *)[self objectForSymbol:@"fs_latent" found:NULL] value]; // (A)   This instruction may raise (value is a user method)
}  

- (Space*)space
{ 
  return [[[Space alloc] initSymbolTableLocale:localSymbolTable] autorelease];
}  

- (FSSymbolTable *) symbolTable { return localSymbolTable;}

@end
