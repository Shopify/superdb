/*   FSGlobalScope.h Copyright (c) 2009 Philippe Mougin.   */
/*   This software is open source. See the license.        */  

#import <Foundation/Foundation.h>

@class FSGlobalScope;

extern FSGlobalScope *FSSharedGlobalScope;

@interface FSGlobalScope : NSObject 
{
  NSMutableDictionary *globals;
}

- (id) objectForSymbol:(NSString *)symbol found:(BOOL *)found; // found may be passed as NULL
- (void) setObject:(id)object forSymbol:(NSString *)symbol;    // object must ne non-nil (current implementation does not support storing nil in the global scope)

@end
