/*   FSSystem.m Copyright (c) 1998-2000 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "FSSystem.h"
#import <Foundation/Foundation.h>
#import "FSUnarchiver.h"
#import "FSBlock.h"
#import "FSVoid.h"
#import "Space.h"
#import "FScriptFunctions.h"
#import "FSInterpreterResult.h"
#import "FSNSString.h"
#import "FSArray.h"
#import "FSMiscTools.h"
#import "FSInterpreter.h"
#import "FSKeyedUnarchiver.h"
#import "ArrayRepFetchRequest.h"
#import "ArrayPrivate.h"
#import "FSSymbolTable.h"
#import <CoreData/CoreData.h>

#if TARGET_OS_IPHONE
//# import <AudioToolbox/AudioToolbox.h>
#else
# import <AppKit/AppKit.h>
#endif

@interface FSSystem(SystemInternal)
- (id)executor;
- (FSInterpreter *)interpreter;
@end

@implementation FSSystem

static BOOL loadNonKeyedArchives; 

+ (void)setLoadNonKeyedArchives:(BOOL)b
{  
  loadNonKeyedArchives = b;
}
 
+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  { 
    loadNonKeyedArchives = NO;
    tooLate = YES;
  }
}

+ system:(id)theExecutor
{ return [[[self alloc] init:theExecutor] autorelease]; }


- (void)attach:(id)objectContext
{
  FSVerifClassArgsNoNil(@"attach:",1,objectContext,[NSManagedObjectContext class]);

  NSArray *entities = [[[objectContext persistentStoreCoordinator] managedObjectModel] entities];
  NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
  NSFetchRequest  *request = [[[NSFetchRequest alloc] init] autorelease];
  FSInterpreter *interpreter = [self interpreter];
  if (!interpreter) FSExecError(@"Can't attach: missing F-Script interpreter");

  [request setPredicate:predicate];

  for (NSUInteger i = 0, count = [entities count]; i < count; i++)
  {
    NSError *error;
    NSEntityDescription *entity = [entities objectAtIndex:i]; 
    [request setEntity:entity];
    
    NSArray *objects = [objectContext executeFetchRequest:request error:&error];
    
    if (objects == nil) 
      FSExecError([NSString stringWithFormat:@"Error while fetching entity %@: %@", [entity name], [error localizedDescription]]);    
    else
      [interpreter setObject:objects forIdentifier:[entity name]];       
  }
}

- copy
{ return [self copyWithZone:NULL]; }

- copyWithZone:(NSZone *)zone
{ return [[FSSystem allocWithZone:zone] init:executor]; }

- (void)dealloc
{
  [executor release];
  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat:@"<%@>",descriptionForFSMessage(self)];
}

- (id)replacementObjectForCoder:(NSCoder *)aCoder
{ 
  return [NSNull null];
}

- init:(id)theExecutor
{
  if ((self = [super init]))
  {
    executor = [theExecutor retain];
    return self;
  }
  return nil;    
}

- (FSInterpreter *)interpreter // Will return nil if the associated interpreter no longer exists
{
  return [executor interpreter];
}

- (void)verboseLevel:(NSInteger)theVerboseLevel {[executor setVerboseLevel:theVerboseLevel];}

///////////////////////////////////// USER METHODS ////////////////////////

- (void)beep 
{
#if TARGET_OS_IPHONE
  //AudioServicesPlayAlertSound(0x00001000);
#else
  NSBeep();
#endif
}
 
- blockFromString:(NSString *)source // May raise
{
  FSVerifClassArgsNoNil(@"blockFromString:", 1, source, [NSString class]);
  return [FSBlock blockWithSource:source parentSymbolTable:[executor symbolTable]]; // May raise
}

- blockFromString:(NSString *)source onError:(FSBlock *)errorBlock // May raise
{
  FSVerifClassArgsNoNil(@"blockFromString:onError:", 2, source, [NSString class], errorBlock, [FSBlock class]);
  return [FSBlock blockWithSource:source parentSymbolTable:[executor symbolTable] onError:errorBlock]; // May raise
}

- (void)browse
{ 
  if (![executor interpreter]) FSExecError(@"Can't open the F-Script object browser: missing F-Script interpreter ");
  [[executor interpreter] browse]; 
}

- (void)browse:(id)anObject
{
  if (![executor interpreter]) FSExecError(@"Can't open the F-Script object browser: missing F-Script interpreter ");
  [[executor interpreter] browse:anObject];
}

- (void)clear
{
  NSArray *identifiers = [self identifiers];
  NSUInteger i, count;
  
  for (i = 0, count = [identifiers count]; i < count; i++)
  {
    NSString *identifier = [identifiers objectAtIndex:i];
    if (![identifier isEqualToString:@"sys"])
	  [self clear:identifier];
  }
}

- (void)clear:(NSString *)identifier
{
  FSSymbolTable *symbolTable = [executor symbolTable];
  struct FSContextIndex contextIndex = [symbolTable indexOfSymbol:identifier];

  if (contextIndex.index == -1)
    FSExecError(@"argument of method \"clear:\" must be the name of a defined variable");
  else if ([identifier isEqualToString:@"sys"])
    FSExecError(@"\"sys\" can't be removed from the workspace");
  else
  { 
    BOOL isDefined;
    [symbolTable objectForIndex:contextIndex isDefined:&isDefined];
	if (isDefined)
	  [symbolTable undefineSymbolAtIndex:contextIndex];
    else
	  FSExecError(@"argument of method \"clear:\" must be the name of a defined variable");
  }
}

- (FSSystem *)clone { return [[self copy] autorelease];}

- (NSString *)fullUserName 
{
  NSString *s = NSFullUserName();
  
  if (s) return [NSMutableString stringWithString:s];
  else return nil;
}

- (NSString *)homeDirectory 
{
  NSString *s = NSHomeDirectory();
  
  if (s) return [NSMutableString stringWithString:s];
  else return nil;
}

- (NSString *)homeDirectoryForUser:(NSString *)userName 
{
  NSString *s;
  
  FSVerifClassArgsNoNil(@"homeDirectoryForUser:",1,userName,[NSString class]);
  
  s = NSHomeDirectoryForUser(userName);
  
  if (s) return [NSMutableString stringWithString:s];
  else return nil;
}

- (FSArray *)identifiers
{
  return [executor allDefinedSymbols];
}

- (void) installFlightTutorial
{ 
  [executor installFlightTutorial]; 
} 

- (id)ktest
{
  NSString *path;
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *testSuiteFileName = @"KTest";

  if ((path = [bundle pathForResource:testSuiteFileName ofType:@"txt"]))
  {
    NSStringEncoding usedEncoding;
    NSError *error;
    
    NSString *ktestString = [NSString stringWithContentsOfFile:path usedEncoding:&usedEncoding error:&error];
    if (!ktestString)
    {
      NSString *errorMessage = [NSString stringWithFormat:@"Unable to read the ktest file: %@", [error localizedDescription]];
      NSLog(@"%@", errorMessage);
      return errorMessage;
    }
    
    return [(FSBlock *)[self blockFromString:ktestString] value];    
  }
  return nil;
}

- (id) load
{
#if !TARGET_OS_IPHONE
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  
  if([openPanel runModal] == NSOKButton) 
    return [self load:[openPanel filename]];
  else  // cancel button
    return [FSVoid fsVoid];
#else
  return [FSVoid fsVoid];
#endif
}  
 
- (id) load:(NSString *)fileName
{
  id r;
  NSString *errStr = nil;
  FSUnarchiver *unarchiver;
  NSData *data;
  NSString *logFmt = @"failure of loading: %@";
  
  FSVerifClassArgsNoNil(@"load:",1,fileName,[NSString class]);
            
  @try       
  { 
    data = [NSData dataWithContentsOfFile:fileName];
    if (data)
    {
      if (loadNonKeyedArchives)
      {
        unarchiver = [[[FSUnarchiver alloc] initForReadingWithData:data loaderEnvironmentSymbolTable:[executor symbolTable] symbolTableForCompiledCodeNode:nil] autorelease];
        r = [unarchiver decodeObject];
      }
      else
      {
        @try
        {
          FSKeyedUnarchiver * keyedUnarchiver = [[[FSKeyedUnarchiver alloc] initForReadingWithData:data loaderEnvironmentSymbolTable:[executor symbolTable] symbolTableForCompiledCodeNode:nil] autorelease];
          r = [keyedUnarchiver decodeObjectForKey:@"root"];
        }
        @catch (id exception)
        {
          unarchiver = [[[FSUnarchiver alloc] initForReadingWithData:data loaderEnvironmentSymbolTable:[executor symbolTable] symbolTableForCompiledCodeNode:nil] autorelease];
          r = [unarchiver decodeObject];
        }
      }
    }
    else
    {
      r = nil;
      errStr = [NSString stringWithFormat:@"loading: can't open file %@",fileName];
    }
  }  
  @catch (id exception)
  {
    r = nil;
    errStr = [NSString stringWithFormat:logFmt, FSErrorMessageFromException(exception)];
  }  
  
  if (r == nil)
  {
    if (!errStr) errStr = @"failure of loading";
    FSExecError(errStr);
  }
  return r;    
}    

- (void)loadSpace
{
#if !TARGET_OS_IPHONE
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  
  if([openPanel runModal] == NSOKButton) 
     [self loadSpace:[openPanel filename]];
#endif
}  

// Here is a version of loadSpace requiring the filetype to be of ".space"

/*

- (void)loadSpace
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSString *currentRequiredFileType = [panel requiredFileType]; 
  
  [panel setRequiredFileType:@"space"];
  if([panel runModalForTypes:[NSArray arrayWithObject:@"space"]] == NSOKButton)
  { 
     [panel setRequiredFileType:currentRequiredFileType];
     [self loadSpace:[String stringWithString:[panel filename]]];
  }
  [panel setRequiredFileType:currentRequiredFileType];
}
*/

- (void)loadSpace:(NSString *)fileName
{
  Space *space = [self load:fileName];
  [executor setSpace:space];
}

- (void)log:(id)object;
{
  if ([object isKindOfClass:[NSString class]]) NSLog(@"%@", object);
  else                                         NSLog(@"%@", printString(object));
}

- (void)saveSpace
{
#if !TARGET_OS_IPHONE
  NSSavePanel *panel = [NSSavePanel savePanel];
    
  if ([panel runModal] == NSOKButton)
    [self saveSpace:[panel filename]];
#endif
}      

// Here is a version of saveSpace requiring the filetype to be of ".space"

/*
- (void)saveSpace
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  NSString *currentRequiredFileType = [panel requiredFileType];
  
  [panel setRequiredFileType:@"space"];
  if([panel runModal] == NSOKButton)
  {
     [panel setRequiredFileType:currentRequiredFileType];
     [self saveSpace:[String stringWithString:[panel filename]]];
  }
  [panel setRequiredFileType:currentRequiredFileType];
}
*/

- (void)saveSpace:(NSString *)fileName  
{
  [self retain]; // In order to not be dealloced when removed from the current workspace
  
  if (![executor interpreter]) FSExecError(@"Can't open the F-Script object browser because the F-Script interpreter no longer exists");
  
  [[executor interpreter] setObject:nil forIdentifier:@"sys"]; 
  // Since "sys" does not know how to archive itself, we remove 
  // it from the workspace in order to avoid F-Script warnings. 
  
  // We use an exception domain in order to ensure that "sys" is reinstalled into the workspace even if
  // something goes wrong during archiving. 
  @try
  {
    [[executor space] save:fileName];
  }
  @finally
  {
    [[executor interpreter] setObject:self forIdentifier:@"sys"];
    [self release];
  }
}

- (void) setValue:(FSSystem*)operand
{ 
  FSVerifClassArgsNoNil(@"setValue:",1,operand,[FSSystem class]);
  [executor autorelease];
  executor = [[operand executor] retain];
}

- (id)executor  {return executor;}

/*
- (void)setSpace:(Space*)space
{
  FSVerifClassArgsNoNil(@"setSpace:",1,space,[Space class]);
  [executor setSpace:space];
}
*/

- (NSString *)userName 
{   
  NSString *s = NSUserName();
  
  if (s) return [NSMutableString stringWithString:s];
  else return nil;
}

@end
