/* FSNSMutableArray.m Copyright (c) 2003-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSNSMutableArray.h"
#import "FSBooleanPrivate.h"
#import "FSArray.h"
#import "FSMiscTools.h"
#import "FScriptFunctions.h"
#import "NumberPrivate.h"
#import "FSNSArrayPrivate.h"

@implementation NSMutableArray(FSNSMutableArray)

- (void)add:(id)elem 
{
  [self addObject:elem];
}

- (id)at:(id)index put:(id)elem
{
  double ind;
  NSUInteger count = [self count];
    
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
    
    [self replaceObjectAtIndex:ind withObject:elem];
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
          [self replaceObjectAtIndex:i withObject:elemIsArray ? [elem objectAtIndex:j] : elem];
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
        [self replaceObjectAtIndex:ind withObject:elemIsArray ? [elem objectAtIndex:i] : elem];
        i++;
        while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
      }
    }  
    else // elem_index is neither an NSNumber nor a FSBoolean
      FSExecError([NSString stringWithFormat:@"array indexing by an array containing %@", descriptionForFSMessage(elem_index)]);
  }
  else
    FSExecError([NSString stringWithFormat:@"array indexing by %@, number, array or index set expected", descriptionForFSMessage(index)]);
    
  return elem;
}

-(void)insert:(id)obj at:(NSNumber *)index
{
  double ind;
  
  FSVerifClassArgs(@"insert:at:",2,obj,(id)nil,(NSInteger)1,index,NSNumberClass,(NSInteger)0);
            
  ind = [index doubleValue];
               
  if (ind < 0)               FSExecError(@"argument 2 of method \"insert:at:\" must be a number greater or equal to 0");
  if (ind > [self count])    FSExecError(@"argument 2 of method \"insert:at:\" must be a number less or equal to the size of the array");
  if (ind != (NSInteger)ind) FSExecError(@"argument 2 of method \"insert:at:\" must be an integer");

  [self insertObject:obj atIndex:(NSUInteger)ind]; 
  return;    
} 

- (void)removeAt:(id)index
{
  NSUInteger count = [self count];
  id indexSet;

  if (!index) FSExecError(@"index of an array must not be nil");    

  if ([index isKindOfClass:[NSNumber class]])
  {      
    double ind = [index doubleValue];

    if (ind < 0)               FSExecError(@"argument of method \"removeAt:\" must be a number greater or equal to 0");
    if (ind >= count)          FSExecError(@"argument of method \"removeAt:\" must be a number less than the size of the array");
    if (ind != (NSInteger)ind) FSExecError(@"argument of method \"removeAt:\" must be an integer");

    [self removeObjectAtIndex:(NSUInteger)ind];
    return;
  }
  else if ([index isKindOfClass:[NSArray class]])
  {
    NSUInteger nb = [index count];
    NSUInteger i = 0;
    
    indexSet = [NSMutableIndexSet indexSet];
                
    while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
    
    if (i == nb)
    {
      if (nb == count || nb == 0)  return;
      else FSExecError(@"invalid index");
    }
    
    id elem_index = [index objectAtIndex:i];

    if ([elem_index isKindOfClass:[FSBoolean class]])
    {
      
      if (nb != count) FSExecError(@"indexing with an array of boolean of bad size");
                                         
      while (i < nb)
      {
        elem_index = [index objectAtIndex:i];
        
        if (elem_index == fsTrue || (elem_index != fsFalse && [elem_index isKindOfClass:[FSBoolean class]] && [elem_index isTrue]) )
          [indexSet addIndex:i];
        else if (elem_index != fsFalse && ![elem_index isKindOfClass:[FSBoolean class]]) 
          FSExecError(@"indexing with a mixed array");
        
        i++;
        while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
      }
    }  
    else if ([elem_index isKindOfClass:[NSNumber class]])
    {
      NSUInteger k;
      double ind;
      
      for (k=i; k<nb; k++)
      {
        elem_index = [index objectAtIndex:k];
        if (![elem_index isKindOfClass:[NSNumber class]]) FSExecError(@"indexing with a mixed array");
        ind = [elem_index doubleValue];
        if (ind < 0) FSExecError(@"index of an array must be a number greater or equal to 0");              
        else if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");                                                
      }      
      
      while (i < nb)
      {        
        elem_index = [index objectAtIndex:i];
        ind = [elem_index doubleValue];        
        [indexSet addIndex:ind];
        i++;
        while (i < nb && ![index objectAtIndex:i]) i++; // ignore the nil value
      }
    }  
    else // elem_index is neither an NSNumber nor a FSBoolean
      FSExecError([NSString stringWithFormat:@"indexing with an array containing %@",descriptionForFSMessage(elem_index)]);    
  }
  else if ([index isKindOfClass:[NSIndexSet class]])
  {
    indexSet = index;
  }
  else
    FSExecError([NSString stringWithFormat:@"indexing by %@, number, array or index set expected", descriptionForFSMessage(index)]);

  NSUInteger currentIndex = [indexSet lastIndex];
  while (currentIndex != NSNotFound)
  {
    [self removeObjectAtIndex:currentIndex];
    currentIndex = [indexSet indexLessThanIndex:currentIndex];
  }
}

- (void)removeWhere:(NSArray *)booleans
{
  NSUInteger count = [self count];
  Class FSBooleanClass = [FSBoolean class];
  
  if (!booleans) FSExecError(@"argument of method \"removeWhere:\" must not be nil");    
  
  if (![booleans isKindOfClass:[NSArray class]]) FSExecError([NSString stringWithFormat:@"argument of method \"removeWhere:\" is %@. An array was expected", descriptionForFSMessage(booleans)]);
  
  if (count != [booleans count]) FSExecError(@"receiver and argument of method \"removeWhere:\" must be arrays of same size");
  
  for (NSUInteger i = 0; i < count; i++)
  {
    id boolean = [booleans objectAtIndex:i];
    
    if (boolean != fsFalse && boolean != fsTrue && boolean != nil && ![boolean isKindOfClass:FSBooleanClass]) 
      FSExecError(@"argument of method \"removeWhere:\" must be an array of booleans");
  }
  
  for (NSUInteger i = count; i > 0; i--)
  {
    id boolean = [booleans objectAtIndex:i-1];
    
    if (boolean == fsFalse || boolean == nil) 
      continue;
    else if (boolean == fsTrue || ([boolean isKindOfClass:FSBooleanClass] && [boolean isTrue]))
      [self removeObjectAtIndex:i-1];
  }
}

- (void)setValue:(NSArray *)operand
{
  VERIF_OP_NSARRAY(@"setValue:");
  [self setArray:operand];
}


- (FSArray *)where:(NSArray *)booleans put:(id)elem
{
  NSUInteger count = [self count];
  BOOL elemIsArray = [elem isKindOfClass:[NSArray class]];
  Class FSBooleanClass = [FSBoolean class];
  NSUInteger trueCount = 0;
  
  if (!booleans) FSExecError(@"argument 1 of method \"where:put:\" must not be nil");    
  
  if (![booleans isKindOfClass:[NSArray class]]) FSExecError([NSString stringWithFormat:@"argument 1 of method \"where:put:\" is %@. An array was expected", descriptionForFSMessage(booleans)]);
  
  if (count != [booleans count]) FSExecError(@"receiver and argument 1 of method \"where:put:\" must be arrays of same size");
    
  for (NSUInteger i = 0; i < count; i++)
  {
    id boolean = [booleans objectAtIndex:i];
    
    if (boolean == fsFalse || boolean == nil) 
      continue;
    else if (boolean == fsTrue )
      trueCount++;
    else if ([boolean isKindOfClass:FSBooleanClass])
    {
      if ([boolean isTrue])
        trueCount++;
    }
    else
      FSExecError(@"argument 1 of method \"where:put:\" must be an array of booleans");
  }
  
  if (elemIsArray)
  {
    if      ([elem count] < trueCount) FSExecError(@"argument 2 of method \"where:put:\" has not enough elements");               
    else if ([elem count] > trueCount) FSExecError(@"argument 2 of method \"where:put:\" has too many elements");               
  }
  
  for (NSUInteger i = 0, j = 0; i < count; i++) 
  {
    id boolean = [booleans objectAtIndex:i];
    
    if (boolean == fsTrue || (boolean != fsFalse && [boolean isKindOfClass:FSBooleanClass] && [boolean isTrue]))
    {
      [self replaceObjectAtIndex:i withObject:elemIsArray ? [elem objectAtIndex:j] : elem];
      j++;
    }
  }
  return elem;
}  

@end
