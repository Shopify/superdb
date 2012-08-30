/*   FSMethod.h Copyright (c) 2007-2009 Philippe Mougin.  */
/*   This software is open source. See the license.     */   

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
# include "ffi.h"
#else
# include <ffi/ffi.h>
#endif

@class FSBlock, FSSymbolTable, FSCNBase;
 
id   fscript_dynamicIvarValue(id instance, NSString *ivarName, BOOL *found);
NSSet *fscript_dynamicIvarNames(Class class);
BOOL fscript_isFScriptClass(Class class);
void fscript_registerFScriptClassPair(Class class);
BOOL fscript_setDynamicIvarValue(id instance, NSString *ivarName, id value);
void fscript_setDynamicIvarNames(Class class, NSSet *ivarNames); 

@interface FSMethod : NSObject
{
@package
  SEL                 selector;
  FSSymbolTable      *symbolTable;
  FSCNBase           *code;
  NSUInteger          argumentCount; // Number of arguments, including the two hidden arguments
  __strong char      *fsEncodedTypes;
  __strong char      *types;
  __strong char     **typesByArgument;
}

- (BOOL) addToClass:(Class)class;

- (id) initWithSelector:(SEL)theSelector fsEncodedTypes:(NSString *)theFSEncodedTypes types:(NSString *)theTypes typesByArgument:(NSArray *)theTypesByArgument argumentCount:(NSUInteger)theArgumentCount code:(FSCNBase *)theCode symbolTable:(FSSymbolTable *)theSymbolTable; 

@end
