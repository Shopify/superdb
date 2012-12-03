/*   FSPointer.m Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.  */  

#import "FScriptFunctions.h"
#import "FSMiscTools.h"
#import "FSNumber.h"
#import "FSBooleanPrivate.h" 
#import "FSBlock.h"
#import "NumberPrivate.h"
#import "FSCompiler.h"
#import "FSPointer.h"
#import "FSGenericPointer.h"
#import "FSGenericPointerPrivate.h"
#import "FSObjectPointer.h"
#import "FSObjectPointerPrivate.h"

void FSPointer_validateDereferencingWithSelector_index(FSPointer *s, SEL selector, id i)  // Would be simpler to implement as a method, but here I want to experiment about not poluting the method's space of user objects
{
  if (s == nil) return;

  double indexDoubleValue;
  size_t index;
  
  //struct FSPointerDef {@defs(FSPointer)} *self = (struct FSPointerDef *)s;
    
  if (i == nil || (i != nil && ![i isKindOfClass:NSNumberClass]))
    FSArgumentError(i, 1, @"NSNumber", NSStringFromSelector(selector));

  indexDoubleValue = [i doubleValue];
  index = indexDoubleValue;
  
  if (indexDoubleValue < 0)      FSExecError([NSString stringWithFormat:@"argument of method %@ must be a number greater or equal to 0", NSStringFromSelector(selector)]);
  if (indexDoubleValue != index) FSExecError([NSString stringWithFormat:@"argument of method %@ must be an integer", NSStringFromSelector(selector)]);    
}

@implementation FSPointer

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    [FSBoolean initialize]; // fsTrue, fsFalse
    tooLate = YES;
  }
}

- (id) initWithCPointer:(void *)p  // designated initializer
{
  if (self = [super init])
  {
    retainCount = 1;
    cPointer = p;
  }
  return self;
} 

- (id) init
{
  return [self initWithCPointer:NULL];
}

/*-(int)intValue
{return *(int *)cPointer;}*/

- (id)retain
{
  retainCount++;
  return self;
}

- (NSUInteger)retainCount
{
  return retainCount;
}

- (oneway void)release
{
  if (--retainCount == 0)  [self dealloc];
}


/////////////////////////// USER METHODS ////////////////////////////

+ (FSGenericPointer *) allocateCollectable:(NSUInteger)size options:(NSUInteger)options
{
  void *p = NSAllocateCollectable(size, options);
  return [[[FSGenericPointer alloc] initWithCPointer:p freeWhenDone:NO type:@encode(void)] autorelease]; 
}

+ (FSGenericPointer *) allocateCollectable:(NSUInteger)size 
{
  void *p = NSAllocateCollectable(size, 0);
  return [[[FSGenericPointer alloc] initWithCPointer:p freeWhenDone:NO type:@encode(void)] autorelease]; 
}

+ (FSGenericPointer *) malloc:(size_t)size
{
  errno = 0;
    
  void *p = malloc(size);
  
  if (errno == ENOMEM) return nil;
  else                 return [[[FSGenericPointer alloc] initWithCPointer:p freeWhenDone:NO type:@encode(void)] autorelease];
}

+ (FSObjectPointer *) objectPointer
{
  return [self objectPointer:1];
}

+ (FSObjectPointer *) objectPointer:(size_t)count
{
  id *p = NSAllocateCollectable(sizeof(id)*count, NSScannedOption);
  
  if (p)
  {
    for (size_t i = 0; i < count; i++) p[i] = nil;
    return [[[FSObjectPointer alloc] initWithCPointer:p count:count] autorelease];
  }
  else return nil;
}

- (NSNumber *) address { return [NSNumber numberWithUnsignedInteger:(NSUInteger)cPointer]; }

- (void *)cPointer { return cPointer; }  

- (BOOL)isEqual:(id)anObject
{
  return ([anObject isKindOfClass:[FSPointer class]] && [(FSPointer *)anObject cPointer] == cPointer); 
}

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

@end

