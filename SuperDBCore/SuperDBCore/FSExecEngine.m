/*   FSExecEngine.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "FSExecEngine.h"
#import "FScriptFunctions.h"
#import "FSArray.h"
#import "ArrayPrivate.h"
#import <Foundation/Foundation.h>
//#import <objc/Protocol.h>  //objc_method_description
#import "FSBooleanPrivate.h"
#import "FSBlock.h"
#import "FSVoid.h"
#import "FSPattern.h"
#if TARGET_OS_IPHONE
# import <objc/runtime.h>
# import <objc/message.h>
#else
# import <objc/objc-runtime.h>
#endif
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FSCompiler.h"
#import "MessagePatternCodeNode.h"
#import "FSCNClassDefinition.h"
#import "BlockPrivate.h"
#import "BlockRep.h"
#import <limits.h>
#import "FSMiscTools.h"
#import "FSVoidPrivate.h"
#import "BlockStackElem.h"
#import "PointerPrivate.h"
#import <CoreData/CoreData.h> 
#import "FSGenericPointer.h"
#import "FSGenericPointerPrivate.h"
#import "FSObjectPointer.h"
#import "FSObjectPointerPrivate.h"
#import "FSReturnSignal.h"
#import "FSBooleanPrivate.h"
#import "FSMethod.h"
#import "FSCNIdentifier.h"
#import "FSCNKeywordMessage.h"
#import "FSCNBinaryMessage.h"
#import "FSCNUnaryMessage.h"
#import "FSCNCascade.h"
#import "FSCNStatementList.h"
#import "FSCNPrecomputedObject.h"
#import "FSCNArray.h"
#import "FSCNBlock.h"
#import "FSCNAssignment.h"
#import "FSCNCategory.h"
#import "FSCNSuper.h"
#import "FSCNReturn.h"
#import "FSCNMethod.h"
#import "FSCNDictionary.h"
#import "FSGlobalScope.h"
#import "FSAssociation.h"

#if !TARGET_OS_IPHONE
# import "FScriptTextView.h"
#endif

// ignoring these warnings until it can be fixed, for build servers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-w"
#ifndef __clang_analyzer__

static NSMutableSet *issuedWarnings;

void __attribute__ ((constructor)) initializeFSExecEngine(void) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"YES" forKey:@"MaintainFScript1EqualityOperatorsSemantics"]];
  issuedWarnings = [[NSMutableSet alloc] init];  
  
  [pool release];
}


@interface FSNSObject

- (NSUInteger) _ul_count;
- _ul_objectAtIndex:(NSUInteger)index;

@end

#define MAP_ARG(TYPE,MIN,MAX,CLASS,CLASS_STR) \
{ \
  if (![object isKindOfClass:CLASS]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of %@ was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object), CLASS_STR]); \
  double d = [object doubleValue]; \
  if (d < MIN  || d > MAX) FSExecError([NSString stringWithFormat:@"%@ has a value of %g. Expected value must be in the range [%.15g, %.15g].", description(mapType, argumentNumber, selector, ivarName), d, (double)MIN,(double)MAX]); \
  ((TYPE *)valuePtr)[index] = d; \
}

#define MAP_RET(TYPE) {TYPE r; [invocation getReturnValue:&r]; return [Number numberWithDouble:r];}

static NSString *description(enum FSMapType mapType, NSUInteger argumentNumber, SEL selector, NSString *ivarName)
{
  switch (mapType) 
  {
    case FSMapArgument:
    case FSMapDereferencedPointer:
      return ([NSString stringWithFormat:@"argument %lu of method %@", (unsigned long)argumentNumber, [FSCompiler stringFromSelector:selector]]);
      
    case FSMapReturnValue:
      return ([NSString stringWithFormat:@"return value of method %@", [FSCompiler stringFromSelector:selector]]);  
      
    case FSMapIVar:
      return ([NSString stringWithFormat:@"object representing value to be assigned to instance variable %@", ivarName]);  
  }
  NSCAssert(0, @"We should never reach this code!");
  return nil; // to avoid a warning
}

#if !TARGET_OS_IPHONE
static NSAffineTransform *FSNSAffineTransformFromCGAffineTransform(CGAffineTransform cgat)
{
  NSAffineTransformStruct matrix = {cgat.a, cgat.b, cgat.c, cgat.d, cgat.tx, cgat.ty};
  NSAffineTransform *result = [NSAffineTransform transform];
  [result setTransformStruct:matrix];
  return result;
}

static CGAffineTransform FSCGAffineTransformFromNSAffineTransform(NSAffineTransform *nsat)
{
  NSAffineTransformStruct matrix = [nsat transformStruct];
  CGAffineTransform result = {matrix.m11, matrix.m12, matrix.m21, matrix.m22, matrix.tX, matrix.tY};
  return result;
}
#endif

id FSMapToObject(void *valuePtr, NSUInteger index, char fsEncodedType, const char *foundationStyleEncodedType, NSString *unsuportedTypeErrorMessage, NSString *ivarName)
{
    switch (fsEncodedType)
    {
      case '@':
      case '#': return ((id *)valuePtr)[index];
      case 'c': if ( ((char *)valuePtr)[index] )  return fsTrue; else return fsFalse;       
      case 'B': if ( ((_Bool *)valuePtr)[index] ) return fsTrue; else return fsFalse; 
      case 'i': return [FSNumber numberWithDouble:((int *)valuePtr)[index]];       
      case 's': return [FSNumber numberWithDouble:((short *)valuePtr)[index]];   
      case 'l': return [NSNumber numberWithLong:((long *)valuePtr)[index]]; 
      case 'C': return [FSNumber numberWithDouble:((unsigned char *)valuePtr)[index]];
      case 'I': return [FSNumber numberWithDouble:((unsigned int *)valuePtr)[index]];
      case 'S': return [FSNumber numberWithDouble:((unsigned short *)valuePtr)[index]]; 
      case 'L': return [NSNumber numberWithUnsignedLong:((unsigned long *)valuePtr)[index]];
      case 'f': return [FSNumber numberWithDouble:((float *)valuePtr)[index]];
      case 'd': return [FSNumber numberWithDouble:((double *)valuePtr)[index]];
      case 'q': return [NSNumber numberWithLongLong:((long long *)valuePtr)[index]]; 
      case 'Q': return [NSNumber numberWithUnsignedLongLong:((unsigned long long *)valuePtr)[index]];       
      case ':': return [FSBlock blockWithSelector:((SEL *)valuePtr)[index]];
      case fscode_NSRange: return [NSValue valueWithRange:((NSRange *)valuePtr)[index]];
#if TARGET_OS_IPHONE
      case fscode_CGPoint: return [NSValue valueWithCGPoint:((CGPoint *)valuePtr)[index]];
      case fscode_CGSize:  return [NSValue valueWithCGSize:((CGSize *)valuePtr)[index]];
      case fscode_CGRect:  return [NSValue valueWithCGRect:((CGRect *)valuePtr)[index]];
#else
      case fscode_NSPoint:
      case fscode_CGPoint: return [NSValue valueWithPoint:((NSPoint *)valuePtr)[index]];
      case fscode_NSSize:
      case fscode_CGSize:  return [NSValue valueWithSize:((NSSize *)valuePtr)[index]];
      case fscode_NSRect:
      case fscode_CGRect:  return [NSValue valueWithRect:((NSRect *)valuePtr)[index]];
      case fscode_CGAffineTransform: return FSNSAffineTransformFromCGAffineTransform(((CGAffineTransform *)valuePtr)[index]);
#endif
      case '*':
      case '^': 
        if ( ((void **)valuePtr)[index] == NULL ) return nil;
        else 
        {
          while (*foundationStyleEncodedType == 'r' || *foundationStyleEncodedType == 'n' || *foundationStyleEncodedType == 'N' || *foundationStyleEncodedType == 'o' || *foundationStyleEncodedType == 'O' || *foundationStyleEncodedType == 'R' || *foundationStyleEncodedType == 'V')
            foundationStyleEncodedType++;
            
          if (*foundationStyleEncodedType == '*') return [[[FSGenericPointer alloc] initWithCPointer:((void **)valuePtr)[index] freeWhenDone:NO type:"c"] autorelease];
          else                                    return [[[FSGenericPointer alloc] initWithCPointer:((void **)valuePtr)[index] freeWhenDone:NO type:foundationStyleEncodedType+1] autorelease];  // +1 because we don't want the ^ character, which is the first character (after the type qualifiers like 'r', 'n' etc.) in the encoded type for a pointer
        }
      default: if (ivarName) FSExecError([NSString stringWithFormat:@"the type of instance variable %@ is not supported", ivarName]); 
               else          FSExecError(unsuportedTypeErrorMessage);          
    }
 }   


void FSMapFromObject(void *valuePtr, NSUInteger index, char fsEncodedType, id object, enum FSMapType mapType, NSUInteger argumentNumber, SEL selector, NSString *ivarName, FSObjectPointer **mappedFSObjectPointerPtr)
{
  switch (fsEncodedType)
  {
  case '@':
    ((id *)valuePtr)[index] = object;
    break;
  
  case '#':  
    if   ([object class] == object) ((Class *)valuePtr)[index] = object;
    else                            FSExecError([NSString stringWithFormat:@"%@ is %@. A class was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    break;
        
  case 'c':
    if      (object == fsTrue)                         ((char *)valuePtr)[index] = YES; 
    else if (object == fsFalse)                        ((char *)valuePtr)[index] = NO;
    else if ([object isKindOfClass:[FSBoolean class]]) ((char *)valuePtr)[index] = [object isTrue];
    else                                               MAP_ARG(char, CHAR_MIN, CHAR_MAX, NSNumberClass, @"NSNumber or FSBoolean");
    break;   
         
  case 'B':
    if      (object == fsTrue)                         ((_Bool *)valuePtr)[index] = 1; 
    else if (object == fsFalse)                        ((_Bool *)valuePtr)[index] = 0;
    else if ([object isKindOfClass:[FSBoolean class]]) ((_Bool *)valuePtr)[index] = ([object isTrue] ? 1 : 0);
    else                                               FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of FSBoolean was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    break;
    
  case 'S': 
    if ([object isKindOfClass:[NSString class]]) 
    {
      if ([(NSString *)object length] == 1) ((unsigned short *)valuePtr)[index] = [object characterAtIndex:0];
      else                                  FSExecError([NSString stringWithFormat:@"%@ is %@. A one character NSString or an instance of NSNumber was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);                                  
    }
    else MAP_ARG(unsigned short, 0, USHRT_MAX, NSNumberClass, @"NSNumber or a one character NSString");
    break;
    
  case 'i':  MAP_ARG(int,           INT_MIN,  INT_MAX,   NSNumberClass, @"NSNumber"); break;
  case 's':  MAP_ARG(short,         SHRT_MIN, SHRT_MAX,  NSNumberClass, @"NSNumber"); break;
  case 'l':  MAP_ARG(long,          LONG_MIN, LONG_MAX,  NSNumberClass, @"NSNumber"); break;
  case 'C':  MAP_ARG(unsigned char, 0,        UCHAR_MAX, NSNumberClass, @"NSNumber"); break;
  case 'I':  MAP_ARG(unsigned int,  0,        UINT_MAX,  NSNumberClass, @"NSNumber"); break;
  case 'L':  MAP_ARG(unsigned long, 0,        ULONG_MAX, NSNumberClass, @"NSNumber"); break;
  case 'f':  MAP_ARG(float,         -FLT_MAX, FLT_MAX,   NSNumberClass, @"NSNumber"); break;
  
  case 'd':
    // no need to test if the number is in a valid range (it's allways the case) so we don't use MAP_ARG
    if (![object isKindOfClass:NSNumberClass]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSNumber was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    ((double *)valuePtr)[index] = [object doubleValue];
    break;
  
  case 'q':
  {
    if (![object isKindOfClass:NSNumberClass]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSNumber was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    
    char objCType = [object objCType][0];
    
    if (objCType == 'Q' && [object unsignedLongLongValue] > LLONG_MAX)
      FSExecError([NSString stringWithFormat:@"%@ has a value of %llu. Expected value must be in the range [%lld, %lld].", description(mapType, argumentNumber, selector, ivarName), [object unsignedLongLongValue], LLONG_MIN, LLONG_MAX]);   
    else if (objCType == 'q' || objCType == 'Q')
    {
      ((long long *)valuePtr)[index] = [object longLongValue];
    }
    else
    {
      double d = [object doubleValue]; 
      if (d <= LLONG_MIN  || d >= LLONG_MAX) // In order to avoid an edge case where LLONG_MAX (or LLONG_MIN) would be converted (by the compiler, for performing the comparison) to a bigger (in absolute value) double value that would happend to be equal to d (which would lead to an overflow on the (1) instruction ), we exclude LLONG_MAX and LLONG_MIN from the acceptable range.
        FSExecError([NSString stringWithFormat:@"%@, which has a value of %g, is too big (in absolute value)", description(mapType, argumentNumber, selector, ivarName), d]);     
      
      ((long long *)valuePtr)[index] = [object longLongValue]; // (1)
    }
    break;
  }
  
  case 'Q':
  { 
    if (![object isKindOfClass:NSNumberClass]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSNumber was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    
    char objCType = [object objCType][0];
    
    if (objCType == 'q' && [object longLongValue] < 0)
      FSExecError([NSString stringWithFormat:@"%@ has a value of %lld. Expected value must be in the range [0, %llu].", description(mapType, argumentNumber, selector, ivarName), [object longLongValue], ULLONG_MAX]);
    else if (objCType == 'q' || objCType == 'Q')
    {
      ((unsigned long long *)valuePtr)[index] = [object unsignedLongLongValue];
    }
    else
    {
      double d = [object doubleValue]; 
      if (d < 0)
        FSExecError([NSString stringWithFormat:@"%@ has a value of %g. Expected value must be in the range [0, %llu].", description(mapType, argumentNumber, selector, ivarName), d, ULLONG_MAX]);
      else if (d >= ULLONG_MAX) // In order to avoid an edge case where ULLONG_MAX would be converted (by the compiler, for performing the comparison) to a bigger  double value that would happend to be equal to d (which would lead to an overflow on the (2) instruction ), we exclude ULLONG_MAX from the acceptable range.
        FSExecError([NSString stringWithFormat:@"%@, which has a value of %g, is too big", description(mapType, argumentNumber, selector, ivarName), d]); 
      
      ((unsigned long long *)valuePtr)[index] = [object unsignedLongLongValue]; // (2)   
    }
    break;
  }
  
  case ':':
  {
    SEL s;
    
    if (![object isKindOfClass:[FSBlock class]]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of FSBlock was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    if (![object isCompact])                     FSExecError([NSString stringWithFormat:@"%@ must be a compact block", description(mapType, argumentNumber, selector, ivarName)]);
    
    if (!(s = [object selector])) s = [FSCompiler selectorFromString:[object selectorStr]];
    
    ((SEL *)valuePtr)[index] = s;

    break;
  }
  case fscode_NSRange:
  {    
    if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a NSRange was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    else if (strcmp([object objCType], @encode(NSRange)) != 0) FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a NSRange", description(mapType, argumentNumber, selector, ivarName)]);    
    else                                                       ((NSRange *)valuePtr)[index] = [object rangeValue];
    break;
  }
#if TARGET_OS_IPHONE
    case fscode_CGPoint:
    {
      if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a CGPoint was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
      else if (strcmp([object objCType], @encode(CGPoint)) != 0) FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a CGPoint", description(mapType, argumentNumber, selector, ivarName)]);    
      else                                                       ((CGPoint *)valuePtr)[index] = [object CGPointValue];
      break;
    }
    case fscode_CGSize:
    {
      if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a CGSize was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
      else if (strcmp([object objCType], @encode(CGSize)) != 0)  FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a CGSize", description(mapType, argumentNumber, selector, ivarName)]);    
      else                                                       ((CGSize *)valuePtr)[index] = [object CGSizeValue];
      break;
    }
    case fscode_CGRect:
    {
      if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a CGRect was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
      else if (strcmp([object objCType], @encode(CGRect)) != 0)  FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a CGRect", description(mapType, argumentNumber, selector, ivarName)]);    
      else                                                       ((CGRect *)valuePtr)[index] = [object CGRectValue];
      break;
    }
#else
  case fscode_NSPoint:
  case fscode_CGPoint:
  {
    if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a NSPoint was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    else if (strcmp([object objCType], @encode(NSPoint)) != 0) FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a NSPoint", description(mapType, argumentNumber, selector, ivarName)]);    
    else                                                       ((NSPoint *)valuePtr)[index] = [object pointValue];
    break;
  }
  case fscode_NSSize:
  case fscode_CGSize:
  {
    if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a NSSize was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    else if (strcmp([object objCType], @encode(NSSize)) != 0)  FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a NSSize", description(mapType, argumentNumber, selector, ivarName)]);    
    else                                                       ((NSSize *)valuePtr)[index] = [object sizeValue];
    break;
  }
  case fscode_NSRect:
  case fscode_CGRect:
  {
    if      (![object isKindOfClass:[NSValue class]])          FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSValue containing a NSRect was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    else if (strcmp([object objCType], @encode(NSRect)) != 0)  FSExecError([NSString stringWithFormat:@"%@ must be an NSValue containing a NSRect", description(mapType, argumentNumber, selector, ivarName)]);    
    else                                                       ((NSRect *)valuePtr)[index] = [object rectValue];
    break;
  }
    case fscode_CGAffineTransform:
    {
      if (![object isKindOfClass:[NSAffineTransform class]]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of NSAffineTransform was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
      else ((CGAffineTransform *)valuePtr)[index] = FSCGAffineTransformFromNSAffineTransform(object);
      break;
    }
#endif
  case '*':
  case '^':
    if (object == nil) ((void **)valuePtr)[index] = NULL; 
    else if (![object isKindOfClass:[FSPointer class]] && ![object isKindOfClass:[Pointer class]]) FSExecError([NSString stringWithFormat:@"%@ is %@. An instance of FSPointer was expected", description(mapType, argumentNumber, selector, ivarName), descriptionForFSMessage(object)]);
    else
    {
      if (mappedFSObjectPointerPtr != NULL && [object isKindOfClass:[FSObjectPointer class]])  *mappedFSObjectPointerPtr = object;
      ((void **)valuePtr)[index] = [object cPointer];
    }    
    break;
  
//   void *a;
//    if (args[i] == nil) 
//      a = NULL;
//    else if ([args[i] isKindOfClass:[Pointer class]])
//    { 
//      const char *argType = [msgContext->signature getArgumentTypeAtIndex:i];
//      while (*argType == 'r' || *argType == 'n' || *argType == 'N' || *argType == 'o' || *argType == 'O' || *argType == 'R' || *argType == 'V')
//        argType++;
//      
//      NSCAssert(*argType == '*' || *argType == '^', @"Invalid type for Pointer !");  
//      
//      if (*argType == '*')
//      { 
//        if ([args[i] pointerType][0] == 'c') a = [args[i] cPointer];
//        else FSExecError([NSString stringWithFormat:@"argument %d of method \"%@\" is a Pointer of type \"%s\". A Pointer of type \"c\" was expected.",i-1,selectorStr,[args[i] pointerType]]);          
//      }
//      else if (strcmp([args[i] pointerType], argType+1) != 0) FSExecError([NSString stringWithFormat:@"argument %d of method \"%@\" is a Pointer of type \"%s\". A Pointer of type \"%s\" was expected.",i-1,selectorStr,[args[i] pointerType],argType+1]);
//    
//      a = [args[i] cPointer];
//    }
//    else FSArgumentError(args[i],i-1,@"Pointer",selectorStr);    
//    
//    [invocation setArgument:&a atIndex:i];
//    break; 
		
  default:
    {
      switch (mapType) 
      {
        case FSMapArgument           : FSExecError([NSString stringWithFormat:@"type expected for %@ is not supported by F-Script", description(mapType, argumentNumber, selector, ivarName)]);
        case FSMapDereferencedPointer: FSExecError(@"can't dereference pointer: the type of the referenced data is not supported by F-Script");
        case FSMapIVar               : FSExecError([NSString stringWithFormat:@"can't assign value to instance variable %@: the type of this instance variable is not supported by F-Script", ivarName]);
        case FSMapReturnValue        : NSCAssert(0, @"unexpected type");
      }
    }  
  }
}
      
void assign(FSCNBase *lnode, id rvalue, FSSymbolTable *symbolTable) 
{
  switch(lnode->nodeType)
  {
  case IDENTIFIER :
  { 
    if (![symbolTable setObject:rvalue forIndex:((FSCNIdentifier *)lnode)->locationInContext])
    {
      id s;
      
      if (symbolTable->localCount != 0 && [symbolTable->locals[0].symbol isEqualToString:@"self"] && symbolTable->locals[0].status == DEFINED)
      {
        s = symbolTable->locals[0].value;      
      }
      else
      {
        s = [symbolTable objectForSymbol:@"self" found:NULL];
      }  
      
      if (s)
      {
        NSString *identifierString = ((FSCNIdentifier *)lnode)->identifierString;
        Ivar ivar = class_getInstanceVariable([s class], [identifierString cStringUsingEncoding:NSASCIIStringEncoding]);
        if (ivar)
        {
          const char *encodedType = ivar_getTypeEncoding(ivar);
          
          if (encodedType[0] == '@')
          {  
            object_setIvar(s, ivar, rvalue);
          }
          else
          {
            char fsEncodedType = FSEncode(encodedType);
            
            if (fsEncodedType == '@') object_setIvar(s, ivar, rvalue);
            else FSMapFromObject( (char *)s + ivar_getOffset(ivar), 0, fsEncodedType, rvalue, FSMapIVar, 0, nil, identifierString, NULL);
          }        
        }
        else
        {
          BOOL found = fscript_setDynamicIvarValue(s, identifierString, rvalue);
          if (!found) FSExecError([NSString stringWithFormat:@"undefined identifier %@", identifierString]); 
        }    
      }
      else FSExecError(@"can't execute assignment");
    }
    break;
  }
 
  case ARRAY:
  {    
    if (![rvalue isKindOfClass:[NSArray class]] || [rvalue count] != ((FSCNArray *)lnode)->count)
      FSExecError(@"left and right sides in multiple assignment must be arrays of same size");
    
    for (NSUInteger i = 0; i < ((FSCNArray *)lnode)->count; i++) 
    {
      assign( ((FSCNArray *)lnode)->elements[i], [rvalue objectAtIndex:i], symbolTable );
    }
    break;
  }         

  default :
    FSExecError(@"left part of assignment must be an identifier or an array of identifiers");
                                  
  } // end_switch
}

id sendMsgNoPattern(id receiver, SEL selector, NSUInteger argumentCount, id *args, FSMsgContext *msgContext, Class ancestorToStartWith)
{
  BOOL sendUsingNSInvocation;
    
  if (receiver == nil)
  {
    if      (selector == @selector(operator_equal_equal:)) return (args[2] == nil ? (id)fsTrue : (id)fsFalse);
    else if (selector == @selector(operator_tilde_tilde:)) return (args[2] != nil ? (id)fsTrue : (id)fsFalse);
    else return nil;  
  }
  else if (selector == @selector(retain) && selector == @selector(release)) 
  {
    // We are running under GC and in the presence of an "ignored selector" 
    // Under GC, selectors for retain, release, autorelease, retainCount and dealloc are all represented by the same special selector     
    return receiver; 
  }
  else if (/*(receiver!=[NSProxy class]) &&*/ ![receiver respondsToSelector:selector] && [receiver methodSignatureForSelector:selector] == nil) // A receiver capable of forwarding the message will return a non-nil signature
  {    
#if !TARGET_OS_IPHONE
    if ( (isKindOfClassNSDistantObject(receiver) && (           // fix for broken NSProxy meta-class level implementation in OS X
             selector == @selector(operator_equal_equal:)     || selector == @selector(operator_tilde_tilde:) 
          || selector == @selector(applyBlock:)
          || selector == @selector(enlist)                    || selector == @selector(enlist:)
          || selector == @selector(printString)               || selector == @selector(vend:)
          || selector == @selector(asBlock)                   || selector == @selector(asBlockOnError:) 
          || selector == @selector(classOrMetaclass)          || selector == @selector(throw) 
          || selector == @selector(setProtocolForProxy:)      || selector == @selector(connectionForProxy)
          || selector == @selector(initWithLocal:connection:) || selector == @selector(initWithTarget:connection:)))
          || (isKindOfClassNSProtocolChecker(receiver) && (
             selector == @selector(protocol)                  || selector == @selector(target) 
          || selector == @selector(initWithTarget:protocol:)
        )))
      switch (argumentCount)
      {
        case 2:  return objc_msgSend(receiver,selector); 
        case 3:  return objc_msgSend(receiver,selector,args[2]);
        case 4:  return objc_msgSend(receiver,selector,args[2],args[3]);
        default: assert(0);
      }   
    else 
#endif
    if (selector == @selector(_ul_count) && [receiver isProxy])
    {  
      return ([receiver isKindOfClass:[NSArray class]] ? [FSNumber numberWithDouble:[receiver count]] : [FSNumber numberWithDouble:1]);
    }
    else if (selector == @selector(_ul_objectAtIndex:) && [receiver isProxy])
    {
      return ([receiver isKindOfClass:[NSArray class]] ? [receiver objectAtIndex:[args[2] doubleValue]] : [receiver self]);
    }
    else if ([receiver isKindOfClass:[NSArray class]]) 
    {     
      FSArray *level = [FSArray arrayWithCapacity:argumentCount-1];
      [level addObject:[FSNumber numberWithDouble:1]];
      for (NSUInteger i = 2; i < argumentCount; i++)
      {
        if([args[i] isKindOfClass:[NSArray class]]) 
          [level addObject:[FSNumber numberWithDouble:1]]; 
        else 
          [level addObject:[FSNumber numberWithDouble:0]];
      }
      return sendMsgPattern(receiver, selector, argumentCount, args, [FSPattern patternWithDeep:1 level:level nextPattern:nil], msgContext, nil);
    }
    else if (selector == @selector(operator_equal:) && [[NSUserDefaults standardUserDefaults] boolForKey:@"MaintainFScript1EqualityOperatorsSemantics"]) 
    {
      NSString *warning = [NSString stringWithFormat:@"Warning: message \"=\" sent to %@. In the future, \"=\" will not be automatically provided for all objects. Change your code to use \"isEqual:\".", descriptionForFSMessage(receiver)];
      if (![issuedWarnings containsObject:warning])
      {
        NSLog(@"%@", warning);
        [issuedWarnings addObject:warning];
      }  
      return [receiver isEqual:args[2]] ? fsTrue : fsFalse;
    }
    else if (selector == @selector(operator_tilde_equal:) && [[NSUserDefaults standardUserDefaults] boolForKey:@"MaintainFScript1EqualityOperatorsSemantics"]) 
    {
      NSString *warning =[NSString stringWithFormat:@"Warning: message \"~=\" sent to %@. In the future, \"~=\" will not be automatically provided for all objects. Change your code to use \"isEqual:\".", descriptionForFSMessage(receiver)];
      if (![issuedWarnings containsObject:warning])
      {
        NSLog(@"%@", warning);
        [issuedWarnings addObject:warning];
      }      
      return [receiver isEqual:args[2]] ? fsFalse : fsTrue ;
    }     
    
    FSExecError([NSString stringWithFormat:@"%@ does not respond to \"%@\"", descriptionForFSMessage(receiver), [FSCompiler stringFromSelector:selector]]); 
  } 
  else if (selector == @selector(alloc)) // alloc and allocWithZone: return non initialized objects.
                                         // They can't be invoked using NSInvocation (NSInvocation
                                         // retains its return value, which this is not a good thing to do
                                         // with uninitialized objects!). This is why we have this special case.  
  {
    id newObject;
    
    if (ancestorToStartWith)
    {
      struct objc_super s_objc_super = {receiver, ancestorToStartWith};
      newObject = objc_msgSendSuper(&s_objc_super, selector);
    }  
    else
    {  
      newObject = objc_msgSend(receiver,selector);
    }
    return newObject;
  }
  else if (selector == @selector(allocWithZone:))
  {
    if (![args[2] isKindOfClass:[FSPointer class]]  && ![args[2] isKindOfClass:[Pointer class]])
      FSVerifClassArgs(@"allocWithZone:",1,args[2],[FSPointer class],(NSInteger)1);
    
    id newObject;
    
    if (ancestorToStartWith)
    {
      struct objc_super s_objc_super = {receiver, ancestorToStartWith};
      newObject = objc_msgSendSuper(&s_objc_super, selector, [args[2] cPointer]);
    }  
    else
    {  
      newObject = objc_msgSend(receiver,selector, [args[2] cPointer]);
    } 
    return newObject;   
  }
  
  [msgContext prepareForMessageWithReceiver:receiver selector:selector];


#ifdef MESSAGING_USES_NSINVOCATION
  sendUsingNSInvocation = YES; 
#else
  sendUsingNSInvocation = argumentCount > 9 || msgContext->shouldConvertArguments || msgContext->specialReturnType;
#endif
  
  if (!sendUsingNSInvocation) 
  { 
    id r;
    struct objc_super s_objc_super = {receiver, ancestorToStartWith};
        
    switch (argumentCount)
    {
    case 2: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector);                                                                else r = objc_msgSend(receiver,selector); break;
    case 3: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2]);                                                       else r = objc_msgSend(receiver,selector,args[2]); break;
    case 4: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3]);                                              else r = objc_msgSend(receiver,selector,args[2], args[3]); break;
    case 5: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3], args[4]);                                     else r = objc_msgSend(receiver,selector,args[2], args[3], args[4]); break;
    case 6: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3], args[4], args[5]);                            else r = objc_msgSend(receiver,selector,args[2], args[3], args[4], args[5]);break;
    case 7: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3], args[4], args[5], args[6]);                   else r = objc_msgSend(receiver,selector,args[2], args[3], args[4],args[5],args[6]); break;
    case 8: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3], args[4], args[5], args[6], args[7]);          else r = objc_msgSend(receiver,selector,args[2], args[3], args[4],args[5],args[6],args[7]); break;
    case 9: if (ancestorToStartWith) r = objc_msgSendSuper(&s_objc_super, selector, args[2], args[3], args[4], args[5], args[6], args[7], args[8]); else r = objc_msgSend(receiver,selector,args[2], args[3], args[4],args[5],args[6],args[7],args[8]); break;
    default:
      assert(0);
    } 
    if (msgContext->return_void) return fsVoid;       
    else                         return r;
  }
  /*else
  {
    NSMutableArray   *mappedFSObjectPointers = nil;
    union ObjCValue   returnValue;
    union ObjCValue   argumentValues[argumentCount];
    void             *argumentsValuesPtrs[argumentCount];
    ffi_type        **argumentsTypes;
    ffi_type         *returnType = ffiTypeFromFSEncodedType(msgContext->returnType);
    ffi_cif          *cif;
    ffi_status        status;
           
    if (msgContext->unsuportedReturnType) FSExecError([NSString stringWithFormat:@"invalid method invocation (return type not supported by F-Script)"]);
    
    argumentsValuesPtrs[0] = &receiver;
    argumentsValuesPtrs[1] = &selector;
       
    for (NSUInteger i = 2; i < argumentCount; i++)
    { 
      if (!msgContext->shouldConvertArguments)
      {
        argumentsValuesPtrs[i] = &(args[i]);
        continue;
      }
      
      FSObjectPointer *mappedFSObjectPointer = nil;
      
      FSMapFromObject(&(argumentValues[i]), 0, msgContext->argumentTypes[i-2], args[i], FSMapArgument, i-1, selector, nil, &mappedFSObjectPointer);
      
      if (mappedFSObjectPointer)
      {
        if (mappedFSObjectPointers) [mappedFSObjectPointers addObject:mappedFSObjectPointer];
        else mappedFSObjectPointers = [NSMutableArray arrayWithObject:mappedFSObjectPointer];
      }
      
      argumentsValuesPtrs[i] = &(argumentValues[i]);
    }
    
    argumentsTypes = malloc(sizeof(ffi_type *) * argumentCount);
    
    argumentsTypes[0] = &ffi_type_pointer;
    argumentsTypes[1] = &ffi_type_pointer; // This code assume that SEL is a pointer type

    if (msgContext->shouldConvertArguments)
    {
      for (NSUInteger i = 2; i < argumentCount; i++)
        argumentsTypes[i] = ffiTypeFromFSEncodedType(msgContext->argumentTypes[i-2]);
    }
    else
    {
      for (NSUInteger i = 2; i < argumentCount; i++)
        argumentsTypes[i] = &ffi_type_pointer;
    }
        
    // Prepare the ffi_cif structure.
    cif = malloc(sizeof(ffi_cif));
    
    if ((status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argumentCount, returnType, argumentsTypes)) != FFI_OK)
    {
      free(argumentsTypes);
      free(cif);
      FSExecError(@"F-Script internal error: can't prepare the ffi_cif structure for ffi_call");
    }
    
    // Invoke the method
    IMP imp = class_getMethodImplementation(object_getClass(receiver), selector);
    
    if (mappedFSObjectPointers == nil)
 	{			      
      ffi_call(cif, FFI_FN(imp), &returnValue, argumentsValuesPtrs);
    }
	else
	{
	  for (NSUInteger i = 0, count = [mappedFSObjectPointers count]; i < count; i++)
	  {
        [[mappedFSObjectPointers objectAtIndex:i] autoreleaseAll];
		
		@try
        {
		  ffi_call(cif, FFI_FN(imp), &returnValue, argumentsValuesPtrs);
		}
        @finally
        {
          [[mappedFSObjectPointers objectAtIndex:i] retainAll];
		}	    
	  }
	} 
        
    free (cif); // TODO: ensure it will be freed even if method invocation raise an exception
    
    if( msgContext->return_void ) return fsVoid;     

    char fsEncodedType = msgContext->returnType;
    
    return FSMapToObject(&returnValue, 0, fsEncodedType, fsEncodedType == '*' || fsEncodedType == '^' ? [msgContext->signature methodReturnType] : NULL, nil, nil);
    
  }
  */
  else    
  {            
    NSMutableArray *mappedFSObjectPointers = nil;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:msgContext->signature];
    
    [invocation setSelector:selector];

    for (NSUInteger i = 2; i < argumentCount; i++)
    { 
      if (!msgContext->shouldConvertArguments)
      {
        [invocation setArgument:&(args[i]) atIndex:i];
        continue;
      }
      
      FSObjectPointer *mappedFSObjectPointer = nil;
      union ObjCValue a;
      
      FSMapFromObject(&a, 0, msgContext->argumentTypes[i-2], args[i], FSMapArgument, i-1, selector, nil, &mappedFSObjectPointer);
      
      if (mappedFSObjectPointer)
      {
        if (mappedFSObjectPointers) [mappedFSObjectPointers addObject:mappedFSObjectPointer];
        else mappedFSObjectPointers = [NSMutableArray arrayWithObject:mappedFSObjectPointer];
      }
      
      [invocation setArgument:&a atIndex:i];
    }
    
    if (msgContext->unsuportedReturnType) FSExecError([NSString stringWithFormat:@"invalid method invocation (return type not supported by F-Script)"]);
    
    if (ancestorToStartWith)
    {
      // Invoking instancesRespondToSelector: below has the side effect of invoking the resolveInstanceMethod: mechanism if needed, which is desirable
      if ([ancestorToStartWith instancesRespondToSelector:selector])
      {
        Class ancestor = ancestorToStartWith;
        unsigned int i, count;
        Method *methods;
        Method  method = NULL; // initialized to NULL to avoid a spurious warning 

        do
        {
          methods = class_copyMethodList(ancestor, &count);
          for (i = 0; i < count && method_getName(methods[i]) != selector; i++);
          if (i == count) 
            ancestor = class_getSuperclass(ancestor);
          else 
            method = methods[i];
          free(methods);
        } while (ancestor != nil && i == count);
      
        if (i == count) // Defensive. Should not happen.
        {
          FSExecError([NSString stringWithFormat:@"F-Script internal error: no method %@ found in class %@, despite instancesRespondToSelector: returning YES!", [FSCompiler stringFromSelector:selector], printString(ancestorToStartWith)]);
        }
        else 
        {
          const char *ancestorName = class_getName(ancestor);
          const char *selectorCString = sel_getName(selector);
          static char *stubNamePart1;
          stubNamePart1 = class_isMetaClass(ancestor) ? "__F-ScriptGeneratedStubForMetaClass_" : "__F-ScriptGeneratedStubForClass_";
          static char *stubNamePart2 = "_forMethod_";
          NSUInteger stubNameMaxLength = 48 + strlen(selectorCString) + strlen(ancestorName);
          char stubName[stubNameMaxLength];
          stpcpy(stpcpy(stpcpy(stpcpy(stubName, stubNamePart1), ancestorName), stubNamePart2), selectorCString);
          SEL stubSelector = sel_getUid(stubName);

          Method stubMethod = class_getInstanceMethod(ancestor, stubSelector); 
          
          if (stubMethod != NULL) // If the stub method already exists
          {
            method_setImplementation(stubMethod, method_getImplementation(method));
          }
          else
          {
            class_addMethod(ancestor, stubSelector, method_getImplementation(method), method_getTypeEncoding(method)); 
          }
          
          [invocation setSelector:stubSelector];
        }
      }
      else FSExecError([NSString stringWithFormat:@"no method %@ found in class %@", [FSCompiler stringFromSelector:selector], printString(ancestorToStartWith)]);
    }    
    
    if (mappedFSObjectPointers == nil)
 	{			      
      [invocation invokeWithTarget:receiver];
    }
	else
	{
	  for (NSUInteger i = 0, count = [mappedFSObjectPointers count]; i < count; i++)
	  {
        [[mappedFSObjectPointers objectAtIndex:i] autoreleaseAll];
		
		@try
        {
		  [invocation invokeWithTarget:receiver];
		}
        @finally
        {
          [[mappedFSObjectPointers objectAtIndex:i] retainAll];
		}	    
	  }
	} 
	    
    if( msgContext->return_void ) return fsVoid;     
    
    union ObjCValue returnValue;
    
    [invocation getReturnValue:&returnValue];
    
    char fsEncodedType = msgContext->returnType;
    
    return FSMapToObject(&returnValue, 0, fsEncodedType, fsEncodedType == '*' || fsEncodedType == '^' ? [msgContext->signature methodReturnType] : NULL, nil, nil);    
  }
  
  return nil; // W
}

id sendMsgPattern(id receiver, SEL selector, NSUInteger argumentCount, id *args, FSPattern *pattern, FSMsgContext *msgContext, Class ancestorToStartWith)
{
  NSUInteger i,j,k; 
  BOOL ready, is_void;
  id res_sub_msg;
  NSUInteger currentDeep;
  int *level = [pattern level];
  NSUInteger level_count = [pattern levelCount];
  NSUInteger patternDeep = [pattern deep];
  NSUInteger i_tab[argumentCount];
  id subArgs[argumentCount];
  NSUInteger r_size_tab[1+patternDeep];
  id r_tab[1+patternDeep];
  NSUInteger size = 0; // initialization of size in order to avoid a warning
  BOOL size_initialized;    
  FSPattern *nextPattern = [pattern nextPattern];
  BOOL empty = NO;
  //id args2[argumentCount];
            
  r_size_tab[0] = 1;
  
  /*
  ////////////// Since there is no meaningful way to implement _ul_objectAtIndex: on sets, we must replace any set that is going to be "iterated" by an equivalent array.
  for (i = 0, j = 0; i < argumentCount; (i == 0 ? i+=2 :i++), j++)
  {
    if (level[j] != 0 && [args[i] isKindOfClass:[NSSet class]]) break;
  }

  if (i < argumentCount)
  {
    for (k = 0; k < argumentCount; k++) args2[k] = args[k];
    args = args2;

    for (; i < argumentCount; (i == 0 ? i+=2 :i++), j++)
    {
      if (level[j] != 0 && [args[i] isKindOfClass:[NSSet class]]) 
      { 
        args[i] = [args[i] allObjects];
      }
    }
  }
  /////////////////////////////////////////////////////////
  */
            
  for (currentDeep = patternDeep; currentDeep; currentDeep--)
  {
    size_initialized = NO;
    //NSLog(@"-----------");
    for (i = 0, j =0; i < argumentCount; (i == 0 ? i+=2 : i++), j++)
    {
      //NSLog(@"%d", level[j]);
      if (level[j] == (int)currentDeep) 
      {
        NSUInteger count = [args[i] _ul_count];
        if (size_initialized && count != size)
          FSExecError(@"collections must be of same size");
        else
        {
          size = count;
          size_initialized = YES;
        }  
      }  
    }
    NSCAssert(size_initialized, @"Size not initialized! Incorrect pattern!"); 
    r_size_tab[currentDeep] = size;
  }   
    
  subArgs[1] = (id)selector;
    
  if ([pattern isSimpleLoopOnReceiver]) 
  {
    if ([receiver isKindOfClass:[FSArray class]])
    {
      NSString *wiredSelectorStr = [@"simpleLoop_" stringByAppendingString:(selector ? NSStringFromSelector(selector): @"")];
      SEL wiredSelector = NSSelectorFromString(wiredSelectorStr);
      if ([[receiver arrayRep] respondsToSelector:wiredSelector])
      {
        id r;
        
        args[0] = [receiver arrayRep];
        args[1] = (id)wiredSelector;
        r = sendMsgNoPattern(args[0], wiredSelector, argumentCount, args, msgContext, nil);
        args[0] = receiver;
        args[1] = (id)selector;
        return r;
      } 
    }
    
    if (![args[0] isProxy] && [args[0] isKindOfClass:[FSArray class]])
    {
      id *t1 = [args[0] dataPtr]; NSUInteger t1_count = [args[0] count];
      FSArray *r = [FSArray arrayWithCapacity:t1_count];

      for (i = 2; i < argumentCount; i++) subArgs[i] = args[i];
      
      is_void = (t1_count > 0);
      for (i = 0; i < t1_count; i++)
      {
        subArgs[0] = t1[i];
        res_sub_msg = sendMsgNoPattern(subArgs[0], selector, argumentCount, subArgs, msgContext, nil);
        is_void = is_void && res_sub_msg == fsVoid;
        [r addObject:res_sub_msg]; 
      } 
      return is_void ? (id)fsVoid : (id)r;
    }
    
    /* The folowing is commented out because arrayByApplyingSelector: leads to unwanted results. See http://groups.google.com/group/f-script/browse_thread/thread/40eeba7515948e8e  
    if ([receiver isKindOfClass:[SBElementArray class]] && argumentCount <= 3)
    {
      if ([receiver count] > 0)
      {
        id elem = [receiver objectAtIndex:0];
        NSMethodSignature *signature = [elem methodSignatureForSelector:selector];
        
        if (signature)
        {
          const char *returnType = [signature methodReturnType];
        
          if (strcmp(returnType, @encode(void)) == 0)
          {
            argumentCount == 2 ? [receiver arrayByApplyingSelector:selector] : [receiver arrayByApplyingSelector:selector withObject:args[2]];
            return fsVoid;
          }
          else if (strcmp(returnType, @encode(BOOL)) == 0)
          {
            NSArray *intermediateResult = argumentCount == 2 ? [receiver arrayByApplyingSelector:selector] : [receiver arrayByApplyingSelector:selector withObject:args[2]];
            FSArray *r = [FSArray arrayWithCapacity:[intermediateResult count]];
            for (NSNumber *elem in intermediateResult)
            {
              [r addObject:[elem boolValue] ? (id)fsTrue : (id)fsFalse];
            }
            return r;
          } 
          else return argumentCount == 2 ? [receiver arrayByApplyingSelector:selector] : [receiver arrayByApplyingSelector:selector withObject:args[2]];
        }
      }    
    }
    */
      
  }
  else if ([pattern isDoubleLoop])
  {
    if ([receiver isKindOfClass:[FSArray class]] && [args[2] isKindOfClass:[FSArray class]] && [[receiver arrayRep] class] == [[args[2] arrayRep] class] && ![receiver isProxy] && ![args[2] isProxy])
    {
      NSString *wiredSelectorStr = [@"doubleLoop_" stringByAppendingString:(selector ? NSStringFromSelector(selector): @"")];
      SEL wiredSelector = NSSelectorFromString(wiredSelectorStr);
      if ([[receiver arrayRep] respondsToSelector:wiredSelector])
      {
        id r;
        
        args[0] = [receiver arrayRep];
        //((SEL)args[1]) = wiredSelector;
        args[1] = (id)wiredSelector;

        r = sendMsgNoPattern(args[0], wiredSelector, argumentCount, args, msgContext, nil);
        args[0] = receiver;
        args[1] = (id)selector;
        return r;
      } 
    }
  }
  else if (level_count == 2 && level[0] == 1 && level[1] == 2 && ![args[0] isProxy] && ![args[2] isProxy]
           && [args[0] isKindOfClass:[FSArray class]] && [args[2] isKindOfClass:[FSArray class]])
  {
    id *t1 = [args[0] dataPtr]; NSUInteger t1_count = [args[0] count];
    id *t2 = [args[2] dataPtr]; NSUInteger t2_count = [args[2] count];
    FSArray *r = [FSArray arrayWithCapacity:t1_count];
    is_void = t1_count > 0 && t2_count > 0;
    for (i = 0; i < t1_count; i++)
    {
      FSArray *sub_r = [FSArray arrayWithCapacity:t2_count];
      [r addObject:sub_r];
      subArgs[0] = t1[i];
      for (j = 0; j < t2_count; j++)
      {
        subArgs[2] = t2[j];
        res_sub_msg = sendMsg(subArgs[0],selector,argumentCount,subArgs,nextPattern,msgContext,nil);
        is_void = is_void && res_sub_msg == fsVoid;
        [sub_r addObject:res_sub_msg];  
      }
    }
    return is_void ? (id)fsVoid : (id)r;   
  }
        
  for (i = 0, j = 0; i < argumentCount; (i == 0 ? i+=2 :i++), j++)
  {
    id currentItem = args[i];
    i_tab[j] = 0;
    if (level[j] == 0) subArgs[i] = currentItem;
    else
    {
      if ([currentItem _ul_count] == 0) empty = YES;
      else                              subArgs[i] = [currentItem _ul_objectAtIndex:0];
    }
  }                 
          
  for (i = 0, currentDeep = patternDeep; i <= currentDeep; i++)
    r_tab[i] = [FSArray arrayWithCapacity:r_size_tab[i]];   
    
  is_void = !empty;        
        
  while(1)
  {
    currentDeep = patternDeep;
    if (!empty)
    {
      res_sub_msg = sendMsg(subArgs[0],selector,argumentCount,subArgs,nextPattern,msgContext,nil);
      [r_tab[currentDeep] addObject:res_sub_msg ];
      is_void = is_void && res_sub_msg == fsVoid;
    }
    
    if (currentDeep == 0)  return is_void ? fsVoid : [r_tab[0] objectAtIndex:0];
      
    ready = NO;
    while(!ready)
    {
      ready = YES;
      for (i = 0, j =0; i < argumentCount; (i == 0 ? i+=2 : i++), j++)
      {
        if (level[j] == (int)currentDeep)
        {
          if (i_tab[j]+1 >= [args[i] _ul_count])
          {
            for (k = 0 ; k+1 < argumentCount; k++)
            {
              if (level[k] == (int)currentDeep)
                i_tab[k] = 0;
            }
            
            [r_tab[currentDeep-1] addObject:r_tab[currentDeep]];
            r_tab[currentDeep] = [FSArray arrayWithCapacity:r_size_tab[currentDeep]]; 
            currentDeep--; 
            if (currentDeep == 0)
              return is_void ? fsVoid : [r_tab[0] objectAtIndex:0];
            ready = NO;
            break;
          }    
          else  
            (i_tab[j])++;
        }
      }
    }
    
    for (i = 0,j = 0; i < argumentCount; (i==0 ? i+=2 : i++), j++)
    {
      if (level[j] != 0)
        subArgs[i] = [args[i] _ul_objectAtIndex:i_tab[j]];
    }          
  }
}    

id sendMsg(id receiver, SEL selector, NSUInteger argumentCount, id *args, FSPattern* pattern, FSMsgContext *msgContext, Class ancestorToStartWith)
{  
  if (pattern) return sendMsgPattern(receiver, selector, argumentCount, args, pattern, msgContext, ancestorToStartWith);
  else         return sendMsgNoPattern(receiver, selector, argumentCount, args, msgContext, ancestorToStartWith);
}
    
struct res_exec execute(FSCNBase *codeNode, FSSymbolTable *symbolTable) // may raise
{
  return executeForBlock(codeNode, symbolTable, nil);
}    
    
struct res_exec executeForBlock(FSCNBase *codeNode, FSSymbolTable *symbolTable, FSBlock* executedBlock) // may raise
{
  struct res_exec r = {-1, -1, nil, nil, nil}; // initialized to avoid spurious warnings
  NSInteger errorFirstCharIndex = -1;
  NSInteger errorLastCharIndex  = -1;

  if (codeNode == nil) 
  {
    r.errorStr = nil;
    r.result = nil;
    r.exception = nil;
    return r;
  }
 
  r.errorStr = nil;
        
  @try
  {
    r.result = execute_rec(codeNode, symbolTable, &errorFirstCharIndex, &errorLastCharIndex);
  }
  @catch (FSReturnSignal *returnSignal)
  {
    if ([returnSignal block] == executedBlock)
    {
      r.result = [returnSignal result]; 
      r.errorStr = nil;
    }
    else @throw;  
  } 
  @catch (NSException *exception)
  { 
    NSMutableDictionary *userInfo;
    NSMutableArray *blockStack;

    if (!(userInfo = [[[exception userInfo] mutableCopy] autorelease])) 
      userInfo = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
    
    if (!(blockStack = [userInfo objectForKey:@"FScriptBlockStack"]))
    { // This blockStack will represent the callStack of blocks. We construct it in order to be able to have it when the exception is returned to the top level FSInterpreter (in order for example to provide it in the FSInterpreterResult) or to a block exception handler (see method -onException: of class FSBlock to see how to use an exception handler at the F-Script language level)
      blockStack = [[NSMutableArray alloc] init];
      [userInfo setObject:blockStack forKey:@"FScriptBlockStack"]; 
      [blockStack release];
    }  
        
    r.errorFirstCharIndex = errorFirstCharIndex;
    r.errorLastCharIndex  = errorLastCharIndex;
    r.errorStr            = FSErrorMessageFromException(exception);
    r.exception           = [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo]; // We do this to ensure that the returned exception has a user info dictionnary (this may not be the case of localException);
        
    if (executedBlock) [blockStack addObject:[BlockStackElem blockStackElemWithBlock:executedBlock errorStr:r.errorStr firstCharIndex:errorFirstCharIndex lastCharIndex:errorLastCharIndex]];
  }
  @catch (id exception)
  { 
    r.errorFirstCharIndex = errorFirstCharIndex;
    r.errorLastCharIndex  = errorLastCharIndex;
    r.errorStr            = FSErrorMessageFromException(exception);
    r.exception           = exception;     
  }
  return r;
}

static void checkNoShadowingOfInheritedIvars(NSString *className, NSArray *ivarNames, Class superclass)    
{
  while(superclass) 
  {
    NSMutableSet *superclassIvarNames = [NSMutableSet set];
    
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList(superclass, &ivarCount);
    
    for (unsigned int i = 0; i < ivarCount; i++)
    {
      [superclassIvarNames addObject:[NSString stringWithUTF8String:ivar_getName(ivars[i])]];
    }
    
    free(ivars);
    
    [superclassIvarNames unionSet:fscript_dynamicIvarNames(superclass)];
    
    for (NSString *name in ivarNames)
    {
      if ([superclassIvarNames containsObject:name])
        FSExecError([NSString stringWithFormat:@"the class definition for \"%@\" is invalid because the variable \"%@\" is already defined in superclass \"%@\"", className, name, NSStringFromClass(superclass)]);
    }  
    
    superclass = [superclass superclass];
  }
}    

static void checkNoChangingSignatureOfExistingMethods(Class class, NSArray *methodNodes)
{    
  unsigned int instanceMethodCount, classMethodCount;     
  NSUInteger i;
  Method *instanceMethods = class_copyMethodList(class, &instanceMethodCount);
  Method *classMethods    = class_copyMethodList(object_getClass(class), &classMethodCount);
  
  for (FSCNMethod *methodNode in methodNodes)
  {
    FSMethod *method = methodNode->method;

    if (!FSIsIgnoredSelector(method->selector))
    {
      // We are not in presence of an "ignored selector", so we can safely compare method names
      // (Under GC, selectors for retain, release, autorelease, retainCount and dealloc are all represented by the same special non-functional "ignored" selector)     

      Method *existingMethods;
      unsigned int existingMethodCount;
      
      if (methodNode->isClassMethod) 
      {
        existingMethods     = classMethods; 
        existingMethodCount = classMethodCount;
      }
      else
      {
        existingMethods     = instanceMethods; 
        existingMethodCount = instanceMethodCount;
      }
      
      for (i = 0; i < existingMethodCount && method_getName(existingMethods[i]) != method->selector; i++);
      
      if (i < existingMethodCount && strcmp(method_getTypeEncoding(existingMethods[i]), method->types) != 0) 
      {
        // A method with the same selector and another signature is already defined for the class
        free(instanceMethods);
        free(classMethods);
        FSExecError([NSString stringWithFormat:@"can't modify the signature of method \"%@\" in class %@. When redefining an existing method, the new one and the original must have the same signature.", NSStringFromSelector(method->selector), NSStringFromClass(class)]);
      }
    }  
  }
  free(instanceMethods);
  free(classMethods);
}

static void addMethodsToClass(NSArray *methods, Class class)
{
    // We make sure we won't try to replace an existing method with a new one with another signature; Objective-C doesn't support this (10.6.2) 
    checkNoChangingSignatureOfExistingMethods(class, methods);

    for (FSCNMethod *methodNode in methods)
    {
      BOOL ok;
      FSMethod *method = methodNode->method;
      
      if (methodNode->isClassMethod) ok = [method addToClass:object_getClass(class)];
      else                           ok = [method addToClass:class]; 
      
#if !TARGET_OS_IPHONE
      if (ok) [FScriptTextView registerMethodNameForCompletion:NSStringFromSelector(method->selector)];
#endif
      if (!ok) FSExecError([NSString stringWithFormat:@"invalid method \"%@\"", NSStringFromSelector(method->selector)]);
    }
}

id execute_rec(FSCNBase *codeNode, FSSymbolTable *localSymbolTable, NSInteger *errorFirstCharIndexPtr, NSInteger *errorLastCharIndexPtr)  
{
  id receiver;
  id res_msg;
  NSUInteger i;
      
  switch(codeNode->nodeType)
  {
  case SUPER :
  case IDENTIFIER :
  { 
    BOOL isDefined;
    id value;
    
    value = [localSymbolTable objectForIndex:((FSCNIdentifier *)codeNode)->locationInContext isDefined:&isDefined];
      
    if (isDefined) 
    {
      return value;
    }
    else 
    { 
      NSString *identifierString = ((FSCNIdentifier *)codeNode)->identifierString;
      BOOL found;
      id s;
      
      // Look up instance variables

      if (localSymbolTable->localCount != 0 && [localSymbolTable->locals[0].symbol isEqualToString:@"self"] && localSymbolTable->locals[0].status == DEFINED)
      {
        s = localSymbolTable->locals[0].value;      
      }
      else
      {
        s = [localSymbolTable objectForSymbol:@"self" found:NULL];
      }  
      
      if (s) 
      {  
        value = fscript_dynamicIvarValue(s, identifierString, &found);
        
        if (found) return value;          
        else
        {
          Ivar ivar = class_getInstanceVariable([s class], [identifierString cStringUsingEncoding:NSASCIIStringEncoding]); // TODO : consider caching the C string to avoid call to cStringUsingEncoding: each time the ivar is accessed
          if (ivar)
          {
            const char *type = ivar_getTypeEncoding(ivar);
            if (type[0] == '@') return object_getIvar(s, ivar);
            else                return FSMapToObject( (char *)s + ivar_getOffset(ivar), 0, FSEncode(type), type, nil, identifierString);
          }
        }
      }
      
      // Look up globals
      value = [[FSGlobalScope sharedGlobalScope] objectForSymbol:identifierString found:&found];
      if (found) return value;
      
      // Look up class names
      if ( (value = NSClassFromString(((FSCNIdentifier *)codeNode)->identifierString)) ) return value;
      
      *errorFirstCharIndexPtr = codeNode->firstCharIndex; 
      *errorLastCharIndexPtr  = codeNode->lastCharIndex;
      FSExecError([NSString stringWithFormat:@"undefined identifier \"%@\" ", ((FSCNIdentifier *)codeNode)->identifierString]);
    }                                        
  }
  
  case UNARY_MESSAGE:
  case BINARY_MESSAGE:
  case KEYWORD_MESSAGE:
  { 
    FSCNMessage *node = (FSCNMessage *)codeNode;  
    NSUInteger argumentCount;
    Class ancestorToStartWith;
    
    if (codeNode->nodeType == UNARY_MESSAGE)  
    {
      argumentCount = 0;
      if (node->selector == @selector(release) && (node->receiver->nodeType == IDENTIFIER || node->receiver->nodeType == SUPER))
        [localSymbolTable willSendReleaseToSymbolAtIndex:((FSCNIdentifier *)(node->receiver))->locationInContext];
    }
    else if (codeNode->nodeType == BINARY_MESSAGE) 
      argumentCount = 1;
    else                                           
      argumentCount = ((FSCNKeywordMessage *)node)->argumentCount;
        
    id *arguments = NSAllocateCollectable(sizeof(id) * (argumentCount+2) , NSScannedOption | NSCollectorDisabledOption);
    
    @try
    {      
      arguments[0] = execute_rec(node->receiver, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
      arguments[1] = (id)(node->selector );

      if      (codeNode->nodeType == BINARY_MESSAGE) arguments[2] = execute_rec( ((FSCNBinaryMessage *)node)->argument, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
      else if (codeNode->nodeType == KEYWORD_MESSAGE)
      {
        for (i = 0; i < argumentCount; i++) 
        {
          arguments[i+2] = execute_rec( ((FSCNKeywordMessage *)node)->arguments[i], localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr );
        }
      }
      
      *errorFirstCharIndexPtr = codeNode->firstCharIndex; 
      *errorLastCharIndexPtr  = codeNode->lastCharIndex;
      
      if (node->receiver->nodeType == SUPER )
      {
        NSString *className  = ((FSCNSuper *)(node->receiver))->className;
        BOOL isInClassMethod = ((FSCNSuper *)(node->receiver))->isInClassMethod;
        Class currentClass  = isInClassMethod ? object_getClass(NSClassFromString(className)) : NSClassFromString(className);
        if (currentClass == nil) FSExecError([NSString stringWithFormat:@"class \"%@\" not linked", className]);
        else ancestorToStartWith = [currentClass superclass];
      }
      else ancestorToStartWith = nil;
     
      @try
      { 
        res_msg = sendMsg(arguments[0], node->selector, argumentCount+2, arguments, node->pattern, node->msgContext, ancestorToStartWith);                                                
      }
      @finally
      {
        if (node->selector == @selector(dealloc) && !FSIsIgnoredSelector(node->selector) && (node->receiver->nodeType == IDENTIFIER || node->receiver->nodeType == SUPER))
          [localSymbolTable didSendDeallocToSymbolAtIndex:((FSCNIdentifier *)(node->receiver))->locationInContext];
      }    

      return res_msg;
    }
    @finally 
    {
      free(arguments);
    }        
  }
  
  case MESSAGE: FSExecError(@"Internal error. Compiled code node with a type of \"MESSAGE\" provided for execution.");
  
  case NUMBER:  FSExecError(@"Internal error. Compiled code node with a type of \"NUMBER\" provided for execution."); 
  
  case METHOD:  FSExecError(@"Internal error. Compiled code node with a type of \"METHOD\" provided for execution.");
  
  case CASCADE:
  {
    res_msg = nil; // To avoid a warning "might be used uninitialized"
    Class ancestorToStartWith;
    
    FSCNBase *receiverNode = ((FSCNCascade*)codeNode)->receiver;
    receiver = execute_rec(receiverNode, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
    
    if ( receiverNode->nodeType == SUPER )
    {
      NSString *className = ((FSCNSuper *)receiverNode)->className;
      Class currentClass  = NSClassFromString(className);
      if (currentClass == nil) FSExecError([NSString stringWithFormat:@"class \"%@\" not linked", className]);
      else ancestorToStartWith = [currentClass superclass];
    }
    else ancestorToStartWith = nil;
    
    for (NSUInteger j = 0; j < ((FSCNCascade*)codeNode)->messageCount ; j++)
    {   
      // code equivalent to the code in the (UNARY_MESSAGE, BINARY_MESSAGE, KEYWORD_MESSAGE) case
    
      NSUInteger argumentCount;
      FSCNMessage *messageNode = ((FSCNCascade*)codeNode)->messages[j];
      
      if (messageNode->nodeType == UNARY_MESSAGE)
      {
        argumentCount = 0;
        if (messageNode->selector == @selector(release) && (messageNode->receiver->nodeType == IDENTIFIER || messageNode->receiver->nodeType == SUPER))
          [localSymbolTable willSendReleaseToSymbolAtIndex:((FSCNIdentifier *)(messageNode->receiver))->locationInContext];
      }
      else if (messageNode->nodeType == BINARY_MESSAGE) 
        argumentCount = 1;
      else                                              
        argumentCount = ((FSCNKeywordMessage *)messageNode)->argumentCount;
          
      id *arguments = NSAllocateCollectable(sizeof(id) * (argumentCount+2) , NSScannedOption | NSCollectorDisabledOption);
      
      @try
      {
        arguments[0] = receiver;
        arguments[1] = (id)(messageNode->selector);

        if      (messageNode->nodeType == BINARY_MESSAGE) arguments[2] = execute_rec( ((FSCNBinaryMessage *)messageNode)->argument, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
        else if (messageNode->nodeType == KEYWORD_MESSAGE)
        {
          for (i = 0; i < argumentCount; i++) 
          {
            arguments[i+2] = execute_rec( ((FSCNKeywordMessage *)messageNode)->arguments[i], localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr );
          }
        }
        
        *errorFirstCharIndexPtr = messageNode->firstCharIndex; 
        *errorLastCharIndexPtr  = messageNode->lastCharIndex;
                              
        @try
        {
          res_msg = sendMsg(arguments[0], messageNode->selector, argumentCount+2, arguments, messageNode->pattern, messageNode->msgContext, ancestorToStartWith);
        }
        @finally
        {
          if (messageNode->selector == @selector(dealloc) && !FSIsIgnoredSelector(messageNode->selector) && (messageNode->receiver->nodeType == IDENTIFIER || messageNode->receiver->nodeType == SUPER))
            [localSymbolTable didSendDeallocToSymbolAtIndex:((FSCNIdentifier *)(messageNode->receiver))->locationInContext];
        }    
      }
      @finally 
      {
        free(arguments);
      }                                                  
    }
    
    return res_msg;
  }
                  
  case BLOCK:
    return [((FSCNBlock *)codeNode)->blockRep newBlockWithParentSymbolTable:localSymbolTable];
  
  case OBJECT:
    return ((FSCNPrecomputedObject *)codeNode)->object; 
    
  case ASSIGNMENT:
  {
    id rvalue = execute_rec( ((FSCNAssignment *)codeNode)->right, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);   
    assign( ((FSCNAssignment *)codeNode)->left, rvalue, localSymbolTable );
    return fsVoid;
  }        
              
  case ARRAY:
  {
    FSCNArray *node = (FSCNArray *)codeNode;
    FSArray *r = [FSArray arrayWithCapacity:node->count];
    for (i = 0; i < node->count; i++)
      [r addObject:execute_rec(node->elements[i], localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr)];       
    return r;
  }         
    
  case DICTIONARY:
  {
    FSCNDictionary *node = (FSCNDictionary *)codeNode;
    NSMutableDictionary *r = [NSMutableDictionary dictionaryWithCapacity:node->count];
    
    for (i = 0; i < node->count; i++)
    {
      id entry = execute_rec(node->entries[i], localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
      
      *errorFirstCharIndexPtr = node->entries[i]->firstCharIndex; 
      *errorLastCharIndexPtr  = node->entries[i]->lastCharIndex;
      
      if (![entry isKindOfClass:[FSAssociation class]])
      {
        FSExecError([NSString stringWithFormat:@"object provided to specify entry %lu of dictionary is %@. An instance of FSAssociation was expected", (unsigned long)(i+1), descriptionForFSMessage(entry)]);
      }
      else
      {
        id key   = [entry key];
        id value = [entry value];
      
        if (key == nil)
        {
          FSExecError([NSString stringWithFormat:@"key for dictionary entry %lu is nil. nil must not be used in dictionaries", (unsigned long)(i+1)]);
        }
        else if (value == nil)
        {
          FSExecError([NSString stringWithFormat:@"value for dictionary entry %lu is nil. nil must not be used in dictionaries", (unsigned long)(i+1)]);
        }
        else if (![key respondsToSelector:@selector(copyWithZone:)])
        {
          FSExecError([NSString stringWithFormat:@"key for dictionary entry %lu does not respond to copyWithZone:", (unsigned long)(i+1)]);
        }
        else
        {
          [r setObject:value forKey:key];       
        }
      }  
    }
    return r;
  }   
    
  case STATEMENT_LIST:
  {
    id r = nil; // to avoid a compiler warning "might be used uninitialized" 
        
    for (i = 0; i < ((FSCNStatementList *)codeNode)->statementCount ; i++)
    {
      r = execute_rec(((FSCNStatementList *)codeNode)->statements[i], localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
    }
          
    return r;
  }
  
  case RETURN :
  {
    id result = execute_rec(((FSCNReturn *)codeNode)->expression, localSymbolTable, errorFirstCharIndexPtr, errorLastCharIndexPtr);
    @throw [FSReturnSignal returnSignalWithSymbolTable:localSymbolTable result:result];
  }        
  case TEST_ABORT :
    break;  
  
  case CLASS_DEFINITION :
  {
    FSCNClassDefinition *node           = (FSCNClassDefinition *)codeNode;
    NSString            *className      = node->className;
    NSString            *superclassName = node->superclassName;
    Class class, superclass;
    BOOL redefinition = NO;
    
    *errorFirstCharIndexPtr = node->firstCharIndex; 
    *errorLastCharIndexPtr  = node->lastCharIndex;
    
    if (superclassName == nil) superclass = Nil; // We are defining a root class
    else
    {
      superclass = NSClassFromString(superclassName);
      if (superclass == nil) FSExecError([NSString stringWithFormat:@"undefined class \"%@\" ", superclassName]);
    }
    
    // We check that the new class definition does not shadow inherited instance variables/class instance variables
    // Note that these checks do not prevent shadowing when redefining a class that has suclasses: a new variable 
    // in the class might already exists in one of its subclasses
    checkNoShadowingOfInheritedIvars(className, node->ivarNames,  superclass);
    checkNoShadowingOfInheritedIvars(className, node->civarNames, object_getClass(superclass));
    
    class = NSClassFromString(className);
    
    if (class)
    {
      // This is a redefinition of an existing class
      
      redefinition = YES;
      
      if      (!fscript_isFScriptClass(class))   FSExecError([NSString stringWithFormat:@"can't redefine the Objective-C class \"%@\" ", className]);
      else if ([class superclass] != superclass) 
      {
        FSExecError([NSString stringWithFormat:@"can't change the superclass of class \"%@\" ", className]);
      }
    }
    else
    {
      // This is a definition of new class
      class = objc_allocateClassPair(superclass, [className cStringUsingEncoding:NSASCIIStringEncoding], 0);   
      
      if (class == nil) FSExecError([NSString stringWithFormat:@"class \"%@\" can't be created", className]);
                  
      fscript_registerFScriptClassPair(class);
    }

    //--------------------- We need an F-Script dealloc method to take control upon deallocation in order to release the resources holding the F-Script dynamic instance variables associated to the object
    if (!fscript_isFScriptClass(superclass) && !FSIsIgnoredSelector(@selector(dealloc)))
    {
      BOOL ok = [[FSCompiler dummyDeallocMethodForClassNamed:className] addToClass:class];
      if (!ok) FSExecError([NSString stringWithFormat:@"F-Script internal error: can't add method \"dealloc\" to class %@", className]);
    }
    //--------------------------------------------------------------------------------
        
    addMethodsToClass(node->methods, class);
    
    fscript_setDynamicIvarNames(class, [NSSet setWithArray:node->ivarNames]);
    fscript_setDynamicIvarNames(object_getClass(class), [NSSet setWithArray:node->civarNames]);
    
    if (!redefinition)
      objc_registerClassPair(class); // This call is made after the class is set up because we might have defined an +initialize method 
                                     // and we don't want the ObjC run-time to call it before we add it to the class
#if !TARGET_OS_IPHONE
    [FScriptTextView registerClassNameForCompletion:className];
#endif
    return class;  
  }
  
  case CATEGORY:
  {
    FSCNCategory *node = (FSCNCategory *)codeNode;
    Class class = NSClassFromString(node->className);   
    if (class == nil) FSExecError([NSString stringWithFormat:@"class \"%@\" not found", node->className]);

    addMethodsToClass(node->methods, class);
    
    return [FSVoid fsVoid];
  }
  
  } // end_switch

  assert(0);
  return nil; // W
}
#pragma clang diagnostic pop
#endif // not __clang_analyzer__