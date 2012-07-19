/*   Executor.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <objc/objc.h>
#import "FSArray.h"

@class Space;
@class FSCompiler;
@class FSSymbolTable; 
@class FSInterpreter;
@class FSInterpreterResult;

@interface FSExecutor:NSObject <NSCoding>
{
  FSInterpreter *interpreter; 
  // WARNING: No retain done on this pointer, in order to avoid a cycle.
  // I add this ivar in order for a FSSystem object to be able to implement the object browser opening.
  
  BOOL should_journal;
  NSInteger verboseLevel;
  NSFileHandle *journal;
  NSString *journalName;
  FSSymbolTable *localSymbolTable;
  FSCompiler *compiler;
}

- (FSArray *) allDefinedSymbols;
- (void)breakCycles;
- (FSInterpreterResult *)execute:(NSString *)command;
- initWithInterpreter:(FSInterpreter *)theInterpreter;
- (void)installFlightTutorial;
- (FSInterpreter *)interpreter; // Will return nil if the associated interpreter no longer exists
- (void)interpreterIsDeallocating;
- (id)objectForSymbol:(NSString *)symbol found:(BOOL *)found; // found may be passed as NULL
- (BOOL)setJournalName:(NSString *)filename;
- (void)setShouldJournal:(BOOL)shouldJournal;
- (void)setObject:(id)object forSymbol:(NSString *)symbol;
- (void)setVerboseLevel:(NSInteger)theVerboseLevel;
- (BOOL)shouldJournal;

// ULSYSTEM PROTOCOL (informal)

- (void)setSpace:(Space*)space;
- (Space*)space;
- (FSSymbolTable *)symbolTable;

@end
