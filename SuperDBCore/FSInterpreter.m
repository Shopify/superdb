/* FSInterpreter.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import "FSInterpreter.h"
#import "FSExecutor.h"
#import "FSBooleanPrivate.h"
#import "FSVoidPrivate.h"
#import "FSArray.h"
#import "FSCompiler.h"

#if !TARGET_OS_IPHONE
# import "FSInterpreterPrivate.h"
# import "FSObjectBrowser.h"
#endif

@implementation FSInterpreter

+ (BOOL) validateSyntaxForIdentifier:(NSString *)identifier
{
   return [FSCompiler isValidIdentifier:identifier];
}

+ (void)initialize 
{
  static BOOL tooLate = NO;
  
  if (tooLate) return;
  tooLate = YES;
  
  // Dynamic class loading
  
  NSString *repositoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"FScriptRepositoryPath"];
  
  if (repositoryPath)
  {
    NSString *dirName = [repositoryPath stringByAppendingPathComponent:@"classes"]; 
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:dirName];
    NSString *pname; 

    while ((pname = [direnum nextObject])) 
    {
      if ([[pname pathExtension] isEqualToString:@"bundle"] || [[pname pathExtension] isEqualToString:@"framework"])
      {
        NSBundle *bundle = [NSBundle bundleWithPath:[dirName stringByAppendingPathComponent:pname]];
        [direnum skipDescendents]; // don't enumerate this directory
        [bundle principalClass];
      }
    }
  } 
}

+ (FSInterpreter *)interpreter
{
  return [[[self alloc] init] autorelease];
}

#if TARGET_OS_IPHONE
- (void)browse {

}

- (void)browse:(id)anObject {

}
#else
- (FSObjectBrowserButtonCtxBlock *) objectBrowserButtonCtxBlockFromString:(NSString *)source // May raise
{
  return [FSObjectBrowserButtonCtxBlock blockWithSource:source parentSymbolTable:[executor symbolTable]]; // May raise
}

- (void)browse 
{
  FSObjectBrowser *bb = [FSObjectBrowser objectBrowserWithRootObject:nil interpreter:self];
  [bb browseWorkspace];
  [bb makeKeyAndOrderFront:nil];
}

- (void)browse:(id)anObject
{
  [[FSObjectBrowser objectBrowserWithRootObject:anObject interpreter:self] makeKeyAndOrderFront:nil];
}
#endif

-(void)dealloc
{
  //NSLog(@"FSInterpreter dealloc");
  [executor breakCycles];
  [executor interpreterIsDeallocating];
  [executor release];
  [super dealloc];
}

- (NSArray *) identifiers
{
  return [executor allDefinedSymbols];
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) 
  {
    [coder encodeObject:executor forKey:@"executor"];
  }
  else
  {
    [coder encodeObject:executor];
  }  
}

-(FSInterpreterResult *)execute:(NSString *)command
{
  return [executor execute:command];
}

-(id)init
{
  if ((self = [super init]))
  {
    executor = [[FSExecutor alloc] initWithInterpreter:self];
    return self;
  }
  return nil;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ([coder allowsKeyedCoding]) 
  {
    executor = [[coder decodeObjectForKey:@"executor"] retain];    
  }
  else
  {
    executor = [[coder decodeObject] retain];  
  }  
  return self;
}

- (void) installFlightTutorial
{
  [executor installFlightTutorial];
}

- (id)objectForIdentifier:(NSString *)identifier found:(BOOL *)found
{
  return [executor objectForSymbol:identifier found:found];
}

- (BOOL)setJournalName:(NSString *)filename
{
  return [executor setJournalName:filename];
}

-(void)setObject:(id)object forIdentifier:(NSString *)identifier
{
  [executor setObject:object forSymbol:identifier];
}

- (void)setShouldJournal:(BOOL)shouldJournal
{
  [executor setShouldJournal:shouldJournal];
}

- (BOOL)shouldJournal
{ return [executor shouldJournal]; }

@end
