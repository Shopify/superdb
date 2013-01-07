/* ArrayRepDouble.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "build_config.h"

#import "BlockPrivate.h"
#import "BlockRep.h"
#import "ArrayRepDouble.h"
#import <string.h>          // memcpy() 
#import "ArrayPrivate.h"  
#import "FSNumber.h"
#import "NumberPrivate.h"
#import "FScriptFunctions.h"  
#import "FSBooleanPrivate.h"
#import "ArrayRepId.h"
#import "FSCompiler.h"
#import "FSExecEngine.h"
#import "ArrayRepBoolean.h"
#import <math.h>
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

// ignoring these warnings until it can be fixed, for build servers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-w"

struct sort_elem
{
  NSUInteger index;
  double   item;
};

static int comp(const void *a,const void *b)
{
  if      ( ((struct sort_elem *)a)->item < ((struct sort_elem *)b)->item ) return -1;
  else if ( ((struct sort_elem *)b)->item < ((struct sort_elem *)a)->item ) return  1;
  else                                                                      return  0;
}


@implementation ArrayRepDouble




////////////////////////////// USER METHODS SUPPORT /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

- (FSArray *) distinctId
{
  ArrayRepDouble *copy = [self copy];
  FSArray *r = [FSArray arrayWithRep:copy];
  [copy release];
  return r;
}

- (id)operator_backslash:(FSBlock*)bl
{
    NSUInteger i;
    id res;
    id args[3];
    
    if ([bl isCompact]) 
    {
      SEL selector = [bl selector];
      NSString *selectorStr  = [bl selectorStr];
      FSMsgContext *msgContext = [bl msgContext];
      double acu = t[0];

      args[1] = (id)(selector ? selector : [FSCompiler selectorFromString:selectorStr]);

      if (selector == @selector(operator_plus:)) { for (i = 1 ; i < count; i++) acu += t[i]         ; return [FSNumber numberWithDouble:acu]; }
      else if (selector == @selector(max:))      { for (i = 1 ; i < count; i++) acu = MAX(acu, t[i]); return [FSNumber numberWithDouble:acu]; }
      else if (selector == @selector(min:))      { for (i = 1 ; i < count; i++) acu = MIN(acu, t[i]); return [FSNumber numberWithDouble:acu]; }
      else
      {
        @try
        {
          args[0] = [[FSNumber alloc] initWithDouble:t[0]];
          for (i = 1; i < count; i++) 
          {
            args[2] = [[FSNumber alloc] initWithDouble:t[i]];
            res = [sendMsg(args[0], selector, 3, args, nil, msgContext, nil) retain];
            [args[0] release];
            args[0] = res;
            [args[2] release];  
          }
        }
        @catch (id exception)
        {
          [args[0] release];
          [args[2] release];
          @throw;
        }
      } // end if
    }
    else
    {
      BlockRep *blRep = [bl blockRep];

      @try
      {
        args[0] = [[FSNumber alloc] initWithDouble:t[0]];
        for (i = 1; i < count; i++)
        {
          args[2] = [[FSNumber alloc] initWithDouble:t[i]];
          res = [[blRep body_notCompact_valueArgs:args count:3 block:bl] retain]; 
          [args[0] release];
          args[0] = res;
          [args[2] release];  
        }
      }  
      @catch (id exception)
      {
        [args[0] release];
        [args[2] release];
        @throw;
      }  
    }
    return [args[0] autorelease]; 
}

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range identical:(BOOL)identical
{
  if (identical || range.length == 0 || ![anObject isKindOfClass:NSNumberClass]) return NSNotFound;

  double val = [anObject doubleValue];
  NSUInteger i = range.location;
  NSUInteger end = (range.location + range.length - 1);
  
  while (i <= end && t[i] != val) i++;

  return (i > end) ? NSNotFound : i;
}

- (FSArray *)reverse
{ 
  NSUInteger i,j;
  ArrayRepDouble *resRep;
  FSArray *r ;
  double *tab = malloc(sizeof(double) * count); 
  
  for(i = count-1, j = 0; j < count; i--, j++)  tab[j] = t[i];

  resRep = [[ArrayRepDouble alloc] initWithDoublesNoCopy:tab count:count];
  r = [FSArray arrayWithRep:resRep];
  [resRep release];
  
  return r;    
}   

- (FSArray *)replicateWithArray:(FSArray *)operand
{
  NSUInteger i,j;
  ArrayRepDouble *resRep;
  
  assert(![operand isProxy]);
  
  resRep = [[[ArrayRepDouble alloc] init] autorelease];
  
  switch ([operand type])
  {
  case FS_ID:
  {
    id *indexData = [operand dataPtr];
    for (i=0; i < count; i++)
    {
      double opElemDouble; 
    
      if (![indexData[i] isKindOfClass:NSNumberClass]) FSExecError(@"argument of method \"replicate:\" must be an array of numbers");
    
      opElemDouble = [(NSNumber *)(indexData[i]) doubleValue];
    
      if (opElemDouble < 0) FSExecError(@"argument of method \"replicate:\" must not contain negative numbers");
      if (opElemDouble > NSUIntegerMax)
        FSExecError([NSString stringWithFormat:@"argument of method \"replicate:\" must contain numbers less or equal to %lu",(unsigned long)NSUIntegerMax]);
      for (j=0; j < opElemDouble; j++) [resRep addDouble:t[i]];
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
        FSExecError([NSString stringWithFormat:@"argument of method \"replicate:\" must contain numbers less or equal to %lu",(unsigned long)NSUIntegerMax]);
      for (j=0; j < opElemDouble; j++) [resRep addDouble:t[i]];
    }
    break;
  }
  
  case BOOLEAN: 
    if ([operand count] != 0) FSExecError(@"argument of method \"replicate:\" is an array of Booleans. An array of numbers was expected");
    break;
  
  case EMPTY: break;
  
  case FETCH_REQUEST:
    [operand becomeArrayOfId];
    return [self replicateWithArray:operand];
    
  } // end switch
  
  return [FSArray arrayWithRep:resRep];
}

- (FSArray *)sort
{
  NSUInteger i;
  double *resTab;
  struct sort_elem * tab;

  @try
  {
    tab = malloc(count*sizeof(struct sort_elem));
    
    if (count == 0) return [FSArray array]; // mergesort() crash if passed an empty array
    
    for (i = 0; i < count; i++)
    {
      tab[i].index = i;
      tab[i].item = t[i];
    }
    if (mergesort(tab,count,sizeof(struct sort_elem),comp) != 0)
    {
      if (errno == ENOMEM) FSExecError(@"not enough memory");
      else FSExecError(@"F-Script internal error in method -sort (class: ArrayRepDouble)");  // Defensive. Not supposed to happen
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


///////////////////////////// OPTIM ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////


/*-------------------------------------- double loop ----------------------------------*/

// note: for all the doubleLoop... methods, precondition is: [[operand arrayRep] isKindOfClass:[ArrayRepDouble class]] && ![operand isProxy]

- (FSArray *)doubleLoop_operator_asterisk:(FSArray *)operand
{
  double *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  //NSLog(@"doubleLoop_operator_asterisk");
 
  resTab = malloc(nb*sizeof(double));
  
  for(i=0; i < nb; i++) resTab[i] = t[i]*opData[i];

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:nb]] autorelease];
}



- (FSArray *)doubleLoop_operator_hyphen:(FSArray *)operand
{
  double *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  //NSLog(@"doubleLoop_operator_hyphen");
 
  resTab = malloc(nb*sizeof(double));
  
  for(i=0; i < nb; i++) resTab[i] = t[i] - opData[i];

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:nb]] autorelease];
}


- (FSArray *)doubleLoop_operator_plus:(FSArray *)operand
{
  double *resTab;
  NSUInteger i;
  const NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  //NSLog(@"doubleLoop_operator_plus");
 
  resTab = malloc(nb*sizeof(double));
  
  for(i=0; i < nb; i++) resTab[i] = t[i] + opData[i];

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_slash:(FSArray *)operand
{
  double *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  //NSLog(@"doubleLoop_operator_slash");
 
  resTab = malloc(nb*sizeof(double));
  
  for(i=0; i < nb; i++) 
  {
    if (!opData[i]) { free(resTab); FSExecError(@"division by zero"); }
    resTab[i] = t[i]/opData[i];
  }

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_equal:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  //NSLog(@"doubleLoop_operator_equal");
  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] == opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
 
}

- (FSArray *)doubleLoop_operator_tilde_equal:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] != opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_greater:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] > opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_greater_equal:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] >= opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_less:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] < opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}

- (FSArray *)doubleLoop_operator_less_equal:(FSArray *)operand
{
  char *resTab;
  NSUInteger i;
  NSUInteger nb = MIN(count, [operand count]);
  double *opData = [[operand arrayRep] doublesPtr];

  resTab = malloc(nb*sizeof(char));
  for(i=0; i < nb; i++) resTab[i] = (t[i] <= opData[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:nb]] autorelease];
}

/*-------------------------------------- simple loop ----------------------------------*/

- (FSArray *)simpleLoop_abs
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = fabs(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcCos
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if((t[i] < -1.0) || (t[i] > 1.0))  
    {
      free(resTab);
      FSExecError(@"receiver of message \"arcCos\" must be a number between -1 and 1");
    }
    resTab[i] = acos(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcCosh
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if (t[i] < 1.0)  
    {
      free(resTab);
      FSExecError(@"receiver of message \"arcCosh\" must be a number equal to or greater than 1");
    }
    resTab[i] = acosh(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcSin
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if((t[i] < -1.0) || (t[i] > 1.0))
    {
      free(resTab);
      FSExecError(@"receiver of message \"arcSin\" must be a number between -1 and 1");
    }
    resTab[i] = asin(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcSinh
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = asinh(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_atan // obsolete
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = atan(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcTan 
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = atan(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_arcTanh
{
  unsigned i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if((t[i] <= -1.0) || (t[i] >= 1.0))
    {
      free(resTab);
      FSExecError(@"receiver of message \"arcTanh\" must be a number greater than -1 and less than 1");
    }
    resTab[i] = atanh(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_between:(NSNumber *)a and:(NSNumber *)b
{
  char *resTab;
  NSUInteger i;
  double inf,sup;
  
  FSVerifClassArgsNoNil(@"between:and:",2,a,NSNumberClass,b,NSNumberClass);
  
  inf = [a doubleValue]; sup = [b doubleValue];
  if (inf > sup) { double l = inf; inf = sup; sup = l; }    
  resTab = malloc(count*sizeof(char));
  for(i=0; i < count; i++) resTab[i] = (t[i] >= inf && t[i] <= sup);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}


- (FSArray *)simpleLoop_ceiling
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = ceil(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_cos
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = cos(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_cosh
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = cosh(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_erf
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = erf(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_erfc
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = erfc(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_exp
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = exp(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_floor
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = floor(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_fractionPart
{
  NSUInteger i;
  double ip;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = modf(t[i],&ip);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_integerPart
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) modf(t[i],&(resTab[i]));
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_ln
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if (t[i] <= 0)
    {
      free(resTab);
      FSExecError(@"receiver of message \"ln\" must be positive");
    }
    resTab[i] = log(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_log
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if (t[i] <= 0)
    {
      free(resTab);
      FSExecError(@"receiver of message \"log\" must be positive");
    }
    resTab[i] = log10(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_max:(NSNumber *)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"max:")

  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(double));

  for(i=0; i < count; i++) resTab[i] = (opVal >= t[i] ? opVal : t[i]);

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_min:(NSNumber *)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"min:")

  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(double));

  for(i=0; i < count; i++) resTab[i] = (opVal <= t[i] ? opVal : t[i]);

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_negated
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = -t[i];
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_asterisk:(NSNumber *)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"*")

  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(double));
  
  for(i=0; i < count; i++) resTab[i] = t[i] * opVal;

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_hyphen:(NSNumber *)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;
  //NSLog(@"simpleLoop_operator_hyphen:");

  VERIF_OP_NSNUMBER(@"-")

  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(double));
  
  for(i=0; i < count; i++) resTab[i] = t[i]-opVal;

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_plus:(id)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;

  if (!([operand isKindOfClass:NSNumberClass] || operand == fsTrue || operand == fsFalse || [operand isKindOfClass:[FSBoolean class]]))
  {
    FSExecError(@"argument of methode \"+\" must be a number or a Boolean"); return nil; // W
  }

  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(double));
  
  for(i=0; i < count; i++) resTab[i] = t[i]+opVal;

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}


- (FSArray *)simpleLoop_operator_slash:(NSNumber *)operand
{
  double opVal;
  double *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"/")

  opVal = [operand doubleValue];
  if (opVal == 0.0) FSExecError(@"division by zero");
  resTab = malloc(count*sizeof(double));
  for(i=0; i < count; i++) resTab[i] = t[i] / opVal;
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_equal:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  //NSLog(@"simpleLoop_operator_equal:");
  
  if ([operand isKindOfClass:NSNumberClass])
  {
    opVal = [operand doubleValue];
    resTab = malloc(count*sizeof(char));
    for(i=0; i < count; i++) resTab[i] = (t[i] == opVal) ;
    return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
  }
  else return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initFilledWithBoolean:NO count:count]] autorelease]; 
}

- (FSArray *)simpleLoop_operator_tilde_equal:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  if ([operand isKindOfClass:NSNumberClass])
  {
    opVal = [operand doubleValue];
    resTab = malloc(count*sizeof(char));
    for(i=0; i < count; i++) resTab[i] = (t[i] != opVal) ;
    return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
  }  
  else return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initFilledWithBoolean:YES count:count]] autorelease];  
}

- (FSArray *)simpleLoop_operator_greater:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@">")
  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(char));
  for(i=0; i < count; i++) resTab[i] = (t[i] > opVal) ;
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_greater_equal:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@">=")
  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(char));
  for(i=0; i < count; i++) resTab[i] = (t[i] >= opVal) ;
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_operator_less:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"<")
  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(char));
  for(i=0; i < count; i++) resTab[i] = (t[i] < opVal) ;
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}


- (FSArray *)simpleLoop_operator_less_equal:(id)operand
{
  double opVal;
  char *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"<=")
  opVal = [operand doubleValue];
  resTab = malloc(count*sizeof(char));
  for(i=0; i < count; i++) resTab[i] = (t[i] <= opVal) ;
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepBoolean alloc] initWithBooleansNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_rem:(NSNumber *)operand 
{
  double opVal;
  double *resTab;
  NSUInteger i;

  VERIF_OP_NSNUMBER(@"rem:")
  
  opVal = [operand doubleValue];

  if (opVal == 0) FSExecError(@"argument of method \"rem:\" must not be zero");

  resTab = malloc(count*sizeof(double));

  for(i=0; i < count; i++) resTab[i] = fmod(t[i],opVal);

  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_sin
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = sin(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_sinh
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = sinh(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_sqrt
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++)
  {
    if (t[i] < 0)
    {
      free(resTab);
      FSExecError(@"receiver of message \"sqrt\" must not be negative");
    }
    resTab[i] = sqrt(t[i]);
  }
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_tan
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = tan(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_tanh
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = tanh(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

- (FSArray *)simpleLoop_truncated
{
  NSUInteger i;
  double *resTab = malloc(count*sizeof(double));
  for(i=0;i<count;i++) resTab[i] = t[i] > 0 ? floor(t[i]) : ceil(t[i]);
  return [[[FSArray alloc] initWithRepNoRetain:[[ArrayRepDouble alloc] initWithDoublesNoCopy:resTab count:count]] autorelease];
}

/////////////////////////////// OTHER METHODS //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

+ arrayRepDoubleWithCapacity:(NSUInteger)aNumItems
{
  return [[[self alloc] initWithCapacity:aNumItems] autorelease];
}

- (void)addDouble:(double)aDouble
{
  count++;
  if (count > capacity)
  {
    capacity = (capacity+1)*2;
    t = (double *)realloc(t, capacity * sizeof(double));
  }
  t[count-1] = aDouble;
}

- (void)addDoublesFromFSArray:(FSArray *)otherArray
{
  NSUInteger i;
  NSUInteger oldCount = count;
  double *otherArrayData = [(ArrayRepDouble *)[otherArray arrayRep] doublesPtr];
  NSUInteger otherArrayCount = [otherArray count];
   
  count += otherArrayCount;
 
  if (count > capacity)
  {
    capacity = count;
    t = (double*)realloc(t, capacity * sizeof(double));
  }
  
  for (i = 0; i < otherArrayCount; i++) t[oldCount+i] = otherArrayData[i];     
}

- (ArrayRepId *) asArrayRepId
{
  NSUInteger i;
  id *tab = (id *) NSAllocateCollectable(count * sizeof(id), NSScannedOption);
  ArrayRepId *r = [[[ArrayRepId alloc] initWithObjectsNoCopy:tab count:count] autorelease];
  
  for (i = 0; i < count; i++) tab[i] = [[FSNumber alloc] initWithDouble:t[i]];
  return r;
}

- copyWithZone:(NSZone *)zone
{
  return [[ArrayRepDouble allocWithZone:zone] initWithDoubles:t count:count];  
}

- (NSUInteger)count {return count;}

- (void)dealloc
{
  free(t);
  [super dealloc];
} 

- (void)finalize 
{
  //NSLog(@"finalizing an ArrayRepDouble");
  free(t);
  [super finalize];
}

- (double *)doublesPtr {return t;}

- (NSString *)descriptionLimited:(NSUInteger)nbElem
{
  NSMutableString *str = [[@"{" mutableCopy] autorelease];
  NSString *elemStr = @""; // W
  NSUInteger i;
  NSUInteger lim = MIN(count,nbElem);

  if (lim > 0)
  {
    elemStr = [NSString stringWithFormat:@"%.11g",t[0]];
    [str appendString:elemStr];  
  }          
    
  for (i = 1; i < lim; i++)
  {
    [str appendString:@", "];
    if ([elemStr length] > 20) [str appendString:@"\n"];
    
    elemStr = [NSString stringWithFormat:@"%.11g",t[i]];
    [str appendString:elemStr];      
  }
  
  if (count > nbElem ) [str appendFormat:@", ... (%lu more elements)",(unsigned long)(count-nbElem)];
  [str appendString:@"}"];
  return str; 
}

- indexWithArray:(FSArray *)index
{
  assert(![index isProxy]);

  switch ([index type])
  {
  case FS_ID:
  {
    ArrayRepDouble *resRep;
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
      if (nb != count) FSExecError(@"indexing with an array of boolean of bad size");
      
      resRep = [[[ArrayRepDouble alloc] init] autorelease];
            
      while (i < nb)
      {                  
        if (indexData[i] == fsTrue)     [resRep addDouble:t[i]];
        else if (indexData[i] != fsFalse)
        {
          if (![indexData[i] isKindOfClass:[FSBoolean class]]) FSExecError(@"indexing with a mixed array");
          else if ([indexData[i] isTrue]) [resRep addDouble:t[i]];
        }  
        i++;
        while (i < nb && !indexData[i]) i++;            // ignore the nil value
      }
    }  
    else if ([indexData[i] isKindOfClass:NSNumberClass])
    {
      resRep = [ArrayRepDouble arrayRepDoubleWithCapacity:nb];
      
      while (i < nb)
      {                  
        double ind = [indexData[i] doubleValue];
        if (![indexData[i] isKindOfClass:NSNumberClass]) FSExecError(@"indexing with a mixed array");

        /*
        if (ind != (int)ind)
          FSExecError(@"l'indice d'un tableau doit etre un nombre sans "
                       @"partie fractionnaire");      
        */
                
        if (ind < 0)     FSExecError(@"index of an array must be a number greater or equal to 0");              
        if (ind >= count) FSExecError(@"index of an array must be a number less than the size of the array");
        
        [resRep addDouble:t[(NSUInteger)ind]];
        
        i++;
        while (i < nb && !indexData[i]) i++;            // ignore the nil value
      }
    }  
    else // indexData[i] is neither an NSNumber nor a FSBoolean
    {
      FSExecError([NSString stringWithFormat:@"array indexing by an array containing %@",descriptionForFSMessage(indexData[i])]);
      return nil; // W
    }
    return [FSArray arrayWithRep:resRep];
  }
  
  case DOUBLE:
  {
    ArrayRepDouble *resRep;
    double *indexData;
    NSUInteger i = 0;
    NSUInteger nb = [index count];
    double *tab; 
    
    if (i == nb) return [FSArray array];

    indexData = [(ArrayRepDouble *)[index arrayRep] doublesPtr];   
    tab = (double *) malloc(sizeof(double) * nb); 
    resRep = [[[ArrayRepDouble alloc] initWithDoublesNoCopy:tab count:nb] autorelease];
      
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
        
        tab[i] = t[(NSUInteger)ind];
       
        i++;
    }
    return [FSArray arrayWithRep:resRep];
  }
  case BOOLEAN:
  {
    NSUInteger i;
    char *indexData;
    ArrayRepDouble *resRep;

    if ([index count] == 0) return [FSArray array];
    
    if ([index count] != count) FSExecError(@"indexing with an array of booleans of bad size");

    resRep = [[[ArrayRepDouble alloc] init] autorelease]; 
    indexData = [(ArrayRepBoolean *)[index arrayRep] booleansPtr];
 
    for (i = 0; i < count; i++) if (indexData[i]) [resRep addDouble:t[i]]; 

    return [FSArray arrayWithRep:resRep];  
  }
  
  case EMPTY: return [FSArray array];  
  
  case FETCH_REQUEST: 
    [index becomeArrayOfId];
    return [self indexWithArray:index];
      
  } // end switch

  return nil; //W
}

- init { return [self initWithCapacity:0]; }

- initFilledWithDouble:(double)elem count:(NSUInteger)nb // contract: a return value of nil means not enough memory
{
  if (self = [self initWithCapacity:nb])
  {    
    for (count = 0; count < nb; count++) t[count] = elem; 
    return self;
  }
  return nil;
}

- initFrom:(NSUInteger)from to:(NSUInteger)to step:(NSUInteger)step // contract: a return value of nil means not enough memory
{
  if (to < from) return [self init];
  
  if (self = [self initWithCapacity:1+((to-from)/step)])
  {
    double valcou = from;
    count = 0;
    do
    {
      t[count] = valcou;
      valcou += step;
      count++;
    }  
    while (valcou <= to);
    return self;
  }
  return nil;
}          

- initWithCapacity:(NSUInteger)aNumItems // contract: a return value of nil means not enough memory
{
  if (self = [super init])
  {
    t = malloc(aNumItems*sizeof(double));
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

- initWithDoubles:(double *)elems count:(NSUInteger)nb
{  
  if ((self = [self initWithCapacity:nb]))
  {
    memcpy(t,elems,nb*sizeof(double));
    count = nb;
    return self;
  }
  return nil;
}

- initWithDoublesNoCopy:(double *)tab count:(NSUInteger)nb
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

- (void)insertDouble:(double)aDouble atIndex:(NSUInteger)index
{  
  count++ ;

  if (count > capacity)
  {
    capacity = (capacity+1)*2;
    t = (double*)realloc(t, capacity * sizeof(double));
  }

  memmove( &(t[index+1]), &(t[index]), ((count-1)-index) * sizeof(double) );

  t[index] = aDouble;
}    

- (void)removeLastElem
{
  count--;
  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (double *)realloc(t, capacity * sizeof(double));
  }    
}

- (void)removeElemAtIndex:(NSUInteger)index
{      
  count--;
  
  memmove( &(t[index]), &(t[index+1]), (count-index) * sizeof(double) );

  if (capacity/2 >= count+100)
  {
    capacity = capacity/2;
    t = (double *)realloc(t, capacity * sizeof(double));
  }
}

- (void)replaceDoubleAtIndex:(NSUInteger)index withDouble:(double)aDouble
{
  t[index] = aDouble;   
}  

- (id)retain                 { retainCount++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (oneway void)release              { if (--retainCount == 0) [self dealloc];}  

- (NSArray *)subarrayWithRange:(NSRange)range
{  
  ArrayRepDouble *resRep; 
  FSArray *r;
  
  resRep = [[ArrayRepDouble alloc] initWithDoubles:t+range.location count:range.length];
  r = [FSArray arrayWithRep:resRep];
  [resRep release];
  return r;   
}

- (enum ArrayRepType)repType {return DOUBLE;}

- (FSArray *)where:(NSArray *)booleans // precondition: booleans is actualy an array and is of same size as the receiver
{
  ArrayRepDouble *resRep = [[[ArrayRepDouble alloc] init] autorelease]; 
  
  if ([booleans isKindOfClass:[FSArray class]] && [(FSArray *)booleans type] == BOOLEAN)  
  {
    char *rawBooleans = [(ArrayRepBoolean *)[(FSArray *)booleans arrayRep] booleansPtr];     
    
    for (NSUInteger i = 0; i < count; i++) if (rawBooleans[i]) [resRep addDouble:t[i]];  
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
        [resRep addDouble:t[i]];
      else if ([boolean isKindOfClass:[FSBoolean class]])
      {
        if ([boolean isTrue])
          [resRep addDouble:t[i]];
      }
      else
        FSExecError(@"argument of method \"where:\" must be an array of booleans");
    }
  } 
  return [FSArray arrayWithRep:resRep];
}


@end
#pragma clang diagnostic pop