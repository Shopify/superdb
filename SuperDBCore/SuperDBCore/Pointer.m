/*   Pointer.m Copyright (c) 2002-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import "PointerPrivate.h"
#import "FScriptFunctions.h"
#import "FSMiscTools.h"
#import "FSNumber.h"
#import "FSBooleanPrivate.h"
#import "FSBlock.h"
#import "NumberPrivate.h"
#import "FSCompiler.h"

@implementation Pointer

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    [FSBoolean initialize]; // fsTrue, fsFalse
    tooLate = YES;
  }
}

+ (Pointer *) pointerWithCPointer:(void *)p type:(const char *)t 
{ 
  return [[[self alloc] initWithCPointer:p type:t] autorelease]; 
}

- (id)copyWithZone:(NSZone *)zone { return [self retain]; }

- (void *)cPointer { return cPointer; }  

- (void) dealloc {/*NSLog(@"Pointer dealloc");*/ free(type); [super dealloc];}

- (NSString *)description { return [NSString stringWithFormat:@"Pointer to %p, type = %s", cPointer, type]; }

- (NSUInteger)hash { return (NSUInteger)cPointer; }

- (Pointer *) initWithCPointer:(void *)p type:(const char *)t 
{
  if (self = [super init])
  {
    type = malloc(strlen(t)+1);
    strcpy(type,t); 
    cPointer = p;
    fsEncodedType = FSEncode(type);
    return self;
  }
  return nil;
}

- (BOOL) isEqual:anObject
{
  if ([anObject isKindOfClass:[Pointer class]]) 
    return (cPointer == [anObject cPointer] && strcmp(type,((Pointer *)anObject)->type) == 0);
  else 
    return NO;
}

- (char *) pointerType
{
  return type;
}

/*-(int)intValue
{return *(int *)cPointer;}*/

/////////////////////////// USER METHODS ////////////////////////////

+ (Pointer*)malloc:(size_t)size
{
  void *p = malloc(size);
  
  if (p) return [self pointerWithCPointer:p type:"v"];
  else   return nil; 
}

- (Pointer *) asPointerForType:(NSString *)theType
{
  return [Pointer pointerWithCPointer:cPointer type:[theType UTF8String]];
}

- (id)at:(id)i
{
  double indexDoubleValue;
  NSUInteger index;
  FSVerifClassArgsNoNil(@"at:",1,i,NSNumberClass);
  
  indexDoubleValue = [i doubleValue];
  index = indexDoubleValue;
  
  if (indexDoubleValue < 0)      FSExecError(@"argument of method at: must be a number greater or equal to 0");
  if (indexDoubleValue != index) FSExecError(@"argument of method at: must be an integer");    
  
  switch (fsEncodedType) 
  {
  case '@':  return ((id *)cPointer)[index];
  case '#':  return ((Class *)cPointer)[index];
  case 'c':  return [FSNumber numberWithDouble:((char *)cPointer)[index]];
  case 'B':  return (((_Bool *)cPointer)[index] ?  (id)fsTrue: (id)fsFalse); 
  case 'i':  return [FSNumber numberWithDouble:((int *)cPointer)[index]];
  case 's':  return [FSNumber numberWithDouble:((short *)cPointer)[index]];  
  case 'l':  return [FSNumber numberWithDouble:((long *)cPointer)[index]];
  case 'C':  return [FSNumber numberWithDouble:((unsigned char *)cPointer)[index]];
  case 'I':  return [FSNumber numberWithDouble:((unsigned int *)cPointer)[index]];
  case 'S':  return [FSNumber numberWithDouble:((unsigned short *)cPointer)[index]];
  case 'L':  return [FSNumber numberWithDouble:((unsigned long *)cPointer)[index]];
  case 'f':  return [FSNumber numberWithDouble:((float *)cPointer)[index]];
  case 'd':  return [FSNumber numberWithDouble:((double *)cPointer)[index]];
  case 'q':  return [NSNumber numberWithLongLong:((long long *)cPointer)[index]];
  case 'Q':  return [NSNumber numberWithDouble:((unsigned long long *)cPointer)[index]];
             //******************
             // The folowing would be better but NSNumber support for unsigned types is broken (at least in Mac OS X 10.3)
             // return [NSNumber numberWithUnsignedLongLong:((unsigned long long *)cPointer)[index]]; 
             //******************
  
  case '*':  { char *p = ((char **)cPointer)[index]; return (p ? [Pointer pointerWithCPointer:p type:"c"] : nil ); }
  case ':':  return [FSBlock blockWithSelector:((SEL *)cPointer)[index]];
  case fscode_NSRange: return [NSValue valueWithRange:((NSRange *)cPointer)[index]];
#if !TARGET_OS_IPHONE
  case fscode_NSPoint: return [NSValue valueWithPoint:((NSPoint *)cPointer)[index]];
  case fscode_NSSize:  return [NSValue valueWithSize: ((NSSize *) cPointer)[index]];
  case fscode_NSRect:  return [NSValue valueWithRect: ((NSRect *) cPointer)[index]];
#endif
  case '^':  { void *p = ((void **)cPointer)[index]; return (p ? [Pointer pointerWithCPointer:p type:type+1] : nil ); } 
  case 'v':  FSExecError(@"dereferencing \"void *\" pointer");
  default:   FSExecError(@"can't dereference pointer: the type of the referenced data is not supported by F-Script");
  }   
}

#define MAP_ELEM(TYPE,MIN,MAX,CLASS_STR) {double d; if (![elem isKindOfClass:NSNumberClass]) FSArgumentError(elem,2,CLASS_STR,@"at:put:"); d = [elem doubleValue]; if (d < MIN  || d > MAX) FSExecError([NSString stringWithFormat:@"argument 2 of method at:put: has a value of %g. Expected value must be in the range [%.15g, %.15g].",d,(double)MIN,(double)MAX]); ((TYPE *)cPointer)[index] = d; return elem;}

- (id)at:(id)i put:(id)elem
{
  double indexDoubleValue;
  NSUInteger index;
  
  FSVerifClassArgsNoNil(@"at:put:",1,i,NSNumberClass);
    
  indexDoubleValue = [i doubleValue];
  index = indexDoubleValue;
  
  if (indexDoubleValue < 0)      FSExecError(@"argument 1 of method at:put: must be a number greater or equal to 0");
  if (indexDoubleValue != index) FSExecError(@"argument 1 of method at:put: must be an integer");    
  
  switch (fsEncodedType) 
  {
  case '@':  
    ((id *)cPointer)[index] = elem; 
    return elem;
    
  case '#':
    if (elem == nil || [elem class] == elem)
    {
      ((Class *)cPointer)[index] = elem; 
      return elem;
    }
    else FSExecError(@"argument 2 of method at:put: must be a class"); 
    
  case 'c':  
    if      (elem == fsTrue)                         ((char *)cPointer)[index] = YES;
    else if (elem == fsFalse)                        ((char *)cPointer)[index] = NO;
    else if ([elem isKindOfClass:[FSBoolean class]]) ((char *)cPointer)[index] = [elem isTrue];
    
    //*************
    // The current Cocoa implementation return the same encoding for char * and unsigned char *.
    // Thus, we can only check for [CHAR_MIN, UCHAR_MAX] instead of a more restrictive range.
    else MAP_ELEM(char,CHAR_MIN,UCHAR_MAX,@"NSNumber or FSBoolean")
    //else MAP_ELEM(char,CHAR_MIN,CHAR_MAX,@"NSNumber or FSBoolean")
    //*************
  
    return elem;
    
  case 'B':  
    if      (elem == fsTrue)                         ((_Bool *)cPointer)[index] = YES;
    else if (elem == fsFalse)                        ((_Bool *)cPointer)[index] = NO;
    else if ([elem isKindOfClass:[FSBoolean class]]) ((_Bool *)cPointer)[index] = [elem isTrue];
    else  FSExecError(@"argument 2 of method at:put: must be an instance of FSBoolean");
    return elem;

  case 'S': 
    if ([elem isKindOfClass:[NSString class]])
    {
      if ([(NSString *)elem length] == 1)
      {
        ((unsigned short *)cPointer)[index] = [elem characterAtIndex:0];
        return elem;
      }
      else FSExecError(@"argument 2 of method at:put: must be a one character NSString or an instance of NSNumber");
    }
    else MAP_ELEM(unsigned short,0,USHRT_MAX,@"NSNumber or a one character NSString")

  case 'i':  MAP_ELEM(int          , INT_MIN , INT_MAX ,   @"NSNumber")
  case 's':  MAP_ELEM(short        , SHRT_MIN, SHRT_MAX,   @"NSNumber")
  case 'l':  MAP_ELEM(long         , LONG_MIN, LONG_MAX,   @"NSNumber")
  case 'C':  MAP_ELEM(unsigned char, 0       , UCHAR_MAX , @"NSNumber")
  case 'I':  MAP_ELEM(unsigned int , 0       , UINT_MAX  , @"NSNumber")
  case 'L':  MAP_ELEM(unsigned long, 0       , LONG_MAX  , @"NSNumber")
  case 'f':  MAP_ELEM(float        , -FLT_MAX, FLT_MAX   , @"NSNumber") 
  case 'd':  MAP_ELEM(double       , -DBL_MAX, DBL_MAX  , @"NSNumber") 

  case 'q':
  {
    if (![elem isKindOfClass:NSNumberClass]) FSArgumentError(elem,2,@"NSNumber",@"at:put:");
    
    char objCType = [elem objCType][0];
    
    if (objCType == 'Q' && [elem unsignedLongLongValue] > LLONG_MAX)
      FSExecError([NSString stringWithFormat:@"argument 2 of method at:put: has a value of %llu. Expected value must be in the range [%lld, %lld].",[elem unsignedLongLongValue],LLONG_MIN,LLONG_MAX]);
    else if (objCType == 'q' || objCType == 'Q')
      ((long long *)cPointer)[index] = [elem longLongValue];
    else
    {
      double d = [elem doubleValue]; 
      if (d <= LLONG_MIN  || d >= LLONG_MAX) // In order to avoid an edge case where LLONG_MAX (or LLONG_MIN) would be converted (by the compiler, for performing the comparison) to a biggest (in absolute value) double value that would happend to be equal to d (which would lead to an overflow on the (1) instruction ), we exclude LLONG_MAX and LLONG_MIN from the acceptable range.
        FSExecError([NSString stringWithFormat:@"argument 2 of method at:put:, which has a value of %g, is too big (in absolute value)",d]); 
      ((long long *)cPointer)[index] = d; //(1)
    }
    return elem;
  }
  
  case 'Q':
  { 
    if (![elem isKindOfClass:NSNumberClass]) FSArgumentError(elem,2,@"NSNumber",@"at:put:");
    
    char objCType = [elem objCType][0];
    
    if (objCType == 'q' && [elem longLongValue] < 0)
      FSExecError([NSString stringWithFormat:@"argument 2 of method at:put: has a value of %lld. Expected value must be in the range [0, %llu].",[elem longLongValue],ULLONG_MAX]);
    else if (objCType == 'q' || objCType == 'Q')
      ((unsigned long long *)cPointer)[index] = [elem unsignedLongLongValue];
    else
    {
      double d = [elem doubleValue]; 
      if (d < 0)
        FSExecError([NSString stringWithFormat:@"argument 2 of method at:put: has a value of %g. Expected value must be in the range [0, %llu].",d,ULLONG_MAX]);
      else if (d >= ULLONG_MAX) // In order to avoid an edge case where ULLONG_MAX would be converted (by the compiler, for performing the comparison) to a biggest  double value that would happend to be equal to d (which would lead to an overflow on the (2) instruction ), we exclude ULLONG_MAX from the acceptable range.
        FSExecError([NSString stringWithFormat:@"argument 2 of method at:put:, which has a value of %g, is too big",d]); 
      ((unsigned long long *)cPointer)[index] = d; // (2)
    }
    return elem;
  }

  case '*':
    if      (elem == nil)                          ((char **)cPointer)[index] = NULL; 
    else if ([elem isKindOfClass:[Pointer class]]) ((char **)cPointer)[index] = [elem cPointer]; 
    else FSArgumentError(elem,2,@"Pointer",@"at:put:"); 
    return elem;
    
  case ':': 
  {
    SEL selector;
    
    if (![elem isKindOfClass:[FSBlock class]]) FSArgumentError(elem,2,@"FSBlock",@"at:put:");
    if (![elem isCompact]) FSExecError(@"argument 2 of method at:put: must be a compact block");
    if (!(selector = [elem selector])) selector = [FSCompiler selectorFromString:[elem selectorStr]];
    ((SEL *)cPointer)[index] = selector;
    return elem;
  }
      
  case fscode_NSRange: 
    if ([elem isKindOfClass:[NSValue class]] && strcmp([elem objCType],@encode(NSRange)) == 0)
    {
      ((NSRange *)cPointer)[index] = [elem rangeValue];
      return elem;
    }
    else FSArgumentError(elem,2,@"NSValue containing an NSRange",@"at:put:");
#if !TARGET_OS_IPHONE
  case fscode_NSPoint:
    if ([elem isKindOfClass:[NSValue class]] && strcmp([elem objCType],@encode(NSPoint)) == 0)
    {
      ((NSPoint *)cPointer)[index] = [elem pointValue];
      return elem;
    }
    else FSArgumentError(elem,2,@"NSValue containing an NSPoint",@"at:put:");
      
  case fscode_NSSize:  
    if ([elem isKindOfClass:[NSValue class]] && strcmp([elem objCType],@encode(NSSize)) == 0)
    {
      ((NSSize *)cPointer)[index] = [elem sizeValue];
      return elem;
    }
    else FSArgumentError(elem,2,@"NSValue containing an NSSize",@"at:put:");
  
  case fscode_NSRect:  
    if ([elem isKindOfClass:[NSValue class]] && strcmp([elem objCType],@encode(NSRect)) == 0)
    {
      ((NSRect *)cPointer)[index] = [elem rectValue];
      return elem;
    }
    else FSArgumentError(elem,2,@"NSValue containing an NSRect",@"at:put:");
#endif  
  case '^':  
    if      (elem == nil)                          ((void **)cPointer)[index] = NULL; 
    else if ([elem isKindOfClass:[Pointer class]]) ((void **)cPointer)[index] = [elem cPointer]; 
    else FSArgumentError(elem,2,@"Pointer",@"at:put:"); 
    return elem;
  
  case 'v':  FSExecError(@"dereferencing \"void *\" pointer");

  default: FSExecError(@"can't dereference pointer: the type of the referenced data is not supported by F-Script");
  }   
}

- (id)clone { return  [[self copy] autorelease];}

- (void)free { free(cPointer); }

@end
