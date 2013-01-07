/* FSMiscTools.h Copyright (c) 1998-2009 Philippe Mougin.     */
/* This software is open source. See the license.           */  

#import "FSMiscTools.h"
#import "FSNSObject.h"
#import "FSNSObjectPrivate.h"
#import "BlockStackElem.h"
#import "FSBlock.h"
#import "BlockPrivate.h"
#import "FSArray.h"
#import "build_config.h"
#import <objc/objc.h>
#import <Foundation/Foundation.h>
#import "FSInterpreter.h"
//#import "FScript.h"
#import "FSNSArrayPrivate.h"
#import "FSSystemPrivate.h"
#import "FScriptFunctions.h"
#include <unistd.h>
#include <stdio.h>
#include <limits.h>
#if TARGET_OS_IPHONE
# import <objc/runtime.h>
#else
# import <objc/objc-runtime.h>
#endif

#if TARGET_OS_IPHONE
# import <UIKit/UIFont.h>
#else
# import <AppKit/NSFont.h>
# import "FSGenericObjectInspector.h"
# import "FSCollectionInspector.h"
#endif

// ignoring these warnings until it can be fixed, for build servers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-w"

@class _NSZombie, NSFault, NSRTFD;

static ffi_type ffi_type_NSRange, ffi_type_NSPoint, ffi_type_NSRect, ffi_type_NSSize, ffi_type_CGAffineTransform;

void __attribute__ ((constructor)) initializeFFITypes(void)
{
  // See http://www.opensource.apple.com/darwinsource/Current/libffi-10/README

  //////////////////////////// Define ffi_type_NSRange
  ffi_type_NSRange.size = 0;                    
  ffi_type_NSRange.alignment = 0;
  ffi_type_NSRange.type = FFI_TYPE_STRUCT;
  ffi_type_NSRange.elements = malloc(3 * sizeof(ffi_type *));
#ifdef __LP64__
  ffi_type_NSRange.elements[0] = &ffi_type_uint64;
  ffi_type_NSRange.elements[1] = &ffi_type_uint64;
#else
  ffi_type_NSRange.elements[0] = &ffi_type_uint;
  ffi_type_NSRange.elements[1] = &ffi_type_uint;
#endif
  ffi_type_NSRange.elements[2] = NULL;
  
  //////////////////////////// Define ffi_type_NSPoint
  ffi_type_NSPoint.size = 0;                    
  ffi_type_NSPoint.alignment = 0;
  ffi_type_NSPoint.type = FFI_TYPE_STRUCT;
  ffi_type_NSPoint.elements = malloc(3 * sizeof(ffi_type*));
#ifdef __LP64__
  ffi_type_NSPoint.elements[0] = &ffi_type_double;
  ffi_type_NSPoint.elements[1] = &ffi_type_double;
#else
  ffi_type_NSPoint.elements[0] = &ffi_type_float;
  ffi_type_NSPoint.elements[1] = &ffi_type_float;
#endif
  ffi_type_NSPoint.elements[2] = NULL;
  
  //////////////////////////// Define ffi_type_NSSize
  ffi_type_NSSize.size = 0;                     
  ffi_type_NSSize.alignment = 0;
  ffi_type_NSSize.type = FFI_TYPE_STRUCT;
  ffi_type_NSSize.elements = malloc(3 * sizeof(ffi_type*));
#ifdef __LP64__
  ffi_type_NSSize.elements[0] = &ffi_type_double;
  ffi_type_NSSize.elements[1] = &ffi_type_double;
#else
  ffi_type_NSSize.elements[0] = &ffi_type_float;
  ffi_type_NSSize.elements[1] = &ffi_type_float;
#endif
  ffi_type_NSSize.elements[2] = NULL;  
  
  //////////////////////////// Define ffi_type_NSRect
  ffi_type_NSRect.size = 0;                    
  ffi_type_NSRect.alignment = 0;
  ffi_type_NSRect.type = FFI_TYPE_STRUCT;
  ffi_type_NSRect.elements = malloc(3 * sizeof(ffi_type*));
  ffi_type_NSRect.elements[0] = &ffi_type_NSPoint;
  ffi_type_NSRect.elements[1] = &ffi_type_NSSize;
  ffi_type_NSRect.elements[2] = NULL;
  
  //////////////////////////// Define ffi_type_CGAffineTransform
  ffi_type_CGAffineTransform.size = 0;                    
  ffi_type_CGAffineTransform.alignment = 0;
  ffi_type_CGAffineTransform.type = FFI_TYPE_STRUCT;
  ffi_type_CGAffineTransform.elements = malloc(7 * sizeof(ffi_type*));
#ifdef __LP64__
  ffi_type_CGAffineTransform.elements[0] = &ffi_type_double;
  ffi_type_CGAffineTransform.elements[1] = &ffi_type_double;
  ffi_type_CGAffineTransform.elements[2] = &ffi_type_double;
  ffi_type_CGAffineTransform.elements[3] = &ffi_type_double;
  ffi_type_CGAffineTransform.elements[4] = &ffi_type_double;
  ffi_type_CGAffineTransform.elements[5] = &ffi_type_double;
#else
  ffi_type_CGAffineTransform.elements[0] = &ffi_type_float;
  ffi_type_CGAffineTransform.elements[1] = &ffi_type_float;
  ffi_type_CGAffineTransform.elements[2] = &ffi_type_float;
  ffi_type_CGAffineTransform.elements[3] = &ffi_type_float;
  ffi_type_CGAffineTransform.elements[4] = &ffi_type_float;
  ffi_type_CGAffineTransform.elements[5] = &ffi_type_float;
#endif
  ffi_type_CGAffineTransform.elements[6] = NULL;
}

Class *allClasses(NSUInteger *count)
{
  Class *result;
  NSInteger i, numClasses = 0, newNumClasses = objc_getClassList(NULL, 0);
  Class *classes = NULL;
//  unsigned int exceptionHandlingMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
  Class _NSZombieClass = NSClassFromString(@"_NSZombie"); 
  Class NSFaultClass   = NSClassFromString(@"NSFault");
  Class ProtocolClass  = NSClassFromString(@"Protocol");
  Class ListClass      = NSClassFromString(@"List");
  Class ObjectClass    = NSClassFromString(@"Object");
  Class NSURL__Class   = NSClassFromString(@"NSURL__");   // Workaround for a strange bug (crash) which happens when using completion in an FSInterpreterView from the FScriptPalette in IB test mode

  while (numClasses < newNumClasses) 
  {
    numClasses = newNumClasses;
    classes = realloc(classes, sizeof(Class) * numClasses);
    newNumClasses = objc_getClassList(classes, numClasses);
    //NSLog([NSString stringWithFormat:@"%d", newNumClasses]);
  }
  // now, can use the classes list; if NULL, there are no classes
  
  result = malloc(numClasses * sizeof(Class));
  *count = 0;

//  [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:63];
  
  for (i = 0; i < numClasses; i++)
  {
//    NS_DURING
      if (classes[i] != ObjectClass && classes[i] != ListClass && classes[i] != ProtocolClass && classes[i] != _NSZombieClass && classes[i] != NSFaultClass && classes[i] != NSURL__Class)
      {
        result[*count] = classes[i];
        (*count)++; 
      }
    
      //else NSLog(NSStringFromClass(classes[i]));
//    NS_HANDLER
//       NSLog(@"F-Script: problem while computing class list. The following exception was encountered: %@ %@", [localException name], [localException reason]);
//       NSLog(NSStringFromClass(classes[i]));
//    NS_ENDHANDLER
  }

//  Restore the original exception handling mask   
//  [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:exceptionHandlingMask];  
  
  free(classes);
  return result;
}

FSArray *allClassNames()
{
  NSUInteger count;
  Class *classes = allClasses(&count);
  FSArray *result = [FSArray arrayWithCapacity:count];
  
  for (NSUInteger i = 0; i < count; i++)
  {  
    [result addObject:NSStringFromClass(classes[i])];    
  }
  
  free(classes);
  return result;  
}


NSArray *classNames() {
	NSUInteger count;
	Class *classes = allClasses(&count);
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	
	for (NSUInteger i = 0; i < count; i++)
	{
		[result addObject:NSStringFromClass(classes[i])];
	}
	
	free(classes);
	[result sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
	}];
	return [NSArray arrayWithArray:result];
}

BOOL containsString(NSString *s, NSString *t, NSUInteger mask)
{
  NSRange range = [s rangeOfString:t options:mask];
  return (range.location != NSNotFound || range.length != 0);
}

NSString *descriptionForFSMessage(id object)
{
  if (object == nil) 
    return @"nil"; 
  else if ((id)[object class]==object) // || object == (id)[NSObject classOrMetaclass])
  { 
    return [NSString stringWithFormat:@"the class object %@", [object printString]]; 
  }
  else
    return [NSString stringWithFormat:@"an instance of %@",NSStringFromClass([object class])];
}

ffi_type *ffiTypeFromFSEncodedType(char fsEncodedType)
{
  switch (fsEncodedType)
  {
    case '#'                      : 
    case '@'                      : 
    case ':'                      : 
    case '^'                      : return &ffi_type_pointer;
    case 'v'                      : return &ffi_type_void;
    case 'c'                      : return &ffi_type_schar;
    case 'C'                      : return &ffi_type_uchar;
    case 's'                      : return &ffi_type_sshort;
    case 'S'                      : return &ffi_type_ushort;
    case 'i'                      : return &ffi_type_sint;
    case 'I'                      : return &ffi_type_uint;
    case 'l'                      : return sizeof(long)          == sizeof(int)          ? &ffi_type_sint : &ffi_type_slong; // Work around the incorect definition of ffi_type_slong in libffi (Mac OS X 10.5.4) 
    case 'L'                      : return sizeof(unsigned long) == sizeof(unsigned int) ? &ffi_type_uint : &ffi_type_ulong; // Work around the incorect definition of ffi_type_ulong in libffi (Mac OS X 10.5.4)
    case 'q'                      : return &ffi_type_uint64;
    case 'Q'                      : return &ffi_type_sint64;
    case 'f'                      : return &ffi_type_float;
    case 'd'                      : return &ffi_type_double;
    case fscode_NSRange           : return &ffi_type_NSRange;   
    case fscode_NSPoint: 
    case fscode_CGPoint           : return &ffi_type_NSPoint;
    case fscode_NSRect            :  
    case fscode_CGRect            : return &ffi_type_NSRect; 
    case fscode_NSSize            : 
    case fscode_CGSize            : return &ffi_type_NSSize; 
    case fscode_CGAffineTransform : return &ffi_type_CGAffineTransform;
    case 'B'           : // No ffi_type defined yet for _Bool (Mac OS X 10.5.4), so we handle it ourselves
      if      (sizeof(_Bool) == 4) return &ffi_type_uint32; 
      else if (sizeof(_Bool) == 1) return &ffi_type_uint8;
      else FSExecError(@"F-Script internal error: _Bool type nor supported on this architecture");
  }
  
  assert(0);
  return NULL;
}

char FSEncode(const char *foundationEncodeStyleStr)
{
  // NSLog(@"FSEncode called with \"%s\"", foundationEncodeStyleStr);
  
  const char *ptr = foundationEncodeStyleStr;

  while (*ptr == 'r' || *ptr == 'n' || *ptr == 'N' || *ptr == 'o' || *ptr == 'O' || *ptr == 'R' || *ptr == 'V')
    ptr++;
  
  if (*ptr == '{') 
  {
    // NSLog([NSString stringWithFormat:@"ptr = %s",ptr]);
           
    // The objc run-time function ivar_getTypeEncoding() does not return the same encoding string as the @encode directive (tested on OSX 10.5.1)
    // This is why we have the additional strncmp calls below         
                              
    if       (strcmp(ptr,@encode(NSRange))            == 0 || strncmp(ptr,"{_NSRange="         , 10) == 0) return fscode_NSRange;
#if !TARGET_OS_IPHONE
    else if  (strcmp(ptr,@encode(NSPoint))            == 0 || strncmp(ptr,"{_NSPoint="         , 10) == 0) return fscode_NSPoint;
    else if  (strcmp(ptr,@encode(NSSize))             == 0 || strncmp(ptr,"{_NSSize="          ,  9) == 0) return fscode_NSSize;
    else if  (strcmp(ptr,@encode(NSRect))             == 0 || strncmp(ptr,"{_NSRect="          ,  9) == 0) return fscode_NSRect;
#endif
    else if  (strcmp(ptr,@encode(CGPoint))            == 0 || strncmp(ptr,"{CGPoint="          ,  9) == 0) return fscode_CGPoint;
    else if  (strcmp(ptr,@encode(CGSize))             == 0 || strncmp(ptr,"{CGSize="           ,  8) == 0) return fscode_CGSize;
    else if  (strcmp(ptr,@encode(CGRect))             == 0 || strncmp(ptr,"{CGRect="           ,  8) == 0) return fscode_CGRect;
    else if  (strcmp(ptr,@encode(CGAffineTransform))  == 0 || strncmp(ptr,"{CGAffineTransform=", 19) == 0) return fscode_CGAffineTransform;    
  }
   
  return *ptr;
}

NSString *FSErrorMessageFromException(id exception)
{  
  if ([exception isKindOfClass:[NSException class]])
  {
    if ([exception name] == FSExecutionErrorException) return [exception reason];
    else
    {
      NSString *name   = [exception name];
      NSString *reason = [exception reason];
      BOOL nameMissing   = name   == nil || [name   length] == 0;
      BOOL reasonMissing = reason == nil || [reason length] == 0;
      
      if (nameMissing && reasonMissing) return @"An exception was thrown (this exception has no name or reason associated with it)";
      else if (nameMissing)             return [NSString stringWithFormat:@"%@", reason];
      else if (reasonMissing)           return [NSString stringWithFormat:@"%@", name];   
      else                              return [NSString stringWithFormat:@"%@: %@", name, reason];  
    }
  }
  else return [NSString stringWithFormat:@"exception thrown: %@", printString(exception)];
}

BOOL FSIsIgnoredSelector(SEL selector)
{
  // Under GC, selectors for retain, release, autorelease, retainCount and dealloc are all represented by the same special non-functional "ignored" selector     
  return (selector == @selector(retain) && selector == @selector(release));
}

void inspect(id object, FSInterpreter *interpreter, id argument)
{
#if !TARGET_OS_IPHONE
  BOOL error = NO;
  
  if (object == nil)
    NSBeep();
  else
  {
    @try  // An exception may occur if the object is invalid (e.g. an invalid proxy)
    {
        [object respondsToSelector:@selector(inspect)];
    }
    @catch (id exception)
    {
      error= YES;
      [FSGenericObjectInspector genericObjectInspectorWithObject:object];
    }

    if (!error)
    {  
      if ([object respondsToSelector:@selector(inspectWithSystem:)])
        [object inspectWithSystem:[interpreter objectForIdentifier:@"sys" found:NULL]];
      else if ([object respondsToSelector:@selector(inspect)])
        [object inspect];
      else [FSGenericObjectInspector genericObjectInspectorWithObject:object];
    }  
  }    
#endif
}

void inspectCollection(id collection, FSSystem *system, NSArray *blocks)  // Factorize some code that would be duplicated in each collection class otherwise
{
  FSVerifClassArgs(@"inspectWithSystem:blocks:",2,system,[FSSystem class],(NSInteger)1,blocks,[NSArray class],(NSInteger)1);
  
  NSUInteger i, count;
  
  if (system && ![system interpreter])
    FSExecError(@"Sorry, can't open the inspector because there is no FSInterpreter associated with the FSSystem object passed as argument");
                        
  if (blocks)
    for (i=0, count=[blocks count]; i < count; i++)
    {
      if (![[blocks objectAtIndex:i] isKindOfClass:[FSBlock class]])
        FSExecError(@"argument 2 of method \"inspectWithSystem:blocks:\" must be an array of blocks");
      if ([[blocks objectAtIndex:i] argumentCount] > 1)
        FSExecError(@"argument 2 of method \"inspectWithSystem:blocks:\" must be an array of blocks taking no more than one argument");
    }
#if !TARGET_OS_IPHONE
  [FSCollectionInspector collectionInspectorWithCollection:collection interpreter:(system ? [system interpreter] : [FSInterpreter interpreter]) blocks:blocks];
#endif
}

void FSInspectBlocksInCallStackForException(id exception)
{
  if ([exception isKindOfClass:[NSException class]])
  {
    id blockStack;
    NSDictionary *userInfo = [[[exception userInfo] retain] autorelease]; // to be sure it stay alive during the rest of the current method    

    if (userInfo && (blockStack = [userInfo objectForKey:@"FScriptBlockStack"]) )
      inspectBlocksInCallStack(blockStack);
  }
}      

void inspectBlocksInCallStack(NSArray *callStack)
{
// We show the block call stack using the inpectors of the blocks. 
// Since a block can have only one inspector opened on it, we do this stuff below with
// distincBlocks etc. But there is obviously still a problem : the stack that will be
// displayed to the user will not be "complete" in the situation where a block is present 
// multiples times in the stack. 

  BlockStackElem *blockStackElem;
  NSInteger i, openedInspectors;
  NSMutableSet *distinctBlocks = [[NSMutableSet alloc] init];

  for (i = [callStack count]-1, openedInspectors = 0; i >= 0 && openedInspectors < 40; i--)
  {
    blockStackElem = [callStack objectAtIndex:i];
    
    if (![distinctBlocks containsObject:[blockStackElem block]])
    {
      [distinctBlocks addObject:[blockStackElem block]];
      //[[blockStackElem block] inspect];
      openedInspectors++;
      if ([blockStackElem lastCharIndex] == -1)
        [[blockStackElem block] showError:[blockStackElem errorStr]];
      else       
        [[blockStackElem block] showError:[blockStackElem errorStr] start:[blockStackElem firstCharIndex] end:[blockStackElem lastCharIndex]];
    }
  } 
  [distinctBlocks release];
}

#if !TARGET_OS_IPHONE
BOOL isKindOfClassNSDistantObject(id object) 
{
  Class cls = [object class];
  
  while (cls != [NSDistantObject class] && cls != nil && cls != [cls superclass]) cls = [cls superclass];
   // Note: Correct behavior for a root class is to return nil when asked for its superclass. 
   // However, NSProxy return itself instead. 
   // The test above take the two possibilities into account.
  
  return cls == [NSDistantObject class];
}

BOOL isKindOfClassNSProtocolChecker(id object)
{
  Class cls = [object class];

  while (cls != [NSProtocolChecker class] && cls != nil && cls != [cls superclass]) cls = [cls superclass];
  // Note: Correct behavior for a root class is to return nil when asked for its superclass.
  // However, NSProxy return itself instead.
  // The test above take the two possibilities into account.

  return cls == [NSProtocolChecker class];
}
#endif

BOOL isKindOfClassNSProxy(id object) 
{
  Class cls = [object class];
  
  while (cls != [NSProxy class] && cls != nil && cls != [cls superclass]) cls = [cls superclass];
  // Note: Correct behavior for a root class is to return nil when asked for its superclass. 
  // However, it seems that some root classes return themselves instead. 
  // The test above take the two possibilities into account.
   
  return cls == [NSProxy class];
}

BOOL isNSNumberWithLosslessConversionToDouble(id anObject)
{
  if ([anObject isKindOfClass:[NSNumber class]] && ![anObject isKindOfClass:[NSDecimalNumber class]])
  {
    char type = [anObject objCType][0];
    if (type != 'q' && type != 'Q') return YES;
  }  
  return NO;
} 

NSString *printString(id object)
{
  return printStringLimited(object, NSUIntegerMax); 
}

NSString *printStringLimited(id object, NSUInteger limit) // Hack. A better scheme for limiting string size will be implemented.
{
  NSString *result;
  
  if (object == nil) result = @"nil";
  else  
  {
    @try
    {
      /* We can have multiples problems leading to an exception being raised.
      First, result itself may not be able to be used anymore (for instance if it is an invalid NSDistantObject). 
      Another problem would be an exception raised by the "descriptionLimited" or "printString" methods.*/ 

      if ([object isKindOfClass:[NSArray class]] && [object respondsToSelector:@selector(descriptionLimited:)]) 
        result = [object descriptionLimited:limit]; // a proxy to a remote NSArray may not responds to descriptionLimited:.
      else
      {  
        if ([object respondsToSelector:@selector(printString)]) 
          result = [object printString];
        else
        {
          result = [object description];
          if (result == nil) // Some Cocoa classes return nil when asked for their descriptions! 
            result = @"";    
        }
      }
      
      if ([result hasPrefix:@"{\n"]) 
        result = [@"{" stringByAppendingString:[result substringFromIndex:2]]; 
    }
    @catch (id exception)
    {
      result = [NSString stringWithFormat:@"*** Non printable object. Exception thrown when trying to get a textual representation of the object: %@", FSErrorMessageFromException(exception)];                          
    }
  }
  return result;
}
 
CGFloat systemFontSize(void)
{
  //[[NSUserDefaults standardUserDefaults] floatForKey:@"FScriptFontSize"] + ([NSFont systemFontSize] - [[NSFont userFixedPitchFontOfSize:-1] pointSize]);
#if TARGET_OS_IPHONE
  return MAX([UIFont systemFontSize]-1, [[NSUserDefaults standardUserDefaults] floatForKey:@"FScriptFontSize"]);
#else
  return MAX([NSFont systemFontSize]-1, [[NSUserDefaults standardUserDefaults] floatForKey:@"FScriptFontSize"]);
#endif
}

CGFloat userFixedPitchFontSize(void)
{
  //return [[NSUserDefaults standardUserDefaults] floatForKey:@"FScriptFontSize"];
  //return [[NSFont userFixedPitchFontOfSize:-1.0] pointSize];
  return systemFontSize();
}

volatile int char_min = CHAR_MIN;

void printIntegerTypeInfo(void)
{
    printf("Size of Boolean type is %d byte(s)\n\n",
        (int)sizeof(_Bool));

    printf("Number of bits in a character: %d\n",
        CHAR_BIT);
    printf("Size of character types is %d byte\n",
        (int)sizeof(char));
    printf("Signed char min: %d max: %d\n",
        SCHAR_MIN, SCHAR_MAX);
    printf("Unsigned char min: 0 max: %u\n",
        (unsigned int)UCHAR_MAX);

    printf("Default char is ");
    if (char_min < 0)
        printf("signed\n\n");
    else if (char_min == 0)
        printf("unsigned\n\n");
    else
        printf("non-standard\n\n");

    printf("Size of short int types is %d bytes\n",
        (int)sizeof(short));
    printf("Signed short min: %d max: %d\n",
        SHRT_MIN, SHRT_MAX);
    printf("Unsigned short min: 0 max: %u\n\n",
        (unsigned int)USHRT_MAX);

    printf("Size of int types is %d bytes\n",
        (int)sizeof(int));
    printf("Signed int min: %d max: %d\n",
        INT_MIN, INT_MAX);
    printf("Unsigned int min: 0 max: %u\n\n",
        (unsigned int)UINT_MAX);

    printf("Size of long int types is %d bytes\n",
        (int)sizeof(long));
    printf("Signed long min: %ld max: %ld\n",
        LONG_MIN, LONG_MAX);
    printf("Unsigned long min: 0 max: %lu\n\n",
        ULONG_MAX);

    printf("Size of long long types is %d bytes\n",
        (int)sizeof(long long));
    printf("Signed long long min: %lld max: %lld\n",
        LLONG_MIN, LLONG_MAX);
    printf("Unsigned long long min: 0 max: %llu\n",
        ULLONG_MAX);
}

#pragma clang diagnostic pop