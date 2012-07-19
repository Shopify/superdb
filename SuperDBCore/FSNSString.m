/* FSNSString.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "Number_fscript.h" 
#import "FSNSString.h"
#import "FSSymbolTable.h"
#import "FSBlock.h"
#import "FSArray.h"
#import "FScriptFunctions.h"
#import "FSBoolean.h"
#import "FSBooleanPrivate.h"
#import "FSNSStringPrivate.h"
#import "FSMiscTools.h"
#import "FSSystem.h"
#import "FSInterpreter.h"

@implementation NSString (FSNSString)

///////////////////////////////// USER METHODS /////////////////////////////

- (FSArray *) asArray
{
  FSArray *r = [FSArray arrayWithCapacity:[self length]];
  NSRange range,comp_range;
  NSUInteger self_length = [self length];
  
  range.location = range.length = 0;
  while (range.location < self_length && (comp_range = [self rangeOfComposedCharacterSequenceAtIndex:range.location]).length) 
  {
    [r addObject:[NSMutableString stringWithString:[self substringWithRange:comp_range]]];
    range.location = comp_range.location+comp_range.length;
  }
  return r;
}

- (FSArray *) asArrayOfCharacters
{
  NSUInteger self_length ;
  FSArray *r = [FSArray arrayWithCapacity:[self length]];
  NSUInteger i;
  
  for(i=0, self_length = [self length]; i < self_length; i++)
  {
    unichar c = [self characterAtIndex:i];
    [r addObject:[NSMutableString stringWithCharacters:&c length:1]]; 
  } 
  return r;
}

- (FSBlock *) asBlock
{
  FSInterpreter *interpreter = [FSInterpreter interpreter];
  FSSystem *sys = [interpreter objectForIdentifier:@"sys" found:NULL];
  FSBlock *result = [sys blockFromString:self]; // May raise
  
  [result setInterpreter:interpreter];
  return result;
}

- (FSBlock *) asBlockOnError:(FSBlock *)errorBlock
{
  FSVerifClassArgsNoNil(@"asBlockOnError:",1,errorBlock,[FSBlock class]); 
  {
    FSInterpreter *interpreter = [FSInterpreter interpreter];
    FSSystem *sys = [interpreter objectForIdentifier:@"sys" found:NULL];
    FSBlock *bl = [@"[:msg :start :stop| {msg, start, stop}]" asBlock];
    id result = [sys blockFromString:self onError:bl]; // May raise
  
    if ([result isKindOfClass:[FSArray class]]) 
      result = [errorBlock value:[result objectAtIndex:0] value:[result objectAtIndex:1] value:[result objectAtIndex:2]];
    else
      [result setInterpreter:interpreter];
    
    return result;
  }  
}

- (id)asClass { return NSClassFromString(self); }

- (NSDate *) asDate { 
#if TARGET_OS_IPHONE
  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
  return [formatter dateFromString:self];
#else
  return [NSDate dateWithNaturalLanguageString:self]; 
#endif
}

/*-(id) asPointer
{
  id r;
  sscanf([self cString],"%p",&r);
  return r;
}*/

- (NSString *)at:(NSNumber *)operand
{
  double ind;
  NSRange range;
  id index = operand; 
      
  if (index == nil) FSExecError(@"index of a string must not be nil"); 
  
  if (! ([index isKindOfClass:[NSNumber class]] || [index isKindOfClass:[FSArray class]]) )
    FSExecError([NSString stringWithFormat:@"string indexing by %@, number or array expected", descriptionForFSMessage(operand)]);
                                                   
  if ([index isKindOfClass:[NSNumber class]])
  {
    unichar carac;    

    ind = [index doubleValue];
                                              
    if (ind < 0)              FSExecError(@"index of a string must be a number greater or equal to 0");
    if (ind >= [self length]) FSExecError(@"index of a a string must be a number less than the length of the string");
    if (ind != (NSInteger)ind)      FSExecError(@"index of a string must be an integer");    
  
    //range.location = ind-1; range.length =1;
    //return [[[String alloc] initWithString:[self substringWithRange:range]] autorelease];
    carac = [self characterAtIndex:ind];  
    return [[[NSMutableString alloc] initWithCharacters:&carac length:1] autorelease]; 
  }
  else     // [index isKindOfClass:[FSArray class]]
  {
    NSMutableString *r;
    NSUInteger i,nb;
    id elem_index;
    
    i = 0;
    nb = [index count];
    
    while (i < nb && [index objectAtIndex:i] == nil) i++; // ignore the nil value
    
    if (i == nb) return (id)[NSMutableString string];
    
    elem_index = [index objectAtIndex:i];

    if ([elem_index isKindOfClass:[FSBoolean class]])
    {
      if (nb != [self length]) FSExecError(@"indexing with an array of boolean of bad size");
      r = (id)[NSMutableString string];
      
      while (i < nb)
      {
        elem_index = [index objectAtIndex:i];          
        range.location = i; range.length =1;
        
        if (elem_index != fsTrue && elem_index != fsFalse && ![elem_index isKindOfClass:[FSBoolean class]])
          FSExecError(@"indexing with a mixed array");        
        else if ([elem_index isTrue]) [r appendString:[self substringWithRange:range]];          
        i++;
        while (i < nb && [index objectAtIndex:i] == nil) i++; // ignore the nil value
      }
    }  
    else if ([elem_index isKindOfClass:[NSNumber class]])
    {
      r = [NSMutableString stringWithCapacity:nb];
      while (i < nb)
      {        
        elem_index = [index objectAtIndex:i];
        if (![elem_index isKindOfClass:[NSNumber class]])
          FSExecError(@"indexing with a mixed array");
        
        ind = [elem_index doubleValue];
                                               
        if (ind < 0)              FSExecError(@"index of a string must be a number greater or equal to 0");              
        if (ind >= [self length]) FSExecError(@"index of a a string must be a number less than the length of the string");
        if (ind != (NSInteger)ind)      FSExecError(@"index of a string must be an integer");    

        range.location = ind; range.length =1;
        [r appendString:[self substringWithRange:range]];
        
        i++;
        while (i < nb && [index objectAtIndex:i] == nil) i++; // ignore the nil value
      }
    }  
    else // elem_index is neither an NSNumber nor a FSBoolean
    {
      FSExecError([NSString stringWithFormat:@"string indexing by an array containing %@"
                                            ,descriptionForFSMessage(elem_index)]);
      return nil; // To avoid a compiler warning
    }
    return r;   
  }         
} 

- (NSString *) clone
{
  //NSLog(@"clone");
  return [[self copy] autorelease];
}

- (id) connect 
{ 
#if TARGET_OS_IPHONE
  return nil;
#else
  return [NSConnection rootProxyForConnectionWithRegisteredName:self host:nil];
#endif
}

- (id) connectOnHost:(NSString *)operand 
{
#if TARGET_OS_IPHONE
  return nil;
#else
  VERIF_OP_NSSTRING(@"connectOnHost:")
  return [NSConnection rootProxyForConnectionWithRegisteredName:self host:operand];
#endif
}

- (NSString *)max:(NSString *)operand
{
  VERIF_OP_NSSTRING(@"max:")
  return [self compare:operand] == NSOrderedDescending ? self : operand; 
}  

- (NSString *)min:(NSString *)operand
{
  VERIF_OP_NSSTRING(@"min:")
  return [self compare:operand] == NSOrderedDescending ? operand : self; 
}  

- (FSBoolean *)operator_equal:(id)operand
{
  return ([self isEqual:operand] ? fsTrue : fsFalse);
}    

- (FSBoolean *)operator_tilde_equal:(id)operand  
{
  return (![self isEqual:operand] ? fsTrue : fsFalse);
}

- (FSBoolean *)operator_greater:(NSString *)operand
{ 
  VERIF_OP_NSSTRING(@">")
  return [self compare:operand] == NSOrderedDescending ? fsTrue : fsFalse;
}

- (FSBoolean *)operator_greater_equal:(NSString *)operand {  
  VERIF_OP_NSSTRING(@">=")
  return [self compare:operand] != NSOrderedAscending ? fsTrue : fsFalse;  
}    

- (FSBoolean *)operator_less:(id)operand 
{
  VERIF_OP_NSSTRING(@"<")
  return [self compare:operand] == NSOrderedAscending ? fsTrue : fsFalse;  
}    
    
- (FSBoolean *)operator_less_equal:(NSString *)operand 
{
  VERIF_OP_NSSTRING(@"<=")
  return [self compare:operand] != NSOrderedDescending ? fsTrue : fsFalse;  
}   

- (NSString *)operator_plus_plus:(NSString *)operand
{
  VERIF_OP_NSSTRING(@"++");
  return [self stringByAppendingString:operand];
}  

- (NSString *)printString
{
  //return [[self class] stringWithFormat:@"\'%@\'", self]; 
  // The above instruction does not work, for an unknown reason (it raise an NSInvalidArgument exception)
  // So we use the folowing :
  return [NSMutableString stringWithFormat:@"'%@'", self];  
} 

- (NSString *)reverse
{
  NSUInteger self_length = [self length];
  unichar self_buf[self_length];
  unichar r_buf[self_length];
  NSUInteger i;
  
  [self getCharacters:self_buf];
  
  for (i=0; i < self_length; i++)
    r_buf[i] = self_buf[(self_length-i)-1]; 
  
  return [NSMutableString stringWithCharacters:r_buf length:self_length];
}

@end
