/*   ArrayRepEmpty.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "ArrayRepEmpty.h"
#import "Number_fscript.h"
#import "ArrayRepId.h"
#import "ArrayRepDouble.h"
#import "ArrayRepBoolean.h" 
#import "FSArray.h"
#import "ArrayPrivate.h"

@implementation ArrayRepEmpty


////////////////////////////// USER METHODS SUPPORT /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

- (id)operator_backslash:(FSBlock*)operand {return nil;}

- (FSArray *)replicateWithArray:(FSArray *)operand {return [FSArray array];} 

- (FSArray *)reverse {return [FSArray array];}

- (FSArray *)scan:(FSBlock*)operand {return [FSArray array];}
   
- (FSArray *)sort    {return [FSArray array];} 

/////////////////////////////// OTHER METHODS //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

+ arrayRepEmptyWithCapacity:(NSUInteger)aNumItems
{
  return [[[self alloc] initWithCapacity:aNumItems] autorelease];
}

+ (void)initialize
{
    static BOOL tooLate = NO;
    if ( !tooLate ) {
        tooLate = YES;
    }
}

- (ArrayRepBoolean *) asArrayRepBoolean { return [[[ArrayRepBoolean alloc] initWithCapacity:capacity] autorelease]; }

- (ArrayRepDouble *) asArrayRepDouble   { return [[[ArrayRepDouble alloc] initWithCapacity:capacity] autorelease];  }

- (ArrayRepId *)     asArrayRepId       { return [[[ArrayRepId     alloc] initWithCapacity:capacity] autorelease];  }

- copyWithZone:(NSZone *)zone
{
  return [[ArrayRepEmpty allocWithZone:zone] initWithCapacity:capacity];  
}

- (NSUInteger)count {return 0;}

- (NSString *)descriptionLimited:(NSUInteger)nbElem { return @"{}" ; }

- indexWithArray:(FSArray *)index {return [FSArray array];}

- init { return [self initWithCapacity:0]; }

- initWithCapacity:(NSUInteger)aNumItems
{
  if ((self = [super init]))
  {
    retainCount = 1;
    capacity = aNumItems;
    return self;
  }
  return nil;    
}
 
- (void)removeLastElem {assert(0);}

- (void)removeElemAtIndex:(NSUInteger)index {assert(0);}

- (id)retain               { retainCount++; return self; }

- (NSUInteger)retainCount  { return retainCount; }

- (oneway void)release            { if (--retainCount == 0) [self dealloc]; }  

- (NSArray *)subarrayWithRange:(NSRange)range {assert(0); return nil; /*return something in order to avoid a compiler warning */}

- (enum ArrayRepType)repType {return EMPTY;}

@end
