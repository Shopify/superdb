/*   CompiledCodeNode.m Copyright (c) 1998-2008 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "CompiledCodeNode.h"
#import "FSSymbolTable.h"
#import <Foundation/Foundation.h> 
#import "FSBlock.h"
#import "FSUnarchiver.h"
#import "FSKeyedUnarchiver.h"
#import "FSArray.h"
#import "MessagePatternCodeNode.h"
#import "FSNumber.h"
#import "FSCNIdentifier.h"
#import "FSCNUnaryMessage.h"
#import "FSCNBinaryMessage.h"
#import "FSCNKeywordMessage.h"
#import "FSCNCascade.h"
#import "FSCNStatementList.h"
#import "FSCNPrecomputedObject.h"
#import "FSCNArray.h"
#import "FSCNBlock.h"
#import "FSCNAssignment.h"
#import "FScriptFunctions.h"


@implementation CompiledCodeNode

+ compiledCodeNode
{ return [[[self alloc] init] autorelease]; }

- addSubnode:(CompiledCodeNode *)subnode
{
  assert(subnode != nil);
  [subnodes addObject:subnode];
  return self;
}  


- (NSString *)description
{
  NSMutableString *r;
  NSString *type;
  unsigned i;

  switch (nodeType)
  {
    case IDENTIFIER:     type = @"IDENTIFIER"; break;
    case MESSAGE:        type = @"MESSAGE"; break;
    case STATEMENT_LIST: type = @"STATEMENT_LIST"; break;  
    case NUMBER:         type = @"NUMBER"; break;
    case BLOCK :         type = @"BLOCK"; break;   
    case OBJECT :        type = @"OBJECT"; break;
    case ARRAY :         type = @"ARRAY"; break;
    case TEST_ABORT:     type = @"TEST_ABORT"; break;
    case ASSIGNMENT:     type = @"ASSIGNMENT"; break;
    case CASCADE:        type = @"CASCADE"; break;
    default: assert(0);
  }

  r = [NSMutableString stringWithFormat:@"\n****************************\n%@: type = %@, firstCharIndex = %d, lastCharIndex = %d", [self class], type, firstCharIndex, lastCharIndex];

  switch (nodeType)
  {
    case IDENTIFIER:
      [r appendFormat:@", identifier = (%d,%d), identifierSymbol = %@", identifier.level,identifier.index, identifierSymbol];
      break;

    case MESSAGE:
      [r appendFormat:@", selector = %@, \n------- receiver = %@ --------", selector, receiver];
      if ([self isKindOfClass:[MessagePatternCodeNode class]])
        [r appendFormat:@", pattern = %@", [(MessagePatternCodeNode *)self pattern]];
      break;

    case NUMBER:
    case BLOCK :        
    case OBJECT :
      [r appendFormat:@", object = %@", object];
      break;

    case CASCADE:
      [r appendFormat:@", ------- receiver = %@ -------", receiver];
      break;
      
    default:
      break;
  }

  [r appendFormat:@", \n subnodeList ( %d elements)", [subnodes count]];

  for (i = 0; i < [subnodes count]; i++)
    [r appendString:[[subnodes objectAtIndex:i] description]];  

  return r;
}

- (long)firstCharIndex
{ return firstCharIndex; }

- (long)lastCharIndex
{ return lastCharIndex; } 

- copy
{ return [self retain]; /*return [self copyWithZone:NULL]; */ }

- copyWithZone:(NSZone *)zone
{
  return [self retain];
}           

-(void)dealloc
{
  // printf("\nCompiledCodeNode dealloc");
  [subnodes release];
  switch (nodeType) 
  {
  case MESSAGE        : [operator release]; [msgContext release];
                        [receiver release]; [selector release];break;
  case NUMBER         :
  case BLOCK          :                         
  case OBJECT         : [object release];break;
  case IDENTIFIER     : [identifierSymbol release]; break;
  case CASCADE        : [receiver release]; break; 
  default             : break;
  }        
  [super dealloc];
}        
    
- (void)encodeWithCoder:(NSCoder *)coder
{
  if ( [coder allowsKeyedCoding] ) 
  {
    [coder encodeDouble:firstCharIndex forKey:@"firstCharIndex"];
    [coder encodeDouble:lastCharIndex forKey:@"lastCharIndex"];
    [coder encodeInt:nodeType forKey:@"nodeType"];
    
    switch (nodeType)
    {
    case IDENTIFIER:
      [coder encodeInt:identifier.index forKey:@"identifier.index"];
      [coder encodeInt:identifier.level forKey:@"identifier.level"]; 
      [coder encodeObject:identifierSymbol forKey:@"identifierSymbol"];
      break;
      
    case MESSAGE:
      [coder encodeObject:operator forKey:@"operator"];
      [coder encodeObject:receiver forKey:@"receiver"];
      [coder encodeObject:selector forKey:@"selector"];
      break;
  
    case NUMBER:
    case BLOCK :        
    case OBJECT :
      [coder encodeObject:object forKey:@"object"];
      break;
  
    case CASCADE:
      [coder encodeObject:receiver forKey:@"receiver"]; break;
    default:
      break;
    }
    [coder encodeObject:subnodes forKey:@"subnodes"];
  }
  else
  {
    [coder encodeValueOfObjCType:@encode(typeof(firstCharIndex)) at:&firstCharIndex];
    [coder encodeValueOfObjCType:@encode(typeof(lastCharIndex)) at:&lastCharIndex];
    [coder encodeValueOfObjCType:@encode(typeof(nodeType)) at:&nodeType];
    
    switch (nodeType)
    {
    case IDENTIFIER:
      [coder encodeValueOfObjCType:@encode(typeof(identifier)) at:&identifier];
      [coder encodeObject:identifierSymbol];
      break;
      
    case MESSAGE:
      [coder encodeObject:operator];
      [coder encodeObject:receiver];
      [coder encodeObject:selector];
      break;
  
    case NUMBER:
    case BLOCK :        
    case OBJECT :
      [coder encodeObject:object];
      break;
  
    case CASCADE:
      [coder encodeObject:receiver]; break;
    default:
      break;
    }
    [coder encodeObject:subnodes];
  }    
} 

-(id)awakeAfterUsingCoder:(NSCoder *)coder
{
  FSCNBase *r;
  
  switch (nodeType)
  {
    case IDENTIFIER:
      r = [[FSCNIdentifier alloc] initWithIdentifierString:identifierSymbol locationInContext:identifier];
      break;
      
    case MESSAGE:
      if (operator != nil) 
        r = [[FSCNBinaryMessage alloc] initWithReceiver:(id)receiver selectorString:selector pattern:[self pattern] argument:[subnodes objectAtIndex:0]];
      else if ([subnodes count] == 0)
        r = [[FSCNUnaryMessage alloc] initWithReceiver:(id)receiver selectorString:selector pattern:[self pattern]];
      else
        r = [[FSCNKeywordMessage alloc] initWithReceiver:(id)receiver selectorString:selector pattern:[self pattern] arguments:subnodes];  
      break; 

    case BLOCK:
      r = [[FSCNBlock alloc] initWithBlockRep:object];
      break;
      
    case NUMBER:
    case OBJECT:
      r = [[FSCNPrecomputedObject alloc] initWithObject:object];
      break;

    case ARRAY:
      r = [[FSCNArray alloc] initWithElements:subnodes];
      break;
    
    case CASCADE:
      r = [[FSCNCascade alloc] initWithReceiver:(id)receiver messages:subnodes];
      break;
    
    case STATEMENT_LIST:
      r = [[FSCNStatementList alloc] initWithStatements:subnodes];
      break;
    
    case ASSIGNMENT:
      r = [[FSCNAssignment alloc] initWithLeft:[subnodes objectAtIndex:0] right:[subnodes objectAtIndex:1]];
      break;
    default:
      FSExecError(@"Internal error in method awakeAfterUsingCoder in class CompiledCodeNode");  
  }  
  [r setFirstCharIndex:firstCharIndex lastCharIndex:lastCharIndex];
  [self autorelease];
  return r; 
}

 
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  
  if ( [coder allowsKeyedCoding] ) 
  {
    firstCharIndex = [coder decodeDoubleForKey:@"firstCharIndex"];
    lastCharIndex  = [coder decodeDoubleForKey:@"lastCharIndex"];
    nodeType         = [coder decodeIntForKey:@"nodeType"];
    
    switch (nodeType)
    {
    case IDENTIFIER:
      identifier.index = [coder decodeIntForKey:@"identifier.index"];
      identifier.level = [coder decodeIntForKey:@"identifier.level"]; 
      identifierSymbol = [[coder decodeObjectForKey:@"identifierSymbol"] retain];

      if ([coder isKindOfClass:[FSKeyedUnarchiver class]])
      { 
        identifier = [[(FSKeyedUnarchiver*)coder  symbolTableForCompiledCodeNode] findOrInsertSymbol:identifierSymbol];      
      }
      break;
      
    case MESSAGE:
      operator  = [[coder decodeObjectForKey:@"operator"] retain];
      receiver  = [[coder decodeObjectForKey:@"receiver"] retain];
      selector  = [[coder decodeObjectForKey:@"selector"] retain];
      sel = sel_registerName([selector UTF8String]);
      msgContext = [[FSMsgContext alloc] init];
      break;
  
    case NUMBER:
    case BLOCK :
    case OBJECT :
      object = [[coder decodeObjectForKey:@"object"] retain];
      break;
  
    case CASCADE:
      receiver = [[coder decodeObjectForKey:@"receiver"] retain];
      break;
    
    default:
      break;    
    }
    subnodes = [[coder decodeObjectForKey:@"subnodes"] retain];
  }
  else
  {
    [coder decodeValueOfObjCType:@encode(typeof(firstCharIndex)) at:&firstCharIndex];
    [coder decodeValueOfObjCType:@encode(typeof(lastCharIndex)) at:&lastCharIndex];
    [coder decodeValueOfObjCType:@encode(typeof(nodeType)) at:&nodeType];
    
    switch (nodeType)
    {
    case IDENTIFIER:
      [coder decodeValueOfObjCType:@encode(typeof(identifier)) at:&identifier];
      identifierSymbol = [[coder decodeObject] retain];
      if ([coder isKindOfClass:[FSUnarchiver class]])
      { 
        /* NSRange range;
        NSString *symbol;
        
        range.location = firstCharIndex;
        range.length = 1 + lastCharIndex - firstCharIndex;
        
        symbol = [[(FSUnarchiver*)coder source] substringWithRange:range]; */
        identifier = [[(FSUnarchiver*)coder  symbolTableForCompiledCodeNode] findOrInsertSymbol:identifierSymbol];      
      }
      break;
      
    case MESSAGE:
      operator  = [[coder decodeObject] retain];
      receiver  = [[coder decodeObject] retain];
      selector  = [[coder decodeObject] retain];
      sel = sel_registerName([selector UTF8String]);
      msgContext = [[FSMsgContext alloc] init];
      break;
  
    case NUMBER:
    case BLOCK :
    case OBJECT :
      object = [[coder decodeObject] retain];
      break;
  
    case CASCADE:
      receiver = [[coder decodeObject] retain];
      break;
    
    default:
      break;    
    }
    subnodes = [[coder decodeObject] retain];
  }  
  return self;
}       
       
- (CompiledCodeNode *)getSubnode:(unsigned)pos
{
  //assert(pos >= 0 && pos < [subnodes count]);
  return [subnodes objectAtIndex:pos];
}  

/*- (Array *)getListSubnode
{
  return subnodes;
} */ 
  
- init
{
  if ((self = [super init]))
  {
    subnodes = [[FSArray alloc] init];
    firstCharIndex = -1;
    lastCharIndex = -1;
    return self;
  }
  return nil;    
}  
    
- insertSubnode:(CompiledCodeNode *)subnode at:(unsigned)pos
{
  [subnodes insertObject:subnode atIndex:pos];
  return self;
}  

- (unsigned)subnodeCount
{
  return [subnodes count];
}  

- setFirstCharIndex:(long)first
{ firstCharIndex = first; return self; }

- setLastCharIndex:(long)last
{ lastCharIndex = last; return self; }

- setFirstCharIndex:(long)first last:(long)last
{
  firstCharIndex = first;
  lastCharIndex = last;
  return self;
}  

- setSubnode:(CompiledCodeNode *)subnode at:(unsigned)pos
{
  [subnodes replaceObjectAtIndex:pos withObject:subnode];
  return self;
}  

- removeSubnode:(unsigned)pos
{
  [subnodes removeObjectAtIndex:pos];
  return self;
}

- (enum FSCNType) nodeType         { return nodeType ;}

- (NSString*)                  operatorSymbols  { return operator ;}

- (struct FSContextIndex)    identifier       { return identifier;}

- (NSString *)                 identifierSymbol {return identifierSymbol;}

- (CompiledCodeNode *)         receiver         { return receiver;}

//- (NSString *)                 selector         { return selector;} 

- (id)                         object           {return object;}

- (FSPattern *)                  pattern          {return nil;}

- (SEL) sel
{
  return sel;
}  

- (FSMsgContext *) msgContext
{
  return msgContext;
}  

- setBlockRep:(BlockRep *) theBlockRep
{
  nodeType = BLOCK;
  object = [theBlockRep retain];
  return self;
} 

- setFSIdentifier:(struct FSContextIndex) theIdentifier symbol:(NSString*)theSymbol
{ 
  nodeType = IDENTIFIER;
  identifier = theIdentifier;
  identifierSymbol = [theSymbol retain];
  return self; 
}

- setSubnodes:(FSArray *)theListSubnode
{
  [subnodes autorelease];
  subnodes = [theListSubnode retain];
  return self;
}

- setMessageWithReceiver:(CompiledCodeNode *) theReceiver 
                selector:(NSString *)  theSelector
                operatorSymbols:(NSString*) theOperatorSymbols
{
  nodeType = MESSAGE;
  operator = [theOperatorSymbols retain];
  receiver  = [theReceiver retain];
  selector  = [theSelector retain];
  sel = sel_registerName([selector UTF8String]);
  msgContext = [[FSMsgContext alloc] init];
  return self;
}

- setNodeType:(enum FSCNType) theNodeType
{
  nodeType = theNodeType;
  return self;
}  

- setNumber:(FSNumber *)theNumber
{
  nodeType = NUMBER;
  object = [theNumber retain];
  return self;
}

- setobject:(id)theobject
{
  nodeType = OBJECT;
  object = [theobject retain];
  return self;
}            

- setReceiver:(CompiledCodeNode*)theReceiver
{
  receiver = [theReceiver retain];
  return self;
}          

-(void)translateCharRange:(int32_t)translation
{
  long nb,i;
  
  firstCharIndex += translation; lastCharIndex += translation;
  if (nodeType == MESSAGE)
    [receiver translateCharRange:translation];
  for (i = 0, nb = [subnodes count]; i <nb; i++)
    [[subnodes objectAtIndex:i] translateCharRange:translation];  
}                  

@end
