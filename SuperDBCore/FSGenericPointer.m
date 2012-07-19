/*   FSGenericPointer.m Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.    */  

#import "FSGenericPointer.h"
#import "FSGenericPointerPrivate.h"
#import "FSMiscTools.h"
#import "FSPointerPrivate.h"
#import "FScriptFunctions.h"
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
#import "FSBlock.h" 
#import "FSCompiler.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "FSExecEngine.h"
#import "FSArray.h"



/* 
char *FSGenericPointer_type(FSGenericPointer *s)  // Would have been simpler to implement as a method, but here I want to experiment about not poluting the method's space of user objects
{
if (s == nil) return nil;

#ifdef __LP64__
  void *typePtr;
  
  object_getInstanceVariable(s, "type", &typePtr);
  return *(char **)typePtr;
#else
  
  struct FSGenericPointerDef {@defs(FSGenericPointer)} *self = (struct FSGenericPointerDef *)s;
  return self->type;
#endif
}
*/ 

@implementation FSGenericPointer

- (id)at:(id)i
{
  FSPointer_validateDereferencingWithSelector_index(self, _cmd, i);
  
  if (freed) FSExecError(@"Can't dereference a freed pointer");

  NSUInteger index = [i unsignedIntegerValue];

  switch (fsEncodedType) 
  {
    case 'c': return [FSNumber numberWithDouble:((char *)cPointer)[index]];
    case 'v': FSExecError(@"can't dereference \"void *\" pointer");
    default: return FSMapToObject(cPointer, index, fsEncodedType, type, @"can't dereference pointer: the type of the referenced data is not supported by F-Script", nil);
  }
}

#define MAP_ELEM(TYPE,MIN,MAX,CLASS_STR) {double d; if (![elem isKindOfClass:NSNumberClass]) FSArgumentError(elem,2,CLASS_STR,@"at:put:"); d = [elem doubleValue]; if (d < MIN  || d > MAX) FSExecError([NSString stringWithFormat:@"argument 2 of method at:put: has a value of %g. Expected value must be in the range [%.15g, %.15g].",d,(double)MIN,(double)MAX]); ((TYPE *)cPointer)[index] = d; return elem;}

- (id)at:(id)i put:(id)elem
{
  FSPointer_validateDereferencingWithSelector_index(self, _cmd, i);
  if (freed) FSExecError(@"Can't dereference a freed pointer");
  
  size_t index = [i doubleValue];
  
  switch (fsEncodedType) 
  {   
  case 'c':  
    if      (elem == fsTrue)                         ((char *)cPointer)[index] = YES;
    else if (elem == fsFalse)                        ((char *)cPointer)[index] = NO;
    else if ([elem isKindOfClass:[FSBoolean class]]) ((char *)cPointer)[index] = [elem isTrue];
    
    // *************
    // The current Cocoa implementation (10.4, 10.5 dev preview) returns the same encoding for char * and unsigned char *.
    // Thus, we can only check for [CHAR_MIN, UCHAR_MAX] instead of a more restrictive range.
    else MAP_ELEM(char,CHAR_MIN,UCHAR_MAX,@"NSNumber or FSBoolean")
    //else MAP_ELEM(char,CHAR_MIN,CHAR_MAX,@"NSNumber or FSBoolean")
    // *************
    break;
  case 'v': FSExecError(@"can't dereference \"void *\" pointer");
  
  default : FSMapFromObject(cPointer, index, fsEncodedType, elem, FSMapDereferencedPointer, 2, _cmd, nil, NULL);
  }  
  
  return elem;
}


- (void) dealloc 
{
  /*NSLog(@"FSGenericPointer dealloc");*/ 
  
  if (freeWhenDone)
  {
    if (freed) NSLog(@"Illegal attempt to free an already freed memory zone pointed by an FSPointer object. This attempt took place during the deallocation of the FSPointer object.");
    else       free(cPointer);
  }
  free(type); 
  [super dealloc];
}

- (void)finalize 
{
  //NSLog(@"finalizing an FSGenericPointer");
  if (freeWhenDone)
  {
    if (freed) NSLog(@"Illegal attempt to free an already freed memory zone pointed by an FSPointer object. This attempt took place during the finalization of the FSPointer object.");
    else       free(cPointer);
  }
  free(type);
  [super finalize];
}

- (NSString *)description 
{ 
  return [NSString stringWithFormat:@"FSGenericPointer to %p, type = %s, freeWhenDone = %@", cPointer, type, freeWhenDone ? @"YES" : @"NO"]; 
}

- (void)free 
{ 
  if (freed) FSExecError(@"Method \"free\" invoked on an already freed pointer object");
  free(cPointer);
  freed = YES; 
}

-(id) initWithCPointer:(void *)p freeWhenDone:(BOOL)free type:(const char *)t  // designated initializer. t is copied.
{  
  if (self = [super initWithCPointer:p])  
  {
    freeWhenDone = free;
    freed = NO;
    type = malloc(strlen(t)+1);
    if (type)
    {
      strcpy(type,t);
      fsEncodedType = FSEncode(type);
    }
    else 
    {
      [super dealloc];
      return nil;
    }
  }
  return self;
}

- (id) initWithCPointer:(void *)p
{
  return [self initWithCPointer:p freeWhenDone:NO type:@encode(void)];
}

- (id) init
{
  return [self initWithCPointer:NULL];
}

- (NSArray *)memoryContent
{
  if (freed) return nil;
  
  size_t msize = malloc_size(cPointer);
  
  if (msize == 0) return nil;
  
  size_t itemSize;
  
  switch (fsEncodedType) 
  {
    case 'c':                      itemSize = sizeof(char);               break;
    case 'B':                      itemSize = sizeof(_Bool);              break; 
    case 'i':                      itemSize = sizeof(int);                break;
    case 's':                      itemSize = sizeof(short);              break;   
    case 'l':                      itemSize = sizeof(long);               break;
    case 'C':                      itemSize = sizeof(unsigned char);      break;
    case 'I':                      itemSize = sizeof(unsigned int);       break;
    case 'S':                      itemSize = sizeof(unsigned short);     break;
    case 'L':                      itemSize = sizeof(unsigned long);      break;
    case 'f':                      itemSize = sizeof(float);              break;
    case 'd':                      itemSize = sizeof(double);             break;
    case 'q':                      itemSize = sizeof(long long);          break;
    case 'Q':                      itemSize = sizeof(unsigned long long); break;
    case fscode_NSRange:           itemSize = sizeof(NSRange);            break;
#if !TARGET_OS_IPHONE
    case fscode_NSPoint:           itemSize = sizeof(NSPoint);            break;
    case fscode_NSSize:            itemSize = sizeof(NSSize);             break;
    case fscode_NSRect:            itemSize = sizeof(NSRect);             break;
#endif
    case fscode_CGPoint:           itemSize = sizeof(CGPoint);            break;
    case fscode_CGSize:            itemSize = sizeof(CGSize);             break;
    case fscode_CGRect:            itemSize = sizeof(CGRect);             break;
    case fscode_CGAffineTransform: itemSize = sizeof(CGAffineTransform);  break;
    default:                       itemSize = 0;
  }   

  if (itemSize == 0) return nil;
  
  NSUInteger count = msize/itemSize;
  
  if (count > 20000) return nil; // The current method is invoked by the BB to display memory content. We don't want to compute and display things too big, for usability and performance reasons.
  
  FSArray *r = [FSArray arrayWithCapacity:count];
  
  for (NSUInteger i = 0; i < count; i++) [r addObject:[self at:[FSNumber numberWithDouble:i]]];
  
  return r;
}

- (NSString *)memoryContentUTF8
{
  NSUInteger i;
   
  if (freed) return nil;
  
  size_t msize = malloc_size(cPointer);
  
  if (msize == 0) return nil;
    
  if (fsEncodedType != 'c') return nil;
     
  for (i = 0; i < msize && ((char *)cPointer)[i] != '\0'; i++);

  if (i > 20000) return nil; // The current method is invoked by the BB to display memory content. We don't want to compute and display things too big, for performance reasons.
  
  if (i < msize) return [NSString stringWithUTF8String:cPointer];
  else           return nil;
}

- (void) setFreeWhenDone:(BOOL)fr
{
  freeWhenDone = fr;
}

- (void) setType:(NSString *)theType
{
  const char *t  = [theType UTF8String];
  free(type);
  type = malloc(strlen(t)+1);
  if (type == NULL) FSExecError(@"Not enough memory");
  strcpy(type,t); 
  fsEncodedType = FSEncode(type);
}

@end
