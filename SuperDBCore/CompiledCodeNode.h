/*   CompiledCodeNode.h Copyright (c) 1998-2008 Philippe Mougin. */
/*   This software is open source. See the license.   */


#import <Foundation/Foundation.h>
#import "FSMsgContext.h" 
#import "FSSymbolTable.h" 
#import "BlockRep.h"
#import "FSCNBase.h"

//enum compiledCodeNode_type {IDENTIFIER, MESSAGE, STATEMENT_LIST, OBJECT, ARRAY, TEST_ABORT, BLOCK, ASSIGNMENT, NUMBER, CASCADE};             

@class FSBlock;
@class FSPattern;
@class FSArray;
@class FSNumber;

@interface CompiledCodeNode: NSObject <NSCopying, NSCoding>
{
@public
  FSArray *subnodes;
  long firstCharIndex;
  long lastCharIndex; 
   
  enum FSCNType nodeType;
  NSString *operator;
  struct FSContextIndex identifier; // IDENTIFIER
  NSString *identifierSymbol;       // IDENTIFIER
  CompiledCodeNode  *receiver;
  NSString *selector;               // used for MESSAGE
  FSMsgContext *msgContext;
  id object;
  SEL sel;
}

+ compiledCodeNode;

- addSubnode:(CompiledCodeNode *)subnode;
- (long)firstCharIndex;
- (long)lastCharIndex;
- copy;
- copyWithZone:(NSZone *)zone;
- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (CompiledCodeNode *)getSubnode:(unsigned)pos;
//- (Array *)getListSubnode;
- init;
- (id)initWithCoder:(NSCoder *)aDecoder;
- insertSubnode:(CompiledCodeNode *)subnode at:(unsigned)pos;
- (unsigned)subnodeCount;
- setSubnode:(CompiledCodeNode *)subnode at:(unsigned)pos;
- removeSubnode:(unsigned)pos;

- (enum FSCNType) nodeType;
- (struct FSContextIndex) identifier;
- (NSString *) identifierSymbol;
- (NSString *) operatorSymbols;
- (CompiledCodeNode *)  receiver;
//- (NSString *) selector;
- (SEL) sel;
- (FSMsgContext *) msgContext;
- (id) object;
- (FSPattern *)pattern;

- setBlockRep:(BlockRep *) theBlockRep;
- setFirstCharIndex:(long)first;
- setLastCharIndex:(long)last;
- setFirstCharIndex:(long)first last:(long)last;
- setFSIdentifier:(struct FSContextIndex) theIdentifier symbol:(NSString *)theSymbol;
- setSubnodes:(FSArray *)theListSubnode;
- setMessageWithReceiver:(CompiledCodeNode *) theReceiver 
                selector:(NSString *)  theSelector
                operatorSymbols:(NSString*) theOperatorSymbols;
- setNodeType:(enum FSCNType) theNodeType;
- setNumber:(FSNumber *)theNumber;
- setobject:(id)theobject;
- setReceiver:(CompiledCodeNode*)theReceiver;

-(void)translateCharRange:(int32_t)translation;                

@end
