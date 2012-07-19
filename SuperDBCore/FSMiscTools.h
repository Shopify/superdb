/* FSMiscTools.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <limits.h>
#import  <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
# include "ffi.h"
#else
# include <ffi/ffi.h>
#endif

@class FSArray;
@class FSInterpreter;
@class NSWindow;
@class FSSystem;

Class *allClasses(NSUInteger *count);

FSArray *allClassNames(void);

BOOL containsString(NSString *s, NSString *t, NSUInteger mask);

NSString *descriptionForFSMessage(id object);

ffi_type *ffiTypeFromFSEncodedType(char fsEncodedType);

enum e_FSObjCTypeCode {fscode_CGAffineTransform = '9',
                       fscode_NSRect = 'w', fscode_NSSize = 'x', fscode_NSPoint = 'y', fscode_NSRange = 'z',
                       fscode_CGRect = 'W', fscode_CGSize = 'X', fscode_CGPoint = 'Y'};

char FSEncode(const char *foundationEncodeStyleStr);

NSString *FSErrorMessageFromException(id exception);

BOOL FSIsIgnoredSelector(SEL selector);

void FSInspectBlocksInCallStackForException(id exception);

void inspect(id object, FSInterpreter *interpreter, id argument);

void inspectCollection(id collection, FSSystem *system, NSArray *blocks);

void inspectBlocksInCallStack(NSArray *callStack);

// Test if an object is descendant of the NSDistantObject class 
BOOL isKindOfClassNSDistantObject(id object);

// Test if an object is descendant of the NSProtocolChecker class
BOOL isKindOfClassNSProtocolChecker(id object);

// Test if an object is descendant of the NSProxy class. 
// In some cases, using the method "isProxy" is not precise enough since other objects hierarchies
// (based on another root class) may return YES when sent "isProxy" (as explained in the NSObject doc).
BOOL isKindOfClassNSProxy(id object); 

BOOL isNSNumberWithLosslessConversionToDouble(id anObject);

void printIntegerTypeInfo(void);

NSString *printString(id object);
NSString *printStringLimited(id object, NSUInteger limit); 

CGFloat systemFontSize(void);
CGFloat userFixedPitchFontSize(void);