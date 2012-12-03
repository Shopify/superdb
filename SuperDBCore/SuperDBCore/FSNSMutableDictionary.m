/* FSNSMutableDictionary.m Copyright (c) 2010 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 

#import "FSNSMutableDictionary.h"
#import "FScriptFunctions.h"

@implementation NSMutableDictionary(FSNSMutableDictionary)

- (void)at:(id)aKey put:(id)anObject
{
   if (aKey == nil)
     FSExecError(@"argument 1 of method \"at:put:\" must not be nil");
   else if (anObject == nil)
     FSExecError(@"argument 2 of method \"at:put:\" must not be nil");
   else
     [self setObject:anObject forKey:aKey];
}

@end
