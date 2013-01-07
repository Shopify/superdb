/*   FSArray.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "FSArray.h"    
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

// ignoring these warnings until it can be fixed, for build servers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-w"

@interface FSArray(ArrayPrivateInternal)
- (void) addObjectsFromFSArray:(FSArray *)otherArray;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical;
- (enum ArrayRepType)type;
@end

void __attribute__ ((constructor)) initializeFSArray(void) 
{
  [NSKeyedUnarchiver setClass:[FSArray class] forClassName:@"Array"];
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"Array" asClassName:@"FSArray"];  
#endif
}

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

@implementation FSArray

///////////////////////////////////// USER METHODS  

- (id)at:(id)index put:(id)elem  
{ 
  if (type == FS_ID) return [(ArrayRepId *)rep at:index put:elem]; 
  else return [super at:index put:elem];
}

- (FSArray *) distinctId
{
  if   ([rep respondsToSelector:@selector(distinctId)]) return [rep distinctId];
  else {return [super distinctId];}
}

- (BOOL) isEqual:(id)anObject
{
  if ([anObject isKindOfClass:[NSArray class]]) return [self isEqualToArray:anObject];
  else                                          return NO;
}

- (FSArray *)replicate:(NSArray *)operand
{
  VERIF_OP_NSARRAY(@"replicate:");
  if ([self count] != [operand count]) FSExecError(@"receiver and argument of method \"replicate:\" must be arrays of same size");
  if ([operand isProxy]) 
  { // build a local array because replicate: of an arrayRep does not support FSArray proxy
    NSUInteger i;
    NSUInteger nb = [operand count];
    NSArray *remoteReplicationArray = operand;
      
    operand = [FSArray arrayWithCapacity:nb]; 
    for (i = 0; i < nb; i++) [(FSArray *)operand addObject:[remoteReplicationArray objectAtIndex:i]];
  } 

  if ([rep respondsToSelector:@selector(replicateWithArray:)] && [operand isKindOfClass:[FSArray class]])
    return [rep replicateWithArray:(FSArray *)operand];
  else
    return [super replicate:operand];
}

- (FSArray *)reverse
{ 
  if ([rep respondsToSelector:@selector(reverse)]) return [rep reverse];
  else                                             return [super reverse];
}    

- (FSArray *)rotatedBy:(NSNumber *)operand
{
  if ([rep respondsToSelector:@selector(rotatedBy:)]) return [rep rotatedBy:operand];
  else                                                return [super rotatedBy:operand];
}  

- (FSArray *)sort 
{
  if ([rep respondsToSelector:@selector(sort)]) return [rep sort]; 
  else                                          return [super sort];
}


///////////////////////////////////////////////////////////////////////////
//////////////////////////////////// OTHER METHODS ////////////////////////
///////////////////////////////////////////////////////////////////////////

+ (id)arrayWithObject:(id)anObject
{
  return [[[FSArray alloc] initWithObject:anObject] autorelease];
}
 
+ (id)arrayWithObjects:(id *)objects count:(NSUInteger)count
{
  return [[[FSArray alloc] initWithObjects:objects count:count] autorelease];
}

+ (FSArray *)arrayWithRep:(id)theRep
{ 
  return [[[FSArray alloc] initWithRep:theRep] autorelease];
}
 
+ (double) maxCount { return NSUIntegerMax;}

typedef struct fs_objc_object {
        Class isa;
} *fso;

- (void)addObject:(id)anObject
{
  switch (type)
  {
  case DOUBLE:
  {
    if (anObject && ((struct {Class isa;} *)anObject)->isa == FSNumberClass)   // anObject is casted to avoid the warning "static access to object of type id"
      [(ArrayRepDouble *)rep addDouble:((FSNumber *)anObject)->value ];
    else if (anObject && isNSNumberWithLosslessConversionToDouble(anObject)) 
      [(ArrayRepDouble *)rep addDouble:[(NSNumber *)anObject doubleValue]];
    else
    {                                          
      [self becomeArrayOfId]; 
      [(ArrayRepId *)rep addObject:anObject];
    }
    break;
  }
  
  case BOOLEAN:
    if      (anObject == fsFalse) [(ArrayRepBoolean *)rep addBoolean:0]; 
    else if (anObject == fsTrue)  [(ArrayRepBoolean *)rep addBoolean:1];  
    else                          {[self becomeArrayOfId]; [(ArrayRepId *)rep addObject:anObject];}
    break;
    
  case FS_ID: 
    [(ArrayRepId *)rep addObject:anObject]; 
    break;

  case EMPTY:
    if (isNSNumberWithLosslessConversionToDouble(anObject)) 
    {
      id oldRep = rep;
      rep = [[(ArrayRepEmpty *)rep asArrayRepDouble] retain];
      type = DOUBLE;
      [oldRep release];
      [(ArrayRepDouble *)rep addDouble:[(NSNumber *)anObject doubleValue]];
    }
    else if (anObject == fsTrue || anObject == fsFalse)
    {
      id oldRep = rep;
      rep = [[(ArrayRepEmpty *)rep asArrayRepBoolean] retain];
      type = BOOLEAN;
      [oldRep release];
      [(ArrayRepBoolean *)rep addBoolean:(anObject == fsTrue ? 1 : 0)];
    }
    else
    {
      [self becomeArrayOfId];
      [(ArrayRepId *)rep addObject:anObject];
    }
    break;
    
  case FETCH_REQUEST:
    [self becomeArrayOfId];
    [(ArrayRepId *)rep addObject:anObject];
    break; 
  } // end switch  
}

- (void)addObjectsFromFSArray:(FSArray *)otherArray
{
  BOOL proxy = [otherArray isProxy];
  enum ArrayRepType repType = [otherArray type];

  if      (type==FS_ID  && repType==FS_ID  && !proxy) [(ArrayRepId *)rep     addObjectsFromFSArray:otherArray];
  else if (type==DOUBLE && repType==DOUBLE && !proxy) [(ArrayRepDouble *)rep addDoublesFromFSArray:otherArray];
  else if (type==EMPTY)                               [self setValue:otherArray];
  else
  {
    NSUInteger otherArrayCount = [otherArray count];
    NSUInteger i;
    
    if (repType == FS_ID && !proxy)
    {
      id *data = [otherArray dataPtr];
      for (i = 0; i < otherArrayCount; i++) [self addObject:data[i]];
    }
    else for (i = 0; i < otherArrayCount; i++) [self addObject:[otherArray objectAtIndex:i]];
  }            
}

- (NSArray *)arrayByAddingObject:(id)anObject
{
  FSArray *r = [[self copy] autorelease];
  [r addObject:anObject];
  return r;
}

- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray
{
  FSArray *r = [[self copy] autorelease];
  NSUInteger i, count;
  
  if ([otherArray isKindOfClass:[FSArray class]]) 
    [r addObjectsFromFSArray:(FSArray*)otherArray];
  else
    for (i = 0, count = [otherArray count]; i < count; i++)
      [r addObject:[otherArray objectAtIndex:i]];
  
  return r;
}

- (id)arrayRep {return rep;} 

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
  Class ReplacementForCoderForNilInArrayClass = [FSReplacementForCoderForNilInArray class];
  NSUInteger i, count;
  for (i = 0, count = [self count]; i < count; i++)
  {
    if ([[self objectAtIndex:i] isKindOfClass:ReplacementForCoderForNilInArrayClass]) 
      [self replaceObjectAtIndex:i withObject:nil];
  }   
  return self;
}

- (void)becomeArrayOfId
{
  id oldRep = rep;
  rep = [[rep asArrayRepId] retain];
  [oldRep release];
  type = FS_ID;   
}  

- (Class)classForCoder { return [self class]; }

- (NSString *)componentsJoinedByString:(NSString *)separator
{
  NSMutableArray *a = [NSMutableArray arrayWithCapacity:[self count]];
  
  for (id elem in self)
  {
    if (elem == nil) [a addObject:@"nil"];
    else             [a addObject:elem];
  }
  return [a componentsJoinedByString:separator];
}

- (BOOL)containsObject:(id)anObject
{
  return [self indexOfObject:anObject] != NSNotFound;
}

- copy  { return [self copyWithZone:NULL];}

- copyWithZone:(NSZone *)zone  { return [[FSArray alloc] initWithRepNoRetain:[rep copyWithZone:zone]];}

- (NSUInteger)count 
{
  if ([rep respondsToSelector:@selector(count)]) 
    return [rep count];
  else
  { 
    [self becomeArrayOfId];
    return [rep count]; 
  }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)statep objects:(id *)stackbuf count:(NSUInteger)len
{
  if (type == FS_ID) return [rep   countByEnumeratingWithState:statep objects:stackbuf count:len];
  else               return [super countByEnumeratingWithState:statep objects:stackbuf count:len];  
}

- (NSString *)descriptionLimited:(NSUInteger)nbElem 
{
  if ([rep respondsToSelector:@selector(descriptionLimited:)]) return [rep descriptionLimited:nbElem];
  else return [super descriptionLimited:nbElem];
}

- (NSString *)description 
{
  return [self descriptionLimited:[self count]]; 
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale
{
  return [self descriptionWithLocale:locale indent:0];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level
{
  // fallback to printString (we may do something better in the future).
  // Note: super's implementation is not used because it won't work if the array contains nil.
  return [self printString];
}
  
- (void *)dataPtr
{
  if (type != FS_ID) [self becomeArrayOfId];
  return ((ArrayRepId *)rep)->t;
}  
  
- (void)dealloc
{
  //NSLog([NSString stringWithFormat:@">>>>>>>>>>>> %@", self]);
  [rep release];
  [super dealloc];
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
  for (id elem in self)
  {
    if ([otherArray containsObject:elem]) return elem;
  }
  return nil;
}

- (NSUInteger)indexOfObject:(id)anObject
{
  return [self indexOfObject:anObject inRange:NSMakeRange(0,[self count])];
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range
{
  return [self indexOfObject:anObject inRange:range identical:NO];   
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical
{   
  if (range.location + range.length > [self count])
    [NSException raise:NSRangeException format:@"*** -[%@ indexOfObject:inRange:identical:]: index (%lu) beyond bounds (%lu)",[self class],(long unsigned)(range.location + MAX(0, range.length-1)), (long unsigned)[self count]];

  if ([rep respondsToSelector:@selector(indexOfObject:inRange:identical:)]) 
    return [rep indexOfObject:anObject inRange:range identical:identical];
  
  if (range.length == 0) return NSNotFound;
  else
  {
    NSUInteger i = range.location;
    NSUInteger end = (range.location + range.length -1);
    id elem = [self objectAtIndex:i];
    while ( i <= end && !( identical ? elem == anObject : ([elem isEqual:anObject] || (elem == nil && anObject == nil)) ) )
    {
      i++;
      elem = [self objectAtIndex:i];
    }   
    return (i > end) ? NSNotFound : i;
  }    
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject
{
  return [self indexOfObjectIdenticalTo:anObject inRange:NSMakeRange(0,[self count])];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range
{   
  return [self indexOfObject:anObject inRange:range identical:YES];
}

- init
{
  return [self initWithCapacity:0];
}   

- initFrom:(NSUInteger)from to:(NSUInteger)to step:(NSUInteger)step
{
  ArrayRepDouble *representation = [[ArrayRepDouble alloc] initFrom:from to:to step:step];

  if (representation) return [self initWithRepNoRetain:representation];
  else
  {
    [super dealloc];
    return nil;
  }  
}           

- initFilledWith:(id)elem count:(NSUInteger)nb
{
  id representation;
  
  if (elem == fsTrue || elem == fsFalse)
    representation = [[ArrayRepBoolean alloc] initFilledWithBoolean:(elem == fsTrue ? 1 :0) count:nb];
  else if (isNSNumberWithLosslessConversionToDouble(elem))
    representation = [[ArrayRepDouble alloc] initFilledWithDouble:[(NSNumber *)elem doubleValue] count:nb];
  else
    representation = [[ArrayRepId alloc] initFilledWith:elem count:nb];

  if (representation) return [self initWithRepNoRetain:representation];
  else
  {
    [super dealloc];
    return nil;
  }
} 

- initWithCapacity:(NSUInteger)aNumItems
{
  return [self initWithRepNoRetain:[[ArrayRepEmpty alloc] initWithCapacity:aNumItems]];
}

- initWithObject:(id)object
{
  if (self = [self initWithCapacity:1])
  {
    [self addObject:object];
    return self;
  }
  return nil;
}

- initWithObjects:(id *)objects count:(NSUInteger)nb
{
  NSUInteger i;
  
  if (self = [self initWithCapacity:nb])
  {
    for (i = 0; i < nb; i++) [self addObject:objects[i]];
    return self;
  }
  return nil;
}
    
- (FSArray *)initWithRep:(id)theRep
{
  return [self initWithRepNoRetain:[theRep retain]];
}

- (FSArray *)initWithRepNoRetain:(id)theRep  //designated initializer
{
  if ((self = [super init]))
  {
    retainCount = 1;
    type = [theRep repType];
    rep = theRep;
    return self;
  }
  return nil;
}
             
- (void)insertObject:anObject atIndex:(NSUInteger)index
{
  if (index > [self count])
    [NSException raise:NSRangeException format:@"index beyond the end of the array in method -insertObject:atIndex"];

  if (type == DOUBLE && isNSNumberWithLosslessConversionToDouble(anObject))
    [(ArrayRepDouble *)rep insertDouble:[anObject doubleValue] atIndex:index];
  else
  { 
    if (type != FS_ID) [self becomeArrayOfId];
    [(ArrayRepId *)rep insertObject:anObject atIndex:index];
  }
}    
    
- (BOOL) isEqualToArray:(NSArray *)anArray
{
  NSUInteger count = [self count];
  NSUInteger i;
  
  if (count != [anArray count]) return NO;
  
  for (i = 0; i < count; i++)
  {
    id e1 = [self objectAtIndex:i];
    id e2 = [anArray objectAtIndex:i];
    if (![e1 isEqual:e2] && !(e1 == nil && e2 == nil))
      break;
  }
  return i == count;  
}
        
- mutableCopyWithZone:(NSZone *)zone 
{ 
  return [[FSArray alloc] initWithRepNoRetain:[rep copyWithZone:zone]];
}
    
- objectAtIndex:(NSUInteger)index
{
  switch (type) 
  {
  case FS_ID:
    if (index >= ((ArrayRepId *)rep)->count)
      [NSException raise:NSRangeException format:@"index beyond the end of the array in method -ObjectAtIndex:"];
    return ((ArrayRepId *)rep)->t[index];

  case DOUBLE:
    if (index >= ((ArrayRepDouble *)rep)->count)
      [NSException raise:NSRangeException format:@"index beyond the end of the array in method -ObjectAtIndex:"];
    return [FSNumber numberWithDouble:((ArrayRepDouble *)rep)->t[index]];
  
  case BOOLEAN:
    if (index >= ((ArrayRepBoolean *)rep)->count)
      [NSException raise:NSRangeException format:@"index beyond the end of the array in method -ObjectAtIndex:"];
    return (((ArrayRepBoolean *)rep)->t[index] ? (id)fsTrue : (id)fsFalse);

  case EMPTY:
    [NSException raise:NSRangeException format:@"index beyond the end of the array in method -ObjectAtIndex:"]; 
  
  case FETCH_REQUEST:
    [self becomeArrayOfId];
    return [self objectAtIndex:index];    
  } // end switch

  return nil; // W
}   

- (NSEnumerator *)objectEnumerator
{
  return [[[FSArrayEnumerator alloc] initWithArray:self reverse:NO] autorelease];
}

- (void)removeLastObject 
{
  if ([rep count] == 0) [NSException raise:NSRangeException format:@"-removeLastObject called on an empty array"];
  
  if ([rep respondsToSelector:@selector(removeLastElem)]) [rep removeLastElem];
  else
  {
    [self becomeArrayOfId];
    [rep removeLastElem];
  }
}

- (void)removeObjectAtIndex:(NSUInteger)index 
{
  if (index >= [self count])
    [NSException raise:NSRangeException format:@"index beyond the end of the array in method -removeObjectAtIndex:"];

  if ([rep respondsToSelector:@selector(removeElemAtIndex:)]) [rep removeElemAtIndex:index];
  else
  {
    [self becomeArrayOfId];
    [rep removeElemAtIndex:index];
  }
}  

- (id)replacementObjectForCoder:(NSCoder *)aCoder
{
  //id superReplacement = [super replacementObjectForCoder:aCoder];
  
  if ([self containsObject:nil])
  {
    FSArray *r = [[[FSArray alloc ] initWithCapacity:[self count]] autorelease];
    FSReplacementForCoderForNilInArray *replacementForNil = [[[FSReplacementForCoderForNilInArray alloc] init] autorelease];
    NSUInteger i, count;
    for (i = 0, count = [self count]; i < count; i++)
    {
      id elem = [self objectAtIndex:i];
      if (elem == nil) 
        [r addObject:replacementForNil];
      else
        [r addObject:elem];  
    }
    return r;
  }  
  return self;
}

#if !TARGET_OS_IPHONE
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder 
// Overhide the NSArray behavior (which is to pass arrays by copy by default), with a by reference behavior by default. 
// This is because passing an object by copy only works if the receiving process is linked with the class of the object.
// In our case, we want to support passing Arrays to applications that are not linked with the F-Script framework. 
{
  if ([encoder isBycopy]) return self;
  else  return [NSDistantObject proxyWithLocal:self connection:[encoder connection]];
}
#endif

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  if (index >= [rep count])
   [NSException raise:NSRangeException format:@"index beyond the end of the array in method -replaceObjectAtIndex:withObject:"];
  
  if (type == DOUBLE)
  {
    if (anObject && ((struct {Class isa;} *)anObject)->isa == FSNumberClass)   // anObject is casted to avoid the warning "static access to object of type id"
      [(ArrayRepDouble *)rep replaceDoubleAtIndex:index withDouble:((FSNumber *)anObject)->value];
    else if (anObject && isNSNumberWithLosslessConversionToDouble(anObject)) 
      [(ArrayRepDouble *)rep replaceDoubleAtIndex:index withDouble:[anObject doubleValue]];
    else
    {
      [self becomeArrayOfId];  
      [(ArrayRepId *)rep replaceObjectAtIndex:index withObject:anObject];
    }
  }
  else if (type == BOOLEAN && (anObject == fsTrue || anObject == fsFalse))
    [(ArrayRepBoolean *)rep replaceBooleanAtIndex:index withBoolean:(anObject == fsTrue ? 1 : 0)];
  else 
  {
    if (type != FS_ID) [self becomeArrayOfId];  
    [(ArrayRepId *)rep replaceObjectAtIndex:index withObject:anObject];
  }    
}  

- (id)retain  { retainCount++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (void)release  { if (--retainCount == 0) [self dealloc];}  

- (NSEnumerator *)reverseObjectEnumerator
{
  return [[[FSArrayEnumerator alloc] initWithArray:self reverse:YES] autorelease];
}

- (void)setArray:(NSArray *)operand
{
  id oldRep = rep;
   
  if ([operand isKindOfClass:[FSArray class]]) 
  {
    if ([operand isProxy])  // we test for proxy because we don't want to have a Proxy as array rep.
    {
      NSUInteger i;
      NSUInteger nb = [operand count];    
      type = EMPTY;
      rep = [[ArrayRepEmpty alloc] initWithCapacity:nb];
      for(i = 0; i < nb; i++) [self addObject:[operand objectAtIndex:i]];
    } 
    else
    {
      type = [(FSArray *)operand type];
      rep  = [[(FSArray *)operand arrayRep] copy];
    }
    [oldRep release];
  }
  else [super setArray:operand];  
}  

 
- (NSArray *)subarrayWithRange:(NSRange)range
{
  if (range.location + range.length > [self count]) return [super subarrayWithRange:range]; // will raise an exception
  
  if ([rep respondsToSelector:@selector(subarrayWithRange:)]) return [rep subarrayWithRange:range];
  else
  {
    [self becomeArrayOfId];
    return [rep subarrayWithRange:range];
  }
}
 
- (enum ArrayRepType)type  { return type;} // declared in ArrayPrivate

///////////////////////////////// PRIVATE FOR USE BY FSExecEngine ///////////////

-(NSUInteger) _ul_count { return [self count]; }
 
- _ul_objectAtIndex:(NSUInteger)index
{ 
  switch (type)
  { 
  case FS_ID  :       return ((ArrayRepId *)rep)->t[index];
  case DOUBLE :       return [FSNumber numberWithDouble:((ArrayRepDouble *)rep)->t[index]];
  case BOOLEAN:       return ((ArrayRepBoolean *)rep)->t[index] ? (id)fsTrue : (id)fsFalse;
  case EMPTY  :       assert(0);
  case FETCH_REQUEST: return [self objectAtIndex:index];
  }
  return nil; // W
}

@end
#pragma clang diagnostic pop