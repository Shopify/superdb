
/*   ArrayRepId.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import "ArrayRepId.h"
#import "FSArray.h"
#import "FScriptFunctions.h"
#import <Foundation/Foundation.h>
#import "FSBooleanPrivate.h"
#import "FSCompiler.h"
#import "FSVoid.h"

#if TARGET_OS_IPHONE
# import <objc/runtime.h>
#else
# import <objc/objc-runtime.h>
# import <objc/objc-auto.h>
#endif

#import "FSBlock.h"
#import "BlockRep.h" 
#import "BlockPrivate.h"
#import "FSExecEngine.h"
#import "FSPattern.h"
#import "FSExecEngine.h" // sendMsg
#import "FSNumber.h"
#import "NumberPrivate.h"
#import <string.h>
#import "ArrayPrivate.h"
#import "ArrayRepDouble.h"
#import "ArrayRepBoolean.h"
#import "FSMiscTools.h"

#ifndef MAX
#define MAX(a, b) \
    ({typeof(a) _a = (a); typeof(b) _b = (b);     \
	_a > _b ? _a : _b; })
#endif

#ifndef MIN
#define MIN(a, b) \
    ({typeof(a) _a = (a); typeof(b) _b = (b);	\
	_a < _b ? _a : _b; })
#endif


@interface ArrayRepId(ArrayRepIdPrivate)
- (void) addObjectsFromFSArray:(FSArray *)otherArray;
@end


@implementation ArrayRepId

/*typedef struct {
    unsigned long state;
    id *itemsPtr;
    unsigned long *mutationsPtr;
    unsigned long extra[5];
} NSFastEnumerationState;*/

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)statep objects:(id *)stackbuf count:(NSUInteger)len
{
  if (statep->state == 0)
  {
    statep->state = 1;
	statep->itemsPtr = t;
	statep->mutationsPtr = (unsigned long *)self;
	return count;
  }
  else return 0;
}

///////////////////////////////////// USER METHODS

- (id)at:(id)index put:(id)elem
{
  double ind;
  id oldElem;
  
  if (!index) FSExecError(@"index of an array must not be nil");    

  if ([index isKindOfClass:[NSIndexSet class]])
  {
    NSMutableArray *newIndex = [FSArray array];
    
    NSUInteger currentIndex = [index firstIndex];
    while (currentIndex != NSNotFound)
    {
      [newIndex addObject:[NSNumber numberWithDouble:currentIndex]];
      currentIndex = [index indexGreaterThanIndex:currentIndex];
    }
    index = newIndex;
  }
  
  if ([index isKindOfClass:[NSNumber class]])
  {      
    ind = [index doubleValue];
                                               
    if (ind < 0) FSExecError(@"index of an array must be a number greater or equal to 0");              
    if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");
    
    oldElem = t[(NSUInteger)ind];
    t[(NSUInteger)ind] = [elem retain];
    [oldElem release];
  }
  else if ([index isKindOfClass:[NSArray class]])
  {
    id elem_index;
    NSUInteger i = 0;
    NSUInteger j = 0;
    NSUInteger nb = [index count];
    NSUInteger elem_count = 0; // elem_count is initialized in order to avoid a false warning "might be used uninitialized"
    BOOL elemIsArray = [elem isKindOfClass:[NSArray class]];
    
    //if (![elem isKindOfClass:[NSArray class]]) 
    //  FSExecError(@"method \"at:put:\", argument 1 is an array, argument 2 must be an array too");
    
    if (elemIsArray) elem_count = [elem count];
            
    while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
    
    if (i == nb)
    {
      if ((nb == count || nb == 0) && (!elemIsArray || elem_count == 0)) return elem;
      else FSExecError(@"invalid index");
    }
    
    elem_index = [index objectAtIndex:i];

    if ([elem_index isKindOfClass:[FSBoolean class]])
    {
      NSUInteger k,trueCount;

      if (nb != count) FSExecError(@"indexing with an array of boolean of bad size");

      if (elemIsArray)
      {  
        for (k=i, trueCount=0; k<nb; k++)
        {
          elem_index = [index objectAtIndex:k];
          if (elem_index == fsTrue || (elem_index != fsFalse && [elem_index isKindOfClass:[FSBoolean class]] && [elem_index isTrue]))
            trueCount++;
        }
        if      (elem_count < trueCount) FSExecError(@"method \"at:put:\", not enough elements in argument 2");               
        else if (elem_count > trueCount) FSExecError(@"method \"at:put:\", too many elements in argument 2");               
      }
      
      while (i < nb)
      {
        elem_index = [index objectAtIndex:i];
        
        if (elem_index == fsTrue || (elem_index != fsFalse && [elem_index isKindOfClass:[FSBoolean class]] && [elem_index isTrue]) )
        {
          oldElem = t[i];
          t[i] = [(elemIsArray ? [elem objectAtIndex:j] : elem) retain];
          [oldElem release];
          j++;
        }
        else if (elem_index != fsFalse && ![elem_index isKindOfClass:[FSBoolean class]]) FSExecError(@"indexing with a mixed array");
        
        i++;
        while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
      }
      return elem;
    }  
    else if ([elem_index isKindOfClass:[NSNumber class]])
    {
      NSUInteger k;
      if (elemIsArray && nb != elem_count) FSExecError(@"method \"at:put:\", argument 1 and argument 2 must be arrays of same size");
      
      for (k=i; k<nb; k++)
      {
        elem_index = [index objectAtIndex:k];
        if (![elem_index isKindOfClass:[NSNumber class]]) FSExecError(@"array indexing by a mixed array");
        ind = [elem_index doubleValue];
        if (ind < 0) FSExecError(@"index of an array must be a number greater or equal to 0");              
        else if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");                                                
      }      
      
      while (i < nb)
      {        
        elem_index = [index objectAtIndex:i];
        ind = [elem_index doubleValue];
        oldElem = t[(NSUInteger)ind];
        t[(NSUInteger)ind] = [(elemIsArray ? [elem objectAtIndex:i] : elem) retain];   
        [oldElem release];
        i++;
        while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil values
      }
    }  
    else // elem_index is neither an NSNumber nor a FSBoolean
      FSExecError([NSString stringWithFormat:@"array indexing by an array containing %@", descriptionForFSMessage(elem_index)]);
  }
  else
    FSExecError([NSString stringWithFormat:@"array indexing by %@, number, array or index set expected", descriptionForFSMessage(index)]);
    
  return elem;
}

- (id)operator_backslash:(FSBlock*)bl // may raise
{
    NSUInteger i;  
    id args[3];
    
    args[0] = t[0];
    
    if ([bl isCompact])
    {
      SEL selector = [bl selector];
      NSString *selectorStr = [bl selectorStr];
      FSMsgContext *msgContext = [bl msgContext];

      args[1] = (id)(selector ? selector : [FSCompiler selectorFromString:selectorStr]);

      for (i = 1; i < count; i++)
      {
        args[2] = t[i];
        args[0] = sendMsg(args[0], selector, 3, args, nil, msgContext, nil);
      }
    }
    else
    {
      BlockRep *blRep = [bl blockRep];

      for (i = 1; i < count; i++)
      {
        args[2] = t[i];
        args[0] = [blRep body_notCompact_valueArgs:args count:3 block:bl];
      }
    }
    return args[0];   
}
   
- (FSArray *)replicateWithArray:(FSArray *)operand
{
  FSArray *r;
  NSUInteger i,j;
  FSArray *index = operand;
  
  assert(![operand isProxy]);
  
  r = [FSArray array];
  
  switch ([index type])
  {
  case FS_ID:
  {
    id *indexData = [operand dataPtr];
    for (i=0; i < count; i++)
    {
      double opElemDouble; 
    
      if (![indexData[i] isKindOfClass:NSNumberClass]) FSExecError(@"argument 1 of method \"replicate:\" must be an array of numbers");
    
      opElemDouble = [(NSNumber *)(indexData[i]) doubleValue];
    
      if (opElemDouble < 0) FSExecError(@"argument 1 of method \"replicate:\" must not contain negative numbers"); 
      if (opElemDouble > NSUIntegerMax) FSExecError([NSString stringWithFormat:@"argument of method \"replicate:\" must contain numbers less or equal to %lu", (unsigned long)NSUIntegerMax]);
      
      for (j=0; j < opElemDouble; j++) [r addObject:t[i]];
    }
    break;
  }
  case DOUBLE:
  {
    double *indexData = [(ArrayRepDouble *)[operand arrayRep] doublesPtr]; 
    for (i=0; i < count; i++)
    {
      double opElemDouble = indexData[i];
      if (opElemDouble < 0) FSExecError(@"argument 1 of method \"replicate:\" must not contain negative numbers"); 
      if (opElemDouble > NSUIntegerMax)
        FSExecError([NSString stringWithFormat:@"argument of method \"replicate:\" must contain numbers less or equal to %lu", (unsigned long)NSUIntegerMax]);
      
      for (j=0; j < opElemDouble; j++) [r addObject:t[i]];
    }
    break;
  }
  
  case BOOLEAN: 
    if ([operand count] != 0) FSExecError(@"argument 1 of method \"replicate:\" is an array of Booleans. An array of numbers was expected");
    break;
  
  case EMPTY: break;
  
  case FETCH_REQUEST:
    [operand becomeArrayOfId];
    return [self indexWithArray:operand];

  } // end switch
  
  return r;
}       
    
- (FSArray *)rotatedBy:(NSNumber *)operand
{
  FSArray *r;
  NSUInteger i;
  NSInteger op;
  
  VERIF_OP_NSNUMBER(@"rotatedBy:");
  
  if (count == 0) return [FSArray array];
  
  op = [operand doubleValue];
  r = [FSArray arrayWithCapacity:count];
  
  if (op >= 0)
  {
    for(i = op % count ; i < count; i++)
      [r addObject:t[i]];

    for (i = 0; i < op % count; i++)
      [r addObject:t[i]];
  }
  else
  {
    op = -op;
    for(i = count-(op % count) ; i < count; i++)
      [r addObject:t[i]];

    for (i = 0; i < count-(op % count); i++)
      [r addObject:t[i]];
  }     
  return r;            
}


///////////////////////////////////////////////////////////////////////////
//////////////////////////////////// OTHER METHOD /////////////////////////
///////////////////////////////////////////////////////////////////////////

- (void)addObject:(id)anObject
{
  count++;
  if (count > capacity)
  {
    capacity = (capacity+1)*2;
    t = (id *)NSReallocateCollectable(t, capacity * sizeof(id), NSScannedOption);
  }
  t[count-1] = [anObject retain];
}

- (void)addObjectsFromFSArray:(FSArray *)otherArray
{
  NSUInteger i;
  NSUInteger oldCount = count;
  id *otherArrayData = [otherArray dataPtr];
  NSUInteger otherArrayCount = [otherArray count];
   
  count += otherArrayCount;
 
  if (count > capacity)
  {
    capacity = count;
    t = (id *)NSReallocateCollectable(t, capacity * sizeof(id), NSScannedOption);
  }
  
  for (i = 0; i < otherArrayCount; i++)
    t[oldCount+i] = [otherArrayData[i] retain];     
}

- (ArrayRepId *) asArrayRepId
{ return self;}

- copyWithZone:(NSZone *)zone
{
  return [[[self class] allocWithZone:zone] initWithObjects:t count:count];  
}

- (NSUInteger)count
{ return  count; }
  
- (void *)dataPtr
{return t;}  
  
- (void)dealloc
{
  NSUInteger i;
  //printf("\n arrayRep : dealloc\n");
  
  for (i = 0; i < count; i++) [t[i] release]; 
  free(t);
  [super dealloc];
} 

- (NSString *)descriptionLimited:(NSUInteger)nbElem
{
  NSMutableString *str = [[@"{" mutableCopy] autorelease];
  NSString *elemStr = @""; // W
  NSUInteger i;
  NSUInteger lim = MIN(count,nbElem); 

  if (lim > 0)
  {
    elemStr = printString(t[0]);
    [str appendString:elemStr];  
  }          
    
  for (i = 1; i < lim; i++)
  {
    [str appendString:@", "];
    if ([elemStr length] > 20) [str appendString:@"\n"];
    
    elemStr = printString(t[i]);
    [str appendString:elemStr];      
  }
  
  if (count > nbElem) [str appendFormat:@", ... (%lu more elements)",(unsigned long)(count-nbElem)];
  [str appendString:@"}"];
  return str; 
} 

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical
{
  if (range.length == 0) return NSNotFound;
  else
  {
    NSUInteger i = range.location;
    NSUInteger end = (range.location + range.length -1);
    while ( i <= end && !( identical ? t[i] == anObject : ([t[i] isEqual:anObject] || (t[i] == nil && anObject == nil)) ) )
    {
      i++;
    }   
    return (i > end) ? NSNotFound : i;
  }    
}

- indexWithArray:(FSArray *)index
{
  switch ([index type])
  {
  case FS_ID:
  {
    FSArray *r;
    id *indexData;
    NSUInteger i = 0;
    NSUInteger nb = [index count];
    
    indexData = [index dataPtr]; 

    while (i < nb && !indexData[i]) i++;            // ignore the nil value
    if (i == nb)
    {
      if (nb == count || nb == 0) return [FSArray array];
      else FSExecError(@"invalid index");
    }
    
    if (indexData[i] == fsTrue || indexData[i] == fsFalse || [indexData[i] isKindOfClass:[FSBoolean class]]) 
    {
      if (nb != count) FSExecError(@"indexing with an array of booleans of bad size");
      
      r  = [FSArray array];
            
      while (i < nb)
      {             
        if (indexData[i] == fsTrue)     [r addObject:t[i]];
        else if (indexData[i] != fsFalse)
        {
          if (![indexData[i] isKindOfClass:[FSBoolean class]]) FSExecError(@"indexing with a mixed array");
          else if ([indexData[i] isTrue]) [r addObject:t[i]];
        }  
        i++;
        while (i < nb && !indexData[i]) i++;            // ignore the nil value
      }
    }  
    else if ([indexData[i] isKindOfClass:NSNumberClass])
    {
      r = [FSArray arrayWithCapacity:nb];
      
      while (i < nb)
      {      
        double ind;            
        if (![indexData[i] isKindOfClass:NSNumberClass]) FSExecError(@"indexing with a mixed array");
                  
        ind = [indexData[i] doubleValue];

        /*
        if (ind != (int)ind)
          FSExecError(@"l'indice d'un tableau doit etre un nombre sans "
                       @"partie fractionnaire");      
        */
                
        if (ind < 0)     FSExecError(@"index of an array must be a number greater or equal to 0");              
        if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");
        
        [r addObject:t[(NSUInteger)ind]];
        
        i++;
        while (i < nb && !indexData[i]) i++;            // ignore the nil value
      }
    }  
    else // indexData[i] is neither an NSNumber nor a FSBoolean
    {
      FSExecError([NSString stringWithFormat:@"array indexing by an array containing %@", descriptionForFSMessage(indexData[i])]);
      return nil; // W
    }
    return r;
  }
  case BOOLEAN:
  {
    NSUInteger i;
    FSArray *r; 
    char *indexData;

    if ([index count] == 0) return [FSArray array];
    
    if ([index count] != count) FSExecError(@"indexing with an array of booleans of bad size");
 
    r  = [FSArray array];
    indexData = [(ArrayRepBoolean *)[index arrayRep] booleansPtr];     

    for (i = 0; i < count; i++) if (indexData[i]) [r addObject:t[i]];   
    
    return r;
  }
  case DOUBLE:
  {
    FSArray *r;
    double *indexData;
    NSUInteger i = 0;
    NSUInteger nb = [index count];
    
    if (i == nb) return [FSArray array];

    indexData = [(ArrayRepDouble *)[index arrayRep] doublesPtr]; 
    
    r = [FSArray arrayWithCapacity:nb];
      
    while (i < nb)
    {                             
        double ind = indexData[i];

        /*
        if (ind != (int)ind)
          FSExecError(@"l'indice d'un tableau doit etre un nombre sans "
                       @"partie fractionnaire");      
        */
                
        if (ind < 0)     FSExecError(@"index of an array must be a number greater or equal to 0");              
        if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");
        
        [r addObject:t[(NSUInteger)ind]];
        
        i++;
    }
    return r;
  }
  
  case EMPTY: return [FSArray array];  
  
  case FETCH_REQUEST: 
    [index becomeArrayOfId];
    return [self indexWithArray:index];
  
  } // end switch

  return nil; // W
} 

- init
{
  return [self initWithCapacity:0];
}   

/*- initFrom:(unsigned)from to:(unsigned)to step:(unsigned)step
{
  if (to < from) return [self init];
  
  if ([self initWithCapacity:1+((to-from)/step)])
  {
    double valcou = from;
    
    do
    {
      t[count++] = [[[Number alloc] initWithDouble:valcou] retain];
      valcou += step;
    }  
    while (valcou <= to);
    return self;
  }
  return nil;
} */

- initFilledWith:(id)elem count:(NSUInteger)nb
{
  if (self = [self initWithCapacity:nb])
  { 
    for(count = 0; count < nb; count++) t[count] = [elem retain];  
    return self;
  }
  return nil; 
} 

- initWithCapacity:(NSUInteger)aNumItems
{ 
  if ((self = [super init]))
  {
    t = NSAllocateCollectable(aNumItems*sizeof(id), NSScannedOption);
    if (!t)
    {
      [super dealloc];
      return nil;
    }
    retainCount = 1;
    capacity = aNumItems;
    count = 0;
    return self;
  }
  return nil;
}

- initWithObjectsNoCopy:(id *)tab count:(NSUInteger)nb
{
  if ((self = [super init]))
  {
    retainCount = 1;
    t = tab;
    capacity = nb;
    count = nb;
    return self;
  }
  return nil;    
}

- initWithObjects:(id *)objects count:(NSUInteger)nb
{
  NSUInteger i;
  
  if (self = [self initWithCapacity:nb])
  {
    for (i = 0; i < nb; i++)
    {
      t[i] = [objects[i] retain];
    }
    count = nb;
    return self;
  }
  return nil;
}
                 
- (void)insertObject:anObject atIndex:(NSUInteger)index
{
  if (index > count) [NSException raise:NSRangeException format:@"index beyond the end of the array in method -insertObject:atIndex"];
  
  count++ ;

  if (count > capacity)
  {
    capacity = (capacity+1)*2;
    t = (id*)NSReallocateCollectable(t, capacity * sizeof(id), NSScannedOption);
  }

  objc_memmove_collectable( &(t[index+1]), &(t[index]), ((count-1)-index) * sizeof(id));

  t[index] = [anObject retain];
}    
  
- objectAtIndex:(NSUInteger)index
{
  if (index >= count) [NSException raise:NSRangeException format:@"index beyond the end of the array in method -ObjectAtIndex:"];
  return t[index];
}   

- (void)removeLastElem
{
  [self removeLastObject];
}

- (void)removeLastObject
{
  if (count == 0) [NSException raise:NSRangeException format:@"-removeLastObject called on an empty array"];

  [t[count-1] release];
  count--;
  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (id*)NSReallocateCollectable(t, capacity * sizeof(id), NSScannedOption);
  }    
}

- (void)removeElemAtIndex:(NSUInteger)index
{
  [self removeObjectAtIndex:index];
}


- (void)removeObjectAtIndex:(NSUInteger)index 
{
  if (index >= count) [NSException raise:NSRangeException format:@"index beyond the end of the array in method -removeObjectAtIndex:"];
    
  [t[index] release];
  
  count--;
  
  objc_memmove_collectable( &(t[index]), &(t[index+1]), (count-index) * sizeof(id) );

  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (id*)NSReallocateCollectable(t, capacity * sizeof(id), NSScannedOption);
  }
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  if (index >= count) [NSException raise:NSRangeException format:@"index beyond the end of the array in method -replaceObjectAtIndex:withObject:"];
    
  [anObject retain];
  [t[index] release];
  t[index] = anObject;
}  

- (id)retain  { retainCount++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (oneway void)release  { if (--retainCount == 0) [self dealloc];}  

- (NSArray *)subarrayWithRange:(NSRange)range
{
  ArrayRepId *resRep;
  FSArray *r;

  resRep = [[ArrayRepId alloc] initWithObjects:t+range.location count:range.length];
  r = [FSArray arrayWithRep:resRep];
  [resRep release];
  return r;   
}

- (enum ArrayRepType)repType { return FS_ID;}

- (FSArray *)where:(NSArray *)booleans // precondition: booleans is actualy an array and is of same size as the receiver
{
  FSArray *result = [FSArray array];

  if ([booleans isKindOfClass:[FSArray class]] && [(FSArray *)booleans type] == BOOLEAN)  
  {
    char *rawBooleans = [(ArrayRepBoolean *)[(FSArray *)booleans arrayRep] booleansPtr];     
    
    for (NSUInteger i = 0; i < count; i++) if (rawBooleans[i]) [result addObject:t[i]];   
  }
  else
  {  
    id boolean;
    
    for (NSUInteger i = 0; i < count; i++) 
    {
      boolean = [booleans objectAtIndex:i];
      
      if (boolean == fsFalse || boolean == nil) 
        continue;
      else if (boolean == fsTrue)
        [result addObject:t[i]];
      else if ([boolean isKindOfClass:[FSBoolean class]])
      {
        if ([boolean isTrue])
          [result addObject:t[i]];
      }
      else
        FSExecError(@"argument of method \"where:\" must be an array of booleans");
    }
  }
  
  return result;  
}

@end
