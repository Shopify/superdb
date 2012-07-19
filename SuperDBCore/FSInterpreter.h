/* FSInterpreter.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>
#import "FSInterpreterResult.h"

@class FSExecutor;

@interface FSInterpreter : NSObject <NSCoding>
{
  FSExecutor *executor;
}

+ (FSInterpreter *)interpreter;
+ (BOOL) validateSyntaxForIdentifier:(NSString *)identifier;

- (void) browse;
- (void) browse:(id)anObject;
- (NSArray *) identifiers;
- (FSInterpreterResult *) execute:(NSString *)command;
- (void) installFlightTutorial;
- (id)   objectForIdentifier:(NSString *)identifier found:(BOOL *)found; // found may be passed as NULL
- (void) setObject:(id)object forIdentifier:(NSString *)identifier;
- (BOOL) setJournalName:(NSString *)filename;
- (void) setShouldJournal:(BOOL)shouldJournal;
- (BOOL) shouldJournal;

@end
