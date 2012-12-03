/* FSNSProxy.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */

#import "build_config.h"
#import "FSNSProxy.h"
#import "FSNSStringPrivate.h"
#import "FSBoolean.h"
#import "FSNSString.h"
#import "FScriptFunctions.h"
#import "FSNSNumber.h"
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FSArray.h"
#import "FSBooleanPrivate.h"
#import "FSNSObject.h"

#if TARGET_OS_IPHONE
# import <objc/runtime.h>
#else
# import <objc/objc-runtime.h>
#endif

/* Note: Cocoa implementation of NSProxy is completely broken at the *class* level: most methods in the 
   NSObject protocol are not provided at the class level, the superclass method return incorect results etc.
   Some methods here (like methodSignatureForSelector:) are partial fixes for some aspects of this problem.
   This fixes are needed by F-Script because it makes use of these methods at some points, when the user
   want to manipulate directly classes of the NSProxy hierarchy.
*/

@interface NSMethodSignature(UndocumentedNSMethodSignature)
+ (NSMethodSignature*) signatureWithObjCTypes:(char *)types;
@end

@implementation NSProxy(FSNSProxy)

+ (NSString *)description
{
  return NSStringFromClass(self);
}

+ (BOOL)isKindOfClass:(Class)theClass
{
  Class cls = [self classOrMetaclass];

  while (cls != theClass && cls != nil && cls != [cls superclass]) cls = [cls superclass];
  // Note: Correct behavior for a root class is to return nil when asked for its superclass.
  // However, it seems that some root classes (e.g. NSProxy) return themselves instead.
  // The test above take the two possibilities into account.

  return cls == theClass; 
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  // Limitation: this is all hard wired here, and thus will not work for methods added in new categories or new subclasses.
  
  if      (selector ==  @selector(class))                       return [NSMethodSignature signatureWithObjCTypes:"#@:"];
  else if (selector ==  @selector(classOrMetaclass))            return [NSMethodSignature signatureWithObjCTypes:"#@:"];
  else if (selector ==  @selector(description))                 return [NSMethodSignature signatureWithObjCTypes:"@@:"];
  else if (selector ==  @selector(isKindOfClass:))              return [NSMethodSignature signatureWithObjCTypes:"c@:#"];
  else if (selector ==  @selector(isProxy))                     return [NSMethodSignature signatureWithObjCTypes:"c@:"];
  else if (selector ==  @selector(methodSignatureForSelector:)) return [NSMethodSignature signatureWithObjCTypes:"@@::"];
  else if (selector ==  @selector(operator_equal_equal:))       return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
  else if (selector ==  @selector(operator_tilde_tilde:))       return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
  else if (selector ==  @selector(printString))                 return [NSMethodSignature signatureWithObjCTypes:"@@:"];
  else if (selector ==  @selector(superclass))                  return [NSMethodSignature signatureWithObjCTypes:"#@:"];
  else return nil;
}

+ (NSUInteger) _ul_count  
{
  return 1;
}

+ _ul_objectAtIndex:(NSUInteger)index 
{ 
  return self;
}


///////////////////////// USER METHODS /////////////////////

+ (id)classOrMetaclass
{
  return objc_getMetaClass(object_getClassName(self));
}

+ (FSBoolean *)operator_equal_equal:(id)operand
{
  return (self == operand ? (id)[FSBoolean fsTrue] : (id)[FSBoolean fsFalse]);
}

+ (FSBoolean *)operator_tilde_tilde:(id)operand
{
  return (self == operand ? (id)[FSBoolean fsFalse] : (id)[FSBoolean fsTrue]);
} 

- (id)classOrMetaclass
{
  return [self class];
}

+ (NSString *)printString
{
  if ([self classOrMetaclass] == [NSProxy classOrMetaclass] && self != (id)[NSProxy class]) 
    return [[self description] stringByAppendingString:@" (meta)"];
  else
    return [self description];
}

@end
