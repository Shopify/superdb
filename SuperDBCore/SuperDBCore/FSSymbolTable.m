/*   FSSymbolTable.m Copyright (c) 1998-2008 Philippe Mougin.  */
/*   This software is open source. See the license.  */  


#import "FSSymbolTable.h"
#import "Number_fscript.h"
#import "FSArray.h"
#import "FSBoolean.h"
#import "Space.h"
#import <Foundation/Foundation.h>
#import "FSUnarchiver.h"
#import "FSKeyedUnarchiver.h"
 
@implementation SymbolTableValueWrapper

+ (void)initialize 
{
  static BOOL tooLate = NO;
  if ( !tooLate )
  {
    [self setVersion:1];
    tooLate = YES; 
  }
}  

- (id)copy
{ return [self copyWithZone:NULL]; }
 
- (id)copyWithZone:(NSZone *)zone
{
  return [[SymbolTableValueWrapper allocWithZone:zone] initWrapperWithValue:value symbol:symbol status:status];
}                             

- (void)dealloc
{ 
  [symbol release];
  [value release];
  [super dealloc]; 
}  

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:status forKey:@"status"];
  [coder encodeObject:value   forKey:@"value"];
  [coder encodeObject:symbol  forKey:@"symbol"];
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  retainCount = 1;

  if ([coder allowsKeyedCoding]) 
  {
    status = [coder decodeIntegerForKey:@"status"];
    value  = [[coder decodeObjectForKey:@"value" ] retain];
    symbol = [[coder decodeObjectForKey:@"symbol"] retain];
  }
  else
  {
  	if ([coder versionForClassName:@"SymbolTableValueWrapper"] == 0)
    {
      [coder decodeIntegerForKey:@"type"];
	}  
    unsigned tmp;
    [coder decodeValueOfObjCType:@encode(typeof(tmp)) at:&tmp];
    status = tmp;
    value  = [[coder decodeObject] retain];
    symbol = [[coder decodeObject] retain];
  }  
  return self;
}

- initWrapperWithValue:(id)theValue symbol:(NSString *)theSymbol
{
  return [self initWrapperWithValue:theValue symbol:theSymbol status:DEFINED];
}  

- initWrapperWithValue:(id)theValue symbol:(NSString *)theSymbol status:(enum FSContext_symbol_status)theStatus
{
  if ((self = [super init]))
  {
    retainCount = 1;
    status = theStatus; 
    value = [theValue retain];
    symbol = [theSymbol retain];
    return self;
  }
  return nil;
}

- (id)retain  { retainCount ++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (oneway void)release  { if (--retainCount == 0) [self dealloc];}  

- (void)setValue:(id)theValue
{
  [theValue retain];
  [value release];
  value = theValue;
}  

- (enum FSContext_symbol_status)status
{ return status;}

- (NSString *)symbol
{ return symbol;}

- (id)value
{ return value;}

@end


/////////////////////////////////////////// FSSymbolTable ///////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////

void __attribute__ ((constructor)) initializeForSymbolTabletoFSSymbolTableTransition(void)
{
#if !TARGET_OS_IPHONE
  [NSUnarchiver decodeClassName:@"SymbolTable" asClassName:@"FSSymbolTable"];
#endif
  [NSKeyedUnarchiver setClass:[FSSymbolTable class] forClassName:@"SymbolTable"];
}


@implementation FSSymbolTable
  
+ (void)initialize 
{
  static BOOL tooLate = NO;
  if ( !tooLate )
  {
    [self setVersion:2];
    tooLate = YES; 
  }
}  
  
+ symbolTable
{
  return [[[self alloc] init] autorelease];
}  
  
//------------------- public methods ---------------

- (FSArray *)allDefinedSymbols
{
  FSArray *r = [FSArray arrayWithCapacity:30];
  for (NSUInteger i = 0; i < localCount; i++)
  {
    if (locals[i].status == DEFINED)
    {
      [r addObject:[NSMutableString stringWithString:locals[i].symbol]];
    }
  }  
  return r;
}  

- (BOOL) containsSymbolAtFirstLevel:(NSString *)theKey 
// Does the receiver contains the symbol (without searching parents)
{
  for (NSUInteger i = 0; i < localCount; i++)
  {
    if ([locals[i].symbol isEqualToString:theKey]) return YES;
  } 
  return NO;  
} 

- (id)copy
{ return [self copyWithZone:NULL]; }

- (id)copyWithZone:(NSZone *)zone
{
  struct FSContextValueWrapper *rLocals = NSAllocateCollectable(localCount * sizeof(struct FSContextValueWrapper), NSScannedOption);
  for (NSUInteger i = 0; i < localCount; i++)
  {
    rLocals[i] = locals[i];
    [rLocals[i].value retain];
    [rLocals[i].symbol retain];    
  }    

  return [[FSSymbolTable allocWithZone:zone] initWithParent:parent tryToAttachWhenDecoding:tryToAttachWhenDecoding locals:rLocals localCount:localCount];          
}  

- (void)dealloc
{
  //NSLog(@"FSSymbolTable dealloc");
  [parent release];
  if (locals)
  { 
    for (NSUInteger i = 0; i < localCount; i++)
    {
      [locals[i].symbol release];
      [locals[i].value release];
    }
    free(locals);
  }
  [super dealloc];
}

- (void) didSendDeallocToSymbolAtIndex:(struct FSContextIndex)index
{
  FSSymbolTable *s = self;
  for (NSUInteger i = 0; i < index.level && s; i++) s = s->parent;
  
  if (s)
  {
    s->locals[index.index].value = nil;
  }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  NSMutableArray *localsArray = [NSMutableArray arrayWithCapacity:localCount];
  for (NSUInteger i = 0; i < localCount; i++)
  {
    [localsArray addObject:[[[SymbolTableValueWrapper alloc] initWrapperWithValue:locals[i].value symbol:locals[i].symbol status:locals[i].status] autorelease]];
  }

  [coder encodeConditionalObject:parent forKey:@"parent"];
  [coder encodeObject:localsArray forKey:@"localsArray"];
  [coder encodeBool:tryToAttachWhenDecoding forKey:@"tryToAttachWhenDecoding"];
} 

- (struct FSContextIndex) findOrInsertSymbol:(NSString*)theKey
// Find the symbol in the highest parent possible (or in self if we don't have a parent) or insert it 
{
  struct FSContextIndex r;
  NSUInteger i;
  
  for  (i = 0; i < localCount; i++)
  {
    if ([locals[i].symbol isEqualToString:theKey]) break;
  }  
  
  if (i == localCount)
  {
    if (parent)
    {
      r = [parent findOrInsertSymbol:theKey];
      r.level++;
      return r;
    }
    else
    {
      return [self insertSymbol:theKey object:nil status:UNDEFINED];
    }  
  }    
  else
  {
    r.level = 0; r.index = i;
    return r;
  }    
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  retainCount = 1;
  receiverRetained = YES;
  
  if ([coder allowsKeyedCoding]) 
  {
    parent = [[coder decodeObjectForKey:@"parent"] retain];
    NSArray *localsArray = [coder decodeObjectForKey: @"localsArray"]; // Try with the new key
    if (!localsArray) localsArray = [coder decodeObjectForKey: @"valueWrappers"]; // Try with the old key
    localCount = [localsArray count];
    locals = NSAllocateCollectable(localCount * sizeof(struct FSContextValueWrapper), NSScannedOption);
    for (NSUInteger i = 0; i < localCount; i++)
    {
      locals[i].status = [((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) status]; 
      locals[i].value  = [[((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) value] retain]; 
      locals[i].symbol = [[((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) symbol] retain]; 
    }    
    tryToAttachWhenDecoding = [coder decodeBoolForKey:@"tryToAttachWhenDecoding"];
    if (tryToAttachWhenDecoding && !parent && [coder isKindOfClass:[FSKeyedUnarchiver class]])
      parent = [[(FSKeyedUnarchiver *)coder loaderEnvironmentSymbolTable] retain];  
  }
  else
  {
    parent = [[coder decodeObject] retain];
    
    if ([coder versionForClassName:@"SymbolTable"] == 0)
    {
      id *loc;
      unsigned int locCount;
      //NSLog(@"version == 0");
      [coder decodeValueOfObjCType:@encode(typeof(locCount)) at:&locCount];
      loc = malloc(locCount*sizeof(id));
      [coder decodeArrayOfObjCType:@encode(id) count:locCount at:loc];
      free(loc);
    }  
  
    if ([coder versionForClassName:@"SymbolTable"] <= 1)
    { 
      [coder decodeObject]; // Read the old "symbtable" NSDictionary
    }
    else
    {
      NSArray *localsArray = [coder decodeObject];
      localCount = [localsArray count];
      locals = NSAllocateCollectable(localCount * sizeof(struct FSContextValueWrapper), NSScannedOption); 
      for (NSUInteger i = 0; i < localCount; i++)
      {
        locals[i].status = [((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) status]; 
        locals[i].value  = [[((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) value] retain]; 
        locals[i].symbol = [[((SymbolTableValueWrapper *)[localsArray objectAtIndex:i]) symbol] retain]; 
      }    
    }        
    [coder decodeValueOfObjCType:@encode(typeof(tryToAttachWhenDecoding)) at:&tryToAttachWhenDecoding];
    if (tryToAttachWhenDecoding && !parent && [coder isKindOfClass:[FSUnarchiver class]])
      parent = [[(FSUnarchiver *)coder loaderEnvironmentSymbolTable] retain];
  }  
  return self;
}

- (struct FSContextIndex)indexOfSymbol:(NSString*)theKey
{
  struct FSContextIndex r;
  NSUInteger i;
  
  for  (i = 0; i < localCount; i++)
  {
    if ([locals[i].symbol isEqualToString:theKey]) break;
  }  
      
  if (i == localCount)
  {
    if (parent)
    {
      r = [parent indexOfSymbol:theKey];
      if (r.index != -1)
        r.level++;
      return r;
    }
    else
    {
      r.index = -1;
      r.level = 0; // In order to avoid a compiler warning "r.level is used uninitialized"
      return r;
    } 
  }    
  else
  {
    r.level = 0; r.index = i;
    return r;
  }    
}      

- init
{
  return [self initWithParent:nil];
}

- initWithParent:(FSSymbolTable *)theParent
{
  return [self initWithParent:theParent tryToAttachWhenDecoding:YES];
}

- initWithParent:(FSSymbolTable *)theParent tryToAttachWhenDecoding:(BOOL)shouldTry
{
  return [self initWithParent:theParent tryToAttachWhenDecoding:shouldTry locals:NULL localCount:0];
} 

- initWithParent:(FSSymbolTable *)theParent tryToAttachWhenDecoding:(BOOL)shouldTry locals:(struct FSContextValueWrapper *)theLocals localCount:(NSUInteger)theLocalCount
{
  if ((self = [super init]))
  {
    retainCount = 1; 
    parent = [theParent retain];
    localCount = theLocalCount;
    locals = theLocals;
    tryToAttachWhenDecoding = shouldTry;
    receiverRetained = YES;
    return self;
  }
  return nil;
}

- (struct FSContextIndex)insertSymbol:(NSString*)symbol object:(id)object
{
  return [self insertSymbol:symbol object:object status:DEFINED];
}
                                   
                                   
-(struct FSContextIndex) insertSymbol:(NSString*)symbol object:(id)object status:(enum FSContext_symbol_status)status                                   
{
  struct FSContextIndex r;
  if (!locals) locals = NSAllocateCollectable(sizeof(struct FSContextValueWrapper), NSScannedOption);
  else locals = NSReallocateCollectable(locals, (localCount+1)*sizeof(struct FSContextValueWrapper), NSScannedOption);
  
  locals[localCount].status = status; 
  locals[localCount].value  = [object retain];
  locals[localCount].symbol = [symbol retain]; 
  
  //[[NSNotificationCenter defaultCenter] postNotificationName:@"changed" object:self];   
  r.index = localCount; r.level = 0;
  localCount++;
  return r;      
}      

- (BOOL) isEmpty  { return (localCount == 0);}

- objectForIndex:(struct FSContextIndex)index isDefined:(BOOL *)isDefined
{
  FSSymbolTable *s = self;
  
  for (NSUInteger i = 0; i < index.level && s; i++) s = s->parent;
  
  if (s)
  {
    if (s->locals[index.index].status == DEFINED)
    {
      *isDefined = YES;
      return s->locals[index.index].value;
    }
  }
  *isDefined = NO;
  return nil;
}

- (id)objectForSymbol:(NSString *)symbol found:(BOOL *)found // foud may be passed as NULL
{
  struct FSContextIndex ind = [self indexOfSymbol:symbol];
  
  if (ind.index == -1) 
  {
    if (found) *found = NO; 
    return nil;
  }
  else
  {
    BOOL isDefined;
    id r = [self objectForIndex:ind isDefined:&isDefined];
    if (isDefined)
    {
      if (found) *found = YES;
      return r;
    }
    else 
    {
      if (found) *found = NO;
      return nil;
    } 
  } 
}

- (FSSymbolTable*) parent  { return parent;}  

- (id)retain  { retainCount ++; return self;}

- (NSUInteger)retainCount  { return retainCount;}

- (oneway void)release  { if (--retainCount == 0) [self dealloc];}  

- (void) removeAllObjects
{
  for (NSUInteger i = 0; i < localCount; i++)
  {
    locals[i].status = UNDEFINED;
    [locals[i].value release];
    locals[i].value = nil;
  }    
}

-(void)setObject:(id)object forSymbol:(NSString *)symbol
{
  struct FSContextIndex ind = [self indexOfSymbol:symbol];

  if (ind.index == -1) [self insertSymbol:symbol object:object];
  else                 [self setObject:object forIndex:ind];
}

- (void) setParent:(FSSymbolTable *)theParent
{
  if (theParent == parent) return;
  
  [theParent retain];
  [parent release];
  //[parent autorelease];
  parent = theParent;
}  

- (void)setToNilSymbolsFrom:(NSUInteger)ind
{
  while (ind < localCount)
  {
    [locals[ind].value release];
    locals[ind].value = nil;
    locals[ind].status = DEFINED;    
    ind++;
  }    
}


- setObject:(id)object forIndex:(struct FSContextIndex)index
{
  NSInteger i; 
  FSSymbolTable *s = self;

  for (i = 0; i < index.level && s; i++) s = s->parent; 
  
  if (s)
  {
    [object retain]; // (1)
    
    if (index.index != 0 || s->receiverRetained) 
    {
      // We are assigning to a regular variable (i.e., not to a "self" pointing to a non-retained receiver).
      // Therefore, we release the old value, as usual. 
      
      [s->locals[index.index].value release];
    }
    else     
    {
      // We are assigning to a "self" pointing to a non-retained receiver (we know that because a symbol table with receiverRetained == NO
      // is a symbol table used for method execution, and the index for "self" in such tables is always 0). 
      // Therefore, we don't release the old value (i.e., the non-retained receiver).
      // The new value for "self" has been retained in (1). We note that in the receiverRetained ivar.

      s->receiverRetained = YES;
    }

    s->locals[index.index].value = object; 
    s->locals[index.index].status = DEFINED;
    return self;
  }  
  else return nil;
}

- (NSString *) symbolForIndex:(struct FSContextIndex)index
{
  FSSymbolTable *s = self;
  
  for (NSUInteger i = 0; i < index.level && s; i++) s = s->parent;
  
  if (s) return s->locals[index.index].symbol;
  else   return nil;
}


-(void) undefineSymbolAtIndex:(struct FSContextIndex)index
{
  FSSymbolTable *s = self;
  for (NSUInteger i = 0; i < index.level && s; i++) s = s->parent;

  if (s)
  {
    s->locals[index.index].status = UNDEFINED;
    [s->locals[index.index].value release];
    s->locals[index.index].value = nil;
  }
}

- (void) willSendReleaseToSymbolAtIndex:(struct FSContextIndex)index
{
  FSSymbolTable *s = self;
  for (NSUInteger i = 0; i < index.level && s; i++) s = s->parent;
  
  if (s && index.index == 0 && !s->receiverRetained)
  {
    // We are informed that a release message is going to be sent to a "self" pointing to a non-retained receiver (we know that because a symbol table 
    // with receiverRetained == NO is a symbol table used for method execution, and the index for "self" in such tables is always 0).
    // Such receivers are non retained because they might be uninitialized objects (if we are executing an init... method defined in F-Script).
    // However, to follow the F-Script language semantics, if they are actualy not unitialized they must act as if they where retained. 
    // The release message might lead to a premature dealloction, and consequently break correct semantic. We retain this receiver in
    // order to avoid such premature deallocation. Note that we can safely retain it because the fact it is going to receive a release
    // message means that it is not actually an uninitialized object (unless there is programming error in the F-Script user code of course).
    [s->locals[0].value retain];
    s->receiverRetained = YES; 
  }
}
                                                                                
@end

