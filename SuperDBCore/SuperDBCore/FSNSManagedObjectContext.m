/* FSNSManagedObjectContext.m Copyright (c) 2005-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 

#import "FSNSManagedObjectContext.h"
#import "FScriptFunctions.h"
#import "FSSystemPrivate.h"

#if !TARGET_OS_IPHONE
# import "FSManagedObjectContextInspector.h"
#endif

@implementation NSManagedObjectContext(FSNSManagedObjectContext)

- (void)inspectWithSystem:(FSSystem *)system
{
  FSVerifClassArgsNoNil(@"inspectWithSystem:",1,system,[FSSystem class]);
  if (![system interpreter]) FSExecError(@"Sorry, can't open the inspector because there is no FSInterpreter associated with the FSSystem object passed as argument");

#if !TARGET_OS_IPHONE
  [FSManagedObjectContextInspector managedObjectContextInspectorWithmanagedObjectContext:self interpreter:[system interpreter]];
#endif
}


@end
