/* ArrayRepBoolean.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h" 

#import "ArrayRepBoolean.h" 
#import "BlockPrivate.h" 
#import "BlockRep.h"
#import "string.h"          // memcpy() 
#import "ArrayPrivate.h"
#import "FSNumber.h" 
#import "FScriptFunctions.h"
#import "FSBooleanPrivate.h"
#import "ArrayRepId.h"
#import "FSCompiler.h"
#import "FSExecEngine.h"

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

@implementation ArrayRepBoolean

////////////////////////////// USER METHODS SUPPORT /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


- (id)operator_backslash:(FSBlock*)bl  // May raise
{
  NSUInteger i;
  id args[3];
  
  if ([bl isCompact]) 
  {
    SEL selector = [bl selector];
    NSString *selectorStr  = [bl selectorStr];
    FSMsgContext *msgContext = [bl msgContext];
    long acu = t[0];

    args[1] = (id)(selector ? selector : [FSCompiler selectorFromString:selectorStr]);

    if (selector == @selector(operator_ampersand:)) 
    {
      for (i = 0; i < count && t[i]; i++);
      return (i == count ? (id)fsTrue : (id)fsFalse);
    }
    else if (selector == @selector(operator_bar:)) 
    {
      for (i = 0; i < count && !t[i]; i++);
      return (i == count ? (id)fsFalse : (id)fsTrue);
    }
    else if (selector == @selector(operator_plus:))      
    {
      for (i = 1; i < count; i++) acu += (t[i] ? 1 : 0);
      return [FSNumber numberWithDouble:acu];
    }
    else
    {
      args[0] = (t[0] ? (id)fsTrue : (id)fsFalse);
      for (i = 1; i < count; i++)
      {
        args[2] = (t[i] ? (id)fsTrue : (id)fsFalse);
        args[0] = sendMsg(args[0], selector, 3, args, nil, msgContext, nil); // May raise
      }
    } // end if
  }
  else
  {
    BlockRep *blRep = [bl blockRep];
    
    args[0] = (t[0] ? (id)fsTrue : (id)fsFalse);
    for (i = 1; i < count; i++)
    {
      args[2] = (t[i] ? (id)fsTrue : (id)fsFalse);
      args[0] = [blRep body_notCompact_valueArgs:args count:3 block:bl];
    }
  }
  return args[0];
}


///////////////////////////// OPTIM ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////


/*-------------------------------------- double loop ----------------------------------*/

// note: for all the doubleLoop... methods, precondition contains: [[operand arrayRep] isKindOfClass:[ArrayRepBoolean class]] && ![operand isProxy]

- (FSArray *)doubleLoop_operator_ampersand:(FSArray *)operand 
{ 
  char *opData = [[operand arrayRep] booleansPtr];
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);

  //NSLog(@"doubleLoop_operator_ampersand:");
 
  resTab = malloc(nb*sizeof(char));
  
  for(i=0; i < nb; i++) resTab[i] = t[i] && opData[i];

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}  
   
- (FSArray *)doubleLoop_operator_bar:(FSArray *)operand
{
  char *resTab;
  NSUInteger i; 
  NSUInteger nb = MIN(count, [operand count]);
  char *opData = [[operand arrayRep] booleansPtr];

  //NSLog(@"doubleLoop_operator_bar:");
 
  resTab = malloc(nb*sizeof(char));
  
  for(i=0; i < nb; i++) 
  {
    resTab[i] = t[i] || opData[i]; 
  }
 
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
} 
   
/*-------------------------------------- simple loop ----------------------------------*/
 
- (FSArray *)simpleLoop_not
{
  char *resTab;  
  NSUInteger i; 

  //NSLog(@"simpleLoop_operator_not"); 

  resTab = malloc(count*sizeof(char));
  for(i=0;i<count;i++) resTab[i] = !t[i];
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}


/////////////////////////////// OTHER METHODS //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


+ (void)initialize
{
    static BOOL tooLate = NO;
    if ( !tooLate ) {
        tooLate = YES;
    }
}
 
- (void)addBoolean:(char)aBoolean
{
  count++;
  if (count > capacity)
  {
    capacity = (capacity+1)*2;
    t = (char *)realloc(t, capacity * sizeof(char));
  }
  t[count-1] = aBoolean;
}


- (ArrayRepId *) asArrayRepId
{
  NSUInteger i;
  
  id *tab = (id *) NSAllocateCollectable(count * sizeof(id), NSScannedOption);
  ArrayRepId *r = [[[ArrayRepId alloc] initWithObjectsNoCopy:tab count:count] autorelease];

  for (i = 0; i < count; i++) tab[i] = (t[i] ? (id)fsTrue : (id)fsFalse);
  return r;
}

- (char *)booleansPtr {return t;}

- copyWithZone:(NSZone *)zone
{
  return [[ArrayRepBoolean allocWithZone:zone] initWithBooleans:t count:count];  
}

- (NSUInteger)count {return count;}

- (void)dealloc
{
  free(t);
  [super dealloc];
} 

- (void)finalize 
{
  free(t);
  [super finalize];
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical
{
  if (range.length == 0 || (identical && !(anObject == fsTrue || anObject == fsFalse)) || ![anObject isKindOfClass:[FSBoolean class]]) return NSNotFound;
  else
  {
    NSUInteger i = range.location;
    NSUInteger end = (range.location + range.length -1);
    char val = ([anObject isTrue] ? 1:0);

    while (i <= end && t[i] != val)
    {
      i++;
    }   
    return (i > end) ? NSNotFound : i;
  }    
}

- init { return [self initWithCapacity:0]; }

- initFilledWithBoolean:(char)elem count:(NSUInteger)nb // contract: a return value of nil means not enough memory
{
  if (self = [self initWithCapacity:nb])
  {    
    for (count = 0; count < nb; count++) t[count] = elem; 
    return self;
  }
  return nil;
}

- initWithCapacity:(NSUInteger)aNumItems // contract: a return value of nil means not enough memory  
{
  if ((self = [super init]))
  {
    t = malloc(aNumItems*sizeof(char));
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

- initWithBooleans:(char *)elems count:(NSUInteger)nb
{  
  if (self = [self initWithCapacity:nb])
  {
    memcpy(t,elems,nb*sizeof(char));
    count = nb;
    return self;
  }
  return nil;
}

- initWithBooleansNoCopy:(char *)tab count:(NSUInteger)nb
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

- (void)removeLastElem
{
  count--;
  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (char *)realloc(t, capacity * sizeof(char));
  }    
}

- (void)removeElemAtIndex:(NSUInteger)index
{      
  count--;
  
  memmove( &(t[index]), &(t[index+1]), (count-index) * sizeof(char));
 
  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (char *)realloc(t, capacity * sizeof(char));
  }
}

- (void)replaceBooleanAtIndex:(NSUInteger)index withBoolean:(char)aBoolean
{
  t[index] = aBoolean;   
}  

- (id)retain                 { retainCount++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (oneway void)release              { if (--retainCount == 0) [self dealloc];}  

- (NSArray *)subarrayWithRange:(NSRange)range
{  
  ArrayRepBoolean *resRep; 
  FSArray *r;
  
  resRep = [[ArrayRepBoolean alloc] initWithBooleans:t+range.location count:range.length];
  r = [FSArray arrayWithRep:resRep];
  [resRep release];
  return r;   
}

- (enum ArrayRepType)repType {return BOOLEAN;}

@end
