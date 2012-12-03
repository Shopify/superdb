/*   FSSystem.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSObject.h"

@class FSBlock;
@class FSExecutor;

@interface FSSystem:NSObject <NSCopying>
{
  FSExecutor *executor; 
  // A FSSystem object point to an Executor instance. Why not an FSInterpreter
  // instance instead? Because it would create a retain cycle that would 
  // prevent the whole object graph (FSInterpreter, FSExecutor, FSSymbolTable, etc.)
  // to be dealoced. But pointing to the Executor also creates a cycle! 
  // However, the dealloc method of FSInterpreter do what is necessary to break 
  // this cycle. 
  // Could the problem be resolved by FSSystem not retaining the FSInterpreter?
  // No, because a FSSystem object can be referenced "externaly" by other objects.
  // Hence its lifecycle is not always determined by  the lifecycle of the 
  // FSInterpreter instance.
}

+ system:(id)theSys;

- copy;
- copyWithZone:(NSZone *)zone;
- (void)dealloc;
- init:(id)theSys;

///////////////////////////////////// USER METHODS ////////////////////////

- (void)attach:(id)objectContext;
- (void)beep;
- blockFromString:(NSString *)source;
- blockFromString:(NSString *)source onError:(FSBlock *)errorBlock;
- (void)browse;
- (void)browse:(id)anObject;
- (void)clear;
- (void)clear:(NSString *)identifier;
- (FSSystem *)clone __attribute__((deprecated));
- (NSString *)fullUserName;
- (NSString *)homeDirectory;
- (NSString *)homeDirectoryForUser:(NSString *)userName;
- (id)ktest;
- (FSArray *)identifiers;
- (void)installFlightTutorial;
- (id)load;
- (id)load:(NSString *)fileName;
- (void)loadSpace __attribute__((deprecated));
- (void)loadSpace:(NSString *)fileName ;
- (void)log:(id)object __attribute__((deprecated));
- (void)saveSpace __attribute__((deprecated));
- (void)saveSpace:(NSString *)fileName;
- (void)setValue:(FSSystem *)operand ;
- (NSString *)userName;

@end
