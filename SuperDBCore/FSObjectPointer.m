/*   FSObjectPointer.m Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.    */  

#import "FSObjectPointer.h"
#import "FSPointer.h"
#import "FSPointerPrivate.h"
#import "FScriptFunctions.h"
#import "Numberprivate.h" 
#import "FSNumber.h"
#import <objc/runtime.h>
#import "FSArray.h"

/*
void FSObjectPointer_autoreleaseAll(FSObjectPointer *s) // Would have been simpler to implement as a method, but here I want to experiment about not poluting the method's space of user objects
{
#ifdef __LP64__
  size_t *countPtr;
  if (s == nil) return;
  
  object_getInstanceVariable(s, "count", &(void*)countPtr);
  
  for (NSUInteger i = 0; i < *countPtr; i++)
  {
    [((id *)[s cPointer])[i] autorelease];  
  }
#else
  if (s == nil) return;

  struct FSObjectPointerDef {@defs(FSObjectPointer)} *self = (struct FSObjectPointerDef *)s;
  
  for (NSUInteger i = 0; i < self->count; i++)
  {
    [((id *)self->cPointer)[i] autorelease];  
  }
#endif  
}

void FSObjectPointer_retainAll(FSObjectPointer *s)  // Would have been simpler to implement as a method, but here I want to experiment about not poluting the method's space of user objects
{
#ifdef __LP64__
  void *countPtr;
  if (s == nil) return;
  
  object_getInstanceVariable(s, "count", &countPtr);
  
  for (NSUInteger i = 0; i < *(size_t *)countPtr; i++)
  {
    [((id *)[s cPointer])[i] retain];  
  }
#else
  if (s == nil) return;

  struct FSObjectPointerDef {@defs(FSObjectPointer)} *self = (struct FSObjectPointerDef *)s;
  
  for (NSUInteger i = 0; i < self->count; i++)
  {
    [((id *)self->cPointer)[i] retain];  
  }
#endif  
}
*/



@implementation FSObjectPointer

- (void) autoreleaseAll
{
  for (NSUInteger i = 0; i < count; i++)
  {
    [((id*)cPointer)[i] autorelease];  
  }
}

- (void) dealloc 
{
  for (size_t i = 0; i < count; i++) [((id *)cPointer)[i] release];  
  free(cPointer);
  [super dealloc];
}

- (NSString *)description  
{ 
  return [NSString stringWithFormat:@"FSObjectPointer to %p", cPointer]; 
}

- (id) initWithCPointer:(void *)p  count:(size_t)c // designated initializer
{
  if (self = [super initWithCPointer:p])
  {
    count = c;
  }
  return self;
} 

- (id) initWithCPointer:(void *)p 
{
  return [self initWithCPointer:p  count:0];  
} 

- (void) retainAll
{
  for (NSUInteger i = 0; i < count; i++)
  {
    [((id*)cPointer)[i] retain];  
  }
}

- (NSArray *)memoryContent
{
  if   (count <= 20000) return [FSArray arrayWithObjects:cPointer count:count]; // The current method is invoked by the BB to display memory content. We don't want to compute and display things too big, for performance reasons.
  else                  return nil;
}

/////////// User methods
 
- (id)at:(id)i
{
  FSPointer_validateDereferencingWithSelector_index(self, _cmd, i);
  
  size_t index = [i doubleValue];
  if (index >= count) [NSException raise:NSRangeException format:@"pointer dereferencing: index out of bounds in method \"at:\""];  
   
  return ((id *)cPointer)[index];
}

- (id)at:(id)i put:(id)elem
{
  FSPointer_validateDereferencingWithSelector_index(self, _cmd, i);  
  
  size_t index = [i doubleValue];
  if (index >= count) [NSException raise:NSRangeException format:@"pointer dereferencing: index out of bounds in method \"at:put:\""];  

  [elem retain];
  [((id *)cPointer)[index] release];
  ((id *)cPointer)[index] = elem;
  
  return elem;
}

@end
