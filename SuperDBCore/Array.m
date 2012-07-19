/*   Array.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "Array_fscript.h"    
#import "ArrayPrivate.h"
#import "ArrayRepId.h"
#import "FScriptFunctions.h"
#import <Foundation/Foundation.h>
#import "FSCompiler.h"
#import "FSVoid.h" 
#if TARGET_OS_IPHONE
# import <objc/runtime.h>
#else
# import <objc/objc-runtime.h>
#endif 
#import "FSBlock.h"
#import "FSExecEngine.h"
#import "FSPattern.h"
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "ArrayRepDouble.h"
#import "ArrayRepEmpty.h"
#import "ArrayRepBoolean.h"
#import "FSBooleanPrivate.h"
#import "FSMiscTools.h"
#import "FSNSArrayPrivate.h"
#import "FSArrayEnumerator.h"
#import "FSNSMutableArray.h"
#import "FSReplacementForCoderForNilInArray.h"

@interface Array(ArrayPrivateInternal)
- (void) addObjectsFromFSArray:(Array *)otherArray;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- (enum ArrayRepType)type;
- (Array *)initWithRep:(id)theRep;
@end


/*static int comp_unsigned_int(const void *a,const void *b)
{
  if (*(unsigned int *)a == *(unsigned int *)b)
    return 0;
  else if (*(unsigned int *)a) < *(unsigned int *)b)
    return -1;
  else
    return 1;
} */

/*static int compEq(const void *a,const void *b)
{
  if      ( [*(id *)a operator_less: *(id *)b] == fsTrue) return -1; 
  else if ( [*(id *)b operator_less: *(id *)a] == fsTrue) return  1;
  else                                                      return  0;   
}
*/

@implementation Array

///////////////////////////////////// USER METHODS  

- (id)at:(id)index put:(id)elem  
{ 
  assert(0);
}

- (Array *) distinctId
{
  assert(0);
}

- (BOOL) isEqual:(id)anObject
{
  assert(0);
}

- (Array *)replicate:(NSArray *)operand
{
  assert(0);
}

- (Array *)reverse
{ 
  assert(0);
}    

- (Array *)rotatedBy:(NSNumber *)operand
{
  assert(0);
}  

- (Array *)sort 
{
  assert(0);
}


///////////////////////////////////////////////////////////////////////////
//////////////////////////////////// OTHER METHODS ////////////////////////
///////////////////////////////////////////////////////////////////////////

+ (id)alloc
{
  return [self allocWithZone:nil];
}

+ (id)allocWithZone:(NSZone *)zone
{
  return (id)[FSArray allocWithZone:zone];
}

+ (id)arrayWithObject:(id)anObject
{
  return [[[Array alloc] initWithObject:anObject] autorelease];
}
 
+ (id)arrayWithObjects:(id *)objects count:(NSUInteger)count
{
  return [[[Array alloc] initWithObjects:objects count:count] autorelease];
}

+ (Array *)arrayWithRep:(id)theRep
{ 
  return [[[Array alloc] initWithRep:theRep] autorelease];
}
 
+ (double) maxCount 
{ 
  return [FSArray maxCount];
}

typedef struct fs_objc_object {
        Class isa;
} *fso;

- (void)addObject:(id)anObject
{
  assert(0);
}

- (void)addObjectsFromFSArray:(Array *)otherArray
{
  assert(0);
}

- (NSArray *)arrayByAddingObject:(id)anObject
{
  assert(0);
}

- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray
{
  assert(0);
}

- (id)arrayRep { assert(0); } 


- (NSString *)componentsJoinedByString:(NSString *)separator
{
  assert(0);
}

- (BOOL)containsObject:(id)anObject
{
  assert(0);
}

- copy  {  assert(0);  }

- copyWithZone:(NSZone *)zone  {   assert(0);   }

- (NSUInteger)count 
{
  assert(0);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)statep objects:(id *)stackbuf count:(NSUInteger)len
{
  assert(0);
}

- (NSString *)descriptionLimited:(NSUInteger)nbElem 
{
  assert(0);
}

- (NSString *)description 
{
  assert(0);
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale
{
  assert(0);
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level
{
  assert(0);
}
  
- (void *)dataPtr
{
  assert(0);
}  
  

/*- (void)getObjects:(id *)aBuffer
{
  return [self getObjects:aBuffer range:NSMakeRange(0,[self count])];
}

- (void)getObjects:(id *)aBuffer range:(NSRange)range
{  
  unsigned i, end;
  
  if (range.location + range.length > [self count] || range.location == [self count]) 
    [NSException raise:NSRangeException format:@"*** -[%@ getObjects:range:]: index (%d) beyond bounds (%d)",[self class],range.location + range.length - 1, [self count]];
  
  if (range.length == 0) return;
  
  for (i = range.location, end = (range.location + range.length - 1); i <= end; i++)
    aBuffer[i] = [self objectAtIndex:i];
}*/


- (id)firstObjectCommonWithArray:(NSArray *)otherArray
{
  assert(0);
}

- (NSUInteger)indexOfObject:(id)anObject
{
  assert(0);
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range
{
  assert(0);
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical
{   
  assert(0);
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject
{
  assert(0);
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range
{   
  assert(0);
}

- init
{
  assert(0);
}   

- initFrom:(NSUInteger)from to:(NSUInteger)to step:(NSUInteger)step
{
  assert(0);
}           

- initFilledWith:(id)elem count:(NSUInteger)nb
{
  assert(0);
} 

- initWithCapacity:(NSUInteger)aNumItems
{
  assert(0);
}

- initWithObject:(id)object
{
  assert(0);
}

- initWithObjects:(id *)objects count:(NSUInteger)nb
{
  assert(0);
}
    
- (Array *)initWithRep:(id)theRep
{
  assert(0);
}

- (Array *)initWithRepNoRetain:(id)theRep  //designated initializer
{
  assert(0);
}
             
- (void)insertObject:anObject atIndex:(NSUInteger)index
{
  assert(0);
}    
    
- (BOOL) isEqualToArray:(NSArray *)anArray
{
  assert(0);
}
        
- mutableCopyWithZone:(NSZone *)zone 
{ 
  assert(0);
}
    
- objectAtIndex:(NSUInteger)index
{
  assert(0);
}   

- (NSEnumerator *)objectEnumerator
{
  assert(0);
}

- (void)removeLastObject 
{
  assert(0);
}

- (void)removeObjectAtIndex:(NSUInteger)index 
{
  assert(0);
}  

- (id)replacementObjectForCoder:(NSCoder *)aCoder
{
  assert(0);
}

#if !TARGET_OS_IPHONE
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder 
// Overhide the NSArray behavior (which is to pass arrays by copy by default), with a by reference behavior by default. 
// This is because passing an object by copy only works if the receiving process is linked with the class of the object.
// In our case, we want to support passing Arrays to applications that are not linked with the F-Script framework. 
{
  assert(0);
}
#endif

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  assert(0);
}  

- (id)retain  {  assert(0); }

- (NSUInteger)retainCount  {   assert(0); }

- (void)release  {   assert(0); }  

- (NSEnumerator *)reverseObjectEnumerator
{
  assert(0);
}

- (void)setArray:(NSArray *)operand
{
  assert(0);
}  

 
- (NSArray *)subarrayWithRange:(NSRange)range
{
  assert(0);
}
 
- (enum ArrayRepType)type  {   assert(0);   } // declared in ArrayPrivate

///////////////////////////////// PRIVATE FOR USE BY FSExecEngine ///////////////

-(NSUInteger) _ul_count {   assert(0);   }
 
- _ul_objectAtIndex:(NSUInteger)index
{ 
  assert(0);
}

@end
