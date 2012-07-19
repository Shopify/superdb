/* FSNSArray.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSArrayPrivate.h"
#import "FSArray.h"
#import "FSMiscTools.h"
#import "FSNSString.h"
#import "FScriptFunctions.h"
#import "FSSystemPrivate.h"
#import "FSBlock.h"
#import "FSNumber.h"
#import "FSPattern.h"
#import "FSExecEngine.h"
#import "ArrayPrivate.h"
#import "NumberPrivate.h"
#import "FSBooleanPrivate.h"
#import "ArrayRepDouble.h"
#include <unistd.h>

static int comp_id(const void *a,const void *b)
{
  if (*(id *)a == *(id*)b)
    return 0;
  else if ( (uintptr_t)(*(id *)a) < (uintptr_t)(*(id *)b) )
    return -1;
  else
    return 1; 
}

struct sort_elem
{
  NSUInteger index;
  id       object;
};

static int comp(const void *a,const void *b)
{
  FSBoolean *a_inf_b;
  FSBoolean *b_inf_a;
  id objectA = ((struct sort_elem *)a)->object;
  id objectB = ((struct sort_elem *)b)->object;
  
  if (objectA == nil)
  {
    if (objectB == nil) return 0;
    else          return 1;
  }
  else if (objectB == nil) return -1;
  
  if ((a_inf_b = [objectA operator_less:objectB]) == fsTrue)
    return -1;
  else if ((b_inf_a =[objectB operator_less:objectA]) == fsTrue)    
    return 1;
  else
  {
    if (a_inf_b == fsFalse && b_inf_a == fsFalse) return 0;
    else if ([a_inf_b isTrue]) return -1;
    else if ([b_inf_a isTrue]) return 1;
    else return 0;
  }  
}

@interface NSCopyingWrapper: NSObject <NSCopying> // This class is specialy designed (and tricky optimized) to be used by the method ><
{
  id obj;
}
  
- (id) copyWithZone:(NSZone *)zone;
- (NSUInteger) hash;
- (id) initWithObject:(id)theObject;
- (BOOL) isEqual:(id)theObject;
- (void) setObject:(id)theObject;
@end

@implementation NSCopyingWrapper

- (id) copyWithZone:(NSZone *)zone {return [[NSCopyingWrapper allocWithZone:zone] initWithObject:obj];}

- (NSUInteger)hash { return [obj hash]; }

- (id) initWithObject:(id)theObject 
{ 
  if ((self = [super init]))
    obj = theObject;  // warning: to speed up, we do not retain.

  return self;
}

- (BOOL)isEqual:(id)theObject 
{
  if ([obj isEqual:((NSCopyingWrapper *)theObject)->obj] || (obj == nil && ((NSCopyingWrapper *)theObject)->obj == nil)) return YES;   
  else return NO; 
}

- (void) setObject:(id)theObject { obj = theObject; } // warning: to speed up, we do not retain.

@end

@interface NSArray(FSNSArrayPrivateInternal)
+ (FSArray *)arrayWithShape:(FSArray *)shape;
@end

@implementation NSArray(FSNSArray)

///////////////////////////////////// USER METHODS

- (id)at:(id)index
{
  double ind;
  NSUInteger count = [self count];
  
  if (!index) FSExecError(@"index of an array must not be nil");    

  if ([index isKindOfClass:NSNumberClass])
  {      
    ind = [index doubleValue];
                                              
    if (ind < 0)              FSExecError(@"index of an array must be a number greater or equal to 0");              
    if (ind >= count)         FSExecError(@"index of an array must be a number less than the size of the array");
    if (ind != (NSUInteger)ind) FSExecError(@"index of an array must be an integer");    

    return [self objectAtIndex:(NSUInteger)ind];
  }
  else if ([index isKindOfClass:[NSArray class]])
  {
    if ([index isProxy])
    { // build a local array because indexWithArray: does not support FSArray proxy
      NSUInteger i;
      NSUInteger nb = [index count];
      FSArray *remoteIndex = index;
      
      index = [FSArray arrayWithCapacity:nb]; 
      for (i = 0; i < nb; i++) [index addObject:[remoteIndex objectAtIndex:i]];
    } 
    
    if ([self isKindOfClass:[FSArray class]] && [index isKindOfClass:[FSArray class]] && [[(FSArray *)self arrayRep] respondsToSelector:@selector(indexWithArray:)])
      return [[(FSArray *)self arrayRep] indexWithArray:(FSArray*)index];
    else
    {
      FSArray *r;
      NSUInteger i = 0;
      NSUInteger nb = [index count];
      id indexElement = nil; // initialization of indexElement in order to avoid a warning
      
      while (i < nb && (indexElement = [index objectAtIndex:i]) == nil) i++;            // ignore the nil value
      if (i == nb)
      {
        if (nb == count || nb == 0) return [FSArray array];
        else FSExecError(@"invalid index");
      }
            
      if (indexElement == fsTrue || indexElement == fsFalse || [indexElement isKindOfClass:[FSBoolean class]]) 
      {
        if (nb != count) FSExecError(@"indexing with an array of booleans of bad size");
        
        r  = [FSArray array];
              
        while (i < nb)
        {             
          if (indexElement == fsTrue) [r addObject:[self objectAtIndex:i]];
          else if (indexElement != fsFalse)
          {
            if (![indexElement isKindOfClass:[FSBoolean class]]) FSExecError(@"indexing with a mixed array");
            else if ([indexElement isTrue]) [r addObject:[self objectAtIndex:i]];
          }  
          i++;
          while (i < nb && (indexElement = [index objectAtIndex:i]) == nil) i++;    // ignore the nil value
        }
      }  
      else if ([indexElement isKindOfClass:NSNumberClass])
      {
        r = [FSArray arrayWithCapacity:nb];
        
        while (i < nb)
        {      
          double ind;            
          if (![indexElement isKindOfClass:NSNumberClass]) FSExecError(@"indexing with a mixed array");
                    
          ind = [indexElement doubleValue];
                    
          if (ind < 0)      FSExecError(@"index of an array must be a number greater or equal to 0");              
          if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");

          [r addObject:[self objectAtIndex:(NSUInteger)ind]];
          
          i++;
          while (i < nb && (indexElement = [index objectAtIndex:i]) == nil) i++;            // ignore the nil value
        }
      }  
      else // indexElement is neither an NSNumber nor a FSBoolean
      {
        FSExecError([NSString stringWithFormat:@"array indexing by an array containing %@",descriptionForFSMessage(indexElement)]);
        return nil; // W
      }
      return r;
    }        
  }
  else if ([index isKindOfClass:[NSIndexSet class]])
  {
    FSArray *r = [FSArray arrayWithCapacity:[index count]];
    NSUInteger currentIndex = [index firstIndex];
    while (currentIndex != NSNotFound)
    {
      [r addObject:[self objectAtIndex:currentIndex]];
      currentIndex = [index indexGreaterThanIndex:currentIndex];
    }
    return r;
  }
  else
  {
    FSExecError([NSString stringWithFormat:@"array indexing by %@, number, array or index set expected", descriptionForFSMessage(index)]);
    return nil; // W
  }
}  

- (id)clone {return [[self copy] autorelease];}

- (FSArray *)difference:(NSArray *)operand
{
  NSUInteger i, op_count;
  BOOL no_nil1 = YES;
  BOOL no_nil2 = YES;
  NSMutableSet *set = [NSMutableSet set];
  FSArray *r;
  NSUInteger count = [self count];

  VERIF_OP_NSARRAY(@"difference:");

  for (i = 0; i < count; i++)
  {
    id elem = [self objectAtIndex:i];
    if (elem) [set addObject:elem];
    else      no_nil1 = NO;
  }

  op_count = [operand count];

  for (i = 0; i < op_count; i++)
  {
    id elem = [operand objectAtIndex:i];
    if (elem) [set removeObject:elem];
    else      no_nil2 = NO;      
  }    

  r = [[[FSArray alloc] initWithArray:[set allObjects]] autorelease];

  if (!no_nil1 && no_nil2)
    [r addObject:nil];

  return r;        
}

- (FSArray *)distinct  {return [self union:[FSArray array]];}

- (FSArray *) distinctId
{
  FSArray *r = [FSArray array];
  id currentId;
  NSUInteger i;
  NSUInteger count = [self count];
  id *tab;
   
  if (count == 0) return r;

  @try
  {
    tab = malloc(count*sizeof(id));
    
    [self getObjects:tab];
    
    qsort(tab,count,sizeof(id),comp_id);
  
    [r addObject:tab[0]];
    currentId = tab[0];
  
    for (i=1; i < count; i++)
      if (tab[i] != currentId)
      {
        [r addObject:tab[i]];
        currentId = tab[i];
      }
  }
  @finally
  {
    free(tab);
  }
  return r;
}

- (void) do:(FSBlock *)operation
{
  FSVerifClassArgsNoNil(@"do:", 1, operation, [FSBlock class]);
  if ([operation argumentCount] != 1) FSExecError(@"argument of method \"do:\" must be a block with one arguments");
  
  for (id element in self) 
  {
    [operation value:element];
  } 
}

- (FSArray *)index 
{
  return [[NSNumber numberWithUnsignedInteger:[self count]] iota];
}  

- (void) inspect
{
  [self inspectWithSystem:nil];
}

- (void)inspectWithSystem:(FSSystem *)system
{
  FSVerifClassArgs(@"inspectWithSystem:",1,system,[FSSystem class],(NSInteger)1);
  [self inspectWithSystem:system blocks:nil];
}

- (void)inspectWithSystem:(FSSystem *)system blocks:(NSArray *)blocks
{
  inspectCollection(self, system, blocks);
}

- (void) inspectIn:(FSSystem *)system
{
  FSVerifClassArgsNoNil(@"inspectIn:",1,system,[FSSystem class]);
  [self inspectWithSystem:system];
}

- (void) inspectIn:(FSSystem *)system with:(NSArray *)blocks
{
  [self inspectWithSystem:system blocks:blocks];
}

- (FSArray *)intersection:(NSArray *)operand
{
  NSUInteger i, op_count;
  BOOL no_nil1 = YES;
  BOOL no_nil2 = YES;
  NSMutableSet *set = [NSMutableSet set];
  FSArray *r = [FSArray array];
  NSUInteger count = [self count];
  
  VERIF_OP_NSARRAY(@"intersection:");
  
  for (i=0; i < count; i++)
  {
    id elem = [self objectAtIndex:i];
    if (elem) [set addObject:elem];
    else      no_nil1 = NO;
  }
  
  op_count = [operand count];
  
  for (i=0; i <op_count; i++)
  {
    id elem = [operand objectAtIndex:i];
    if (elem)
    {
      if ([set member:elem]) { [r addObject:elem]; [set removeObject:elem];}
    }
    else 
      no_nil2 = NO;
  }    
  
  if (!no_nil1 && !no_nil2) [r addObject:nil];
    
  return r;        
}

- (id)operator_backslash:(FSBlock*)operand
{
  NSUInteger count = [self count];
  NSUInteger i;
  id acu;

  FSVerifClassArgsNoNil(@"\\",1,operand,[FSBlock class]);
  if ([operand argumentCount] != 2) FSExecError(@"argument of method \"\\\" must be a block with two arguments");
  
  if ([self count] == 0) return nil;

  if ([self isKindOfClass:[FSArray class]] && ![operand isProxy] && [[(FSArray*)self arrayRep] respondsToSelector:@selector(operator_backslash:)])
  {
    return [[(FSArray*)self arrayRep] operator_backslash:operand];
  }
  else 
  {
    acu = [self objectAtIndex:0];
    for (i = 1; i < count; i++) acu = [operand value:acu value:[self objectAtIndex:i]];
    return acu;
  }  
}

- (NSNumber *)operator_exclam:(id)anObject
{
  NSUInteger index = [self indexOfObject:anObject];
  return index == NSNotFound ? [NSNumber numberWithUnsignedInteger:[self count]] : [NSNumber numberWithUnsignedInteger:index];
}  

- (NSNumber *)operator_exclam_exclam:(id)anObject
{
  NSUInteger index = [self indexOfObjectIdenticalTo:anObject];
  return index == NSNotFound ? [NSNumber numberWithUnsignedInteger:[self count]] : [NSNumber numberWithUnsignedInteger:index];
}  

- (FSArray *)operator_greater_less:(id)operand  
{
  NSMutableDictionary *dict;
  FSArray *r;
  NSUInteger i, self_count, operand_count;
  NSCopyingWrapper *w;

  VERIF_OP_NSARRAY(@"><");

  self_count = [self count]; operand_count = [operand count];  
  w = [[[NSCopyingWrapper alloc] initWithObject:nil] autorelease];

  dict = [NSMutableDictionary dictionaryWithCapacity:self_count];
 
  for (i = 0; i < self_count; i++) 
  {
    [w setObject:[self objectAtIndex:i]];
    [dict setObject:[FSArray array] forKey:w]; // w is then copied by the dictionary
  }

  for (i=0; i < operand_count; i++)
  {
    [w setObject:[operand objectAtIndex:i]]; 
    [[dict objectForKey:w] addObject:[FSNumber numberWithDouble:i]]; 
  }
  
  r = [FSArray arrayWithCapacity:self_count];
  
  for (i = 0; i < self_count; i++)
  {
   [w setObject:[self objectAtIndex:i]];
   [r addObject:[dict objectForKey:w]];
  }
  
  return r;
}

- (FSArray *)operator_plus_plus:(NSArray *)operand 
{  
  FSArray *r;
  
  VERIF_OP_NSARRAY(@"++");
  
  r =  [FSArray arrayWithArray:self];
  [r addObjectsFromArray:operand];
  return r;
}

- (FSArray *)prefixes
{
  NSUInteger i;
  NSUInteger count = [self count];
  FSArray *r = [FSArray arrayWithCapacity:count];
  NSRange range;
  
  for (i = 0 ; i < count; i++)
  {
    range.location = 0;
    range.length = i+1;
    [r addObject:[self subarrayWithRange:range]];
  }
  return r;
}

- (NSString *)printString
{
  return [self descriptionLimited:[self count]];
}

- (FSArray *)replicate:(NSArray *)operand
{
  FSArray *r;
  NSUInteger i,j;
  NSUInteger count = [self count];

  VERIF_OP_NSARRAY(@"replicate:");
  if ([self count] != [operand count]) FSExecError(@"receiver and argument of method \"replicate:\" must be arrays of same size");
   
  r = [FSArray array];
  
  for (i=0; i < count; i++)
  {
    id opElem = [operand objectAtIndex:i];
    double opElemDouble;
    id elem = [self objectAtIndex:i]; 
    
    if (![opElem isKindOfClass:NSNumberClass]) FSExecError(@"argument 1 of method \"replicate:\" must be an array of numbers");
    
    opElemDouble = [(NSNumber *)(opElem) doubleValue];
    
    if (opElemDouble < 0)        FSExecError(@"argument 1 of method \"replicate:\" must not contain negative numbers"); 
    if (opElemDouble > NSUIntegerMax) FSExecError([NSString stringWithFormat:@"argument of method \"replicate:\" must contain numbers less or equal to %lu",(unsigned long)NSUIntegerMax]);
      
    for (j=0; j < opElemDouble; j++) [r addObject:elem];
  }
  return r;  
}

- (FSArray *)reverse
{ 
  NSUInteger  i = [self count];
  FSArray      *r = [FSArray arrayWithCapacity:i];
  
  while (i != 0)
  {
    [r addObject:[self objectAtIndex:i-1]];
	i--;
  }
  
  return r;    
}    

- (FSArray *)rotatedBy:(NSNumber *)operand
{
  FSArray *r;
  NSUInteger i;
  NSInteger op;
  NSUInteger count = [self count];
  
  VERIF_OP_NSNUMBER(@"rotatedBy:");
  
  if (count == 0) return [FSArray array];
  
  op = [operand doubleValue];
  r = [FSArray arrayWithCapacity:count];
  
  if (op >= 0)
  {
    for (i = op % count ; i < count; i++) [r addObject:[self objectAtIndex:i]];
    for (i = 0; i < op % count; i++)      [r addObject:[self objectAtIndex:i]];
  }
  else
  {
    op = -op;
    for(i = count-(op % count) ; i < count; i++) [r addObject:[self objectAtIndex:i]];
    for (i = 0; i < count-(op % count); i++)     [r addObject:[self objectAtIndex:i]];
  }     
  return r;            
}

- (FSArray *)scan:(FSBlock*)operand  // very sub-optimized
{
  NSUInteger i;
  FSArray *r;
  id acu;
  NSUInteger count = [self count];

  FSVerifClassArgsNoNil(@"scan:",1,operand,[FSBlock class]);
  if ([operand argumentCount] != 2)  FSExecError(@"argument of method \"scan:\" must be a block with two arguments");
  
  r = [[[FSArray alloc] initWithCapacity:count] autorelease];
  
  if (count == 0) return r;

  acu = [self objectAtIndex:0];
  [r addObject:acu]; 

  for (i = 1; i < count; i++) {acu = [operand value:acu value:[self objectAtIndex:i]]; [r addObject:acu];}
 
  return r;
}

- (FSArray *)sort
{
  NSUInteger i;
  double *resTab;
  NSUInteger count = [self count];
  struct sort_elem * tab;

  if (count == 0) return [FSArray array]; // mergesort() crashes if passed an empty array 
  
  if (count >= 2 && ([self objectAtIndex:0] && ![[self objectAtIndex:0] respondsToSelector:@selector(operator_less:)] || [self objectAtIndex:count/2] && ![[self objectAtIndex:count/2] respondsToSelector:@selector(operator_less:)]))
      FSExecError(@"elements must responds to \"<\"");
  
  @try
  {
    tab = malloc(count * sizeof(struct sort_elem));  
    for (i = 0; i < count; i++)
    {
      tab[i].index = i;
      tab[i].object = [self objectAtIndex:i];
    }
    
    if (mergesort(tab,count,sizeof(struct sort_elem),comp) != 0)
    {
      if (errno == ENOMEM) FSExecError(@"not enough memory");
      else FSExecError(@"F-Script internal error in method -sort (FSNSArray.m)");  // Defensive. 
    }
    
    resTab = (double*) malloc(count * sizeof(double));
      
    for (i = 0; i < count; i++) resTab[i] = tab[i].index;
  }
  @finally
  {
    free(tab);
  }
  return [FSArray arrayWithRep:[[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count] autorelease]];
} 

- (FSArray *)subpartsOfSize:(NSNumber *)operand
{
  FSArray *r;
  NSInteger i,j,size;
  NSUInteger count = [self count];
  
  VERIF_OP_NSNUMBER(@"subpartsOfSize:")
  
  size = [operand doubleValue];
  
  if (size < 1) FSExecError(@"argument 1 of method \"subpartsOfSize:\" must be a number greater or equal to 1");
  
  r = [FSArray arrayWithCapacity:count];
  
  for (i=0; i < 1+(NSInteger)count-size ; i++)
  {
    FSArray *sub_r = [FSArray arrayWithCapacity:size];
    
    for (j=0; j < size; j++) [sub_r addObject:[self objectAtIndex:i+j]];
    
    [r addObject:sub_r];
  }    
  return r;
}

// -------------------------- transposition ------------------------
- (FSArray *) shape
{
  FSArray *r;
  if ([self count] && [[self objectAtIndex:0] isKindOfClass:[FSArray class]])
  {
    r = [[self objectAtIndex:0] shape];
    [r insertObject:[NSNumber numberWithUnsignedInteger:[self count]] atIndex:0];
    return r;
  }
  else
    return [FSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[self count]]];
}

+ (FSArray *) arrayWithShape:(FSArray *)shape
{
  NSUInteger capacity = [shape count] ? [[shape objectAtIndex:0] doubleValue] : 0;
  NSUInteger i;
  FSArray *r = [FSArray arrayWithCapacity:capacity];
 
  if ([shape count] > 1)
  {
    FSArray *localShape = [shape copy];
    [localShape removeObjectAtIndex:0];
    for (i = 0; i < capacity; i++)
      [r addObject:[FSArray arrayWithShape:localShape]];
    [localShape release];  
  }
  return r;
}

void transpose_rec(NSArray *arrayToTranspose, NSInteger *pos, NSUInteger pos_count, NSUInteger depth, NSInteger *transposition_vector, FSArray *result)
{
//  We construct, into "pos", the position of the terminal element in the resulting array. The position is the list of index (indexing start at 0) that marks the position of the element inside the array for each level of sub arrays.

// Dans pos, on construit la position de l'element terminal dans le tableau resultat. La position est la suite d'indice (indices commencant a 0) reperant la place de l'element dans le tableau pour chaque niveau d'imbrication de sous tableaux. 

  NSUInteger i,j;
  FSArray *target;
  
  NSUInteger arrayToTranspose_count = [arrayToTranspose count]; 
  // may raise if arrayToTranspose is not an FSArray
  
  if (depth == pos_count-1)
  {
    for (i = 0; i < arrayToTranspose_count; i++)
    {
      pos[transposition_vector[depth]] = i;
      
      for (j = 0, target = result; j < pos_count-1; j++)
        target = [target objectAtIndex:pos[j]];

      [target addObject:[arrayToTranspose objectAtIndex:i]];
      // may raise if arrayToTranspose is not an FSArray  
    }
  }
  else
  {
    for (i = 0; i < arrayToTranspose_count; i++)
    {
      pos[transposition_vector[depth]] = i;

      transpose_rec([arrayToTranspose objectAtIndex:i], pos, pos_count, depth+1,transposition_vector,result);
      // may raise if arrayToTranspose is not an FSArray
    }
  } 
} 

- (FSArray *)transposition:(FSArray *)operand // deprecated
{
  return [self transposedBy:operand];
}

- (FSArray *)transposedBy:(NSArray *)operand
{
  FSArray *r;
  FSArray *r_shape;
  FSArray *shape = [self shape];
  NSInteger   *pos;
  FSArray *transposition_vector_array;
  NSInteger *transposition_vector;
  NSUInteger i;
  NSString *logText;
  
  // operand must be an FSArray
  VERIF_OP_NSARRAY(@"transposedBy:")

  // operand must be a permutation of the integers in range [0..numbers of dimensions of the receiver-1]  
  if ([operand count] != [shape count] || [[operand intersection:[shape index]] count] != [shape count])
  {
    if ([shape count] != [operand count]) 
      FSExecError(@"argument 1 of method \"transposedBy:\": bad size");
    else
      FSExecError(@"argument 1 of method \"transposedBy:\" must be a permutation of the "
                  @"integers in range [0..numbers of dimensions of the receiver-1]");
  }

  r_shape = [shape at:operand];
  r = [FSArray arrayWithShape:r_shape]; 

  pos  = malloc(sizeof(NSInteger)*[operand count]);

  transposition_vector_array = [operand sort];
  transposition_vector = malloc(sizeof(NSInteger)*[transposition_vector_array count]);

  for (i = 0; i < [transposition_vector_array count]; i++)
    transposition_vector[i] = [[transposition_vector_array objectAtIndex:i] doubleValue];

  logText = @"receiver of message \"transposedBy:\" must be an array structured as an hypercube";
  
  @try
  {
    transpose_rec(self, pos, [r_shape count], 0, transposition_vector, r);
  }
  @catch (id exception)
  {
    FSExecError(logText);
  }
  @finally
  {
    free(pos);
    free(transposition_vector);
  }
     
  return r;
}

//----------------------- end of tranposition -------------------


- (FSArray *)union:(NSArray *)operand
{
  NSUInteger i, op_count;
  BOOL no_nil = YES;
  NSMutableSet *set = [NSMutableSet set];
  FSArray *r;
  NSUInteger count = [self count];
  
  VERIF_OP_NSARRAY(@"union:");
  
  for (i=0; i <count; i++)
  {
    id elem = [self objectAtIndex:i];
   
    if (elem) [set addObject:elem];
    else      no_nil = NO;
  }
  
  op_count = [operand count];
  
  for (i=0; i <op_count; i++)
  {
    id elem = [operand objectAtIndex:i];
    if (elem) [set addObject:elem];
    else      no_nil = NO;
  }    

  r = [[[FSArray alloc] initWithArray:[set allObjects]] autorelease];
  
  if (!no_nil) [r addObject:nil];
    
  return r;        
}

- (FSArray *)where:(NSArray *)booleans
{
  NSUInteger count = [self count];
  
  if (!booleans) FSExecError(@"argument of method \"where:\" must not be nil");    
  
  if (![booleans isKindOfClass:[NSArray class]]) FSExecError([NSString stringWithFormat:@"argument of method \"where:\" is %@. An array was expected", descriptionForFSMessage(booleans)]);
  
  if (count != [booleans count]) FSExecError(@"receiver and argument of method \"where:\" must be arrays of same size");
  
  if ([self isKindOfClass:[FSArray class]] && [[(FSArray *)self arrayRep] respondsToSelector:@selector(where:)])
    return [[(FSArray *)self arrayRep] where:booleans];
  else
  {  
    FSArray *result = [FSArray array];;
    NSUInteger i;
    id boolean;
    
    for (i = 0; i < count; i++) 
    {
      boolean = [booleans objectAtIndex:i];
      
      if (boolean == fsFalse || boolean == nil) 
        continue;
      else if (boolean == fsTrue)
        [result addObject:[self objectAtIndex:i]];
      else if ([boolean isKindOfClass:[FSBoolean class]])
      {
        if ([boolean isTrue])
          [result addObject:[self objectAtIndex:i]];
      }
      else
        FSExecError(@"argument of method \"where:\" must be an array of booleans");
    }
    return result;
  }
}  


//////////////////////////////////// NON USER METHODS


- (NSString *)descriptionLimited:(NSUInteger)nbElem
{
  NSMutableString *str;
  NSString *elemStr = @""; // W
  NSUInteger i;
  NSUInteger lim = MIN([self count],nbElem); 

  if ([self isKindOfClass:[FSArray class]]) str = [NSMutableString stringWithString:@"{"];
  else str = [NSMutableString stringWithFormat:@"%@ {", [self class]];
  
  if (lim > 0)
  {
    elemStr = printString([self objectAtIndex:0]);
    [str appendString:elemStr];  
  }          
    
  for (i = 1; i < lim; i++)
  {
    [str appendString:@", "];
    if ([elemStr length] > 20) [str appendString:@"\n"];
    
    elemStr = printString([self objectAtIndex:i]);
    [str appendString:elemStr];      
  }
  
  if ([self count] > nbElem) [str appendFormat:@", ... (%lu more elements)",(unsigned long)([self count]-nbElem)];
  [str appendString:@"}"];
  return str; 
}

///////////////////////////////// PRIVATE FOR USE BY FSExecEngine ///////////////

-(NSUInteger) _ul_count  { return [self count]; }

- _ul_objectAtIndex:(NSUInteger)index { return [self objectAtIndex:index];}

@end
