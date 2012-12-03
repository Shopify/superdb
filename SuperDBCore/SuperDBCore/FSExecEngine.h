
/*   FSExecEngine.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.     */   

#import "FSSymbolTable.h"
#import "FSMsgContext.h"

@class NSException;
@class FSCNBase;
@class FSPattern;
@class FSBlock;
@class FSObjectPointer;

struct res_exec
{
 NSInteger errorFirstCharIndex;
 NSInteger errorLastCharIndex;
 NSString *errorStr;
 id exception;
 id result;
};

union ObjCValue
{
  id                 idValue;
  Class              ClassValue;
  SEL                SELValue;
  _Bool              _BoolValue;
  char               charValue;
  unsigned char      unsignedCharValue;
  short              shortValue;
  unsigned short     unsignedShortValue;
  int                intValue;
  unsigned int       unsignedIntValue;
  long               longValue;
  unsigned long      unsignedLongValue;
  long long          longLongValue;
  unsigned long long unsignedLongLongValue;
  float              floatValue;
  double             doubleValue;
  NSRange            NSRangeValue;
  CGSize             CGSizeValue;
  CGPoint            CGPointValue;
  CGRect             CGRectValue;
#if !TARGET_OS_IPHONE
  NSSize             NSSizeValue;
  NSPoint            NSPointValue;
  NSRect             NSRectValue;
#endif
  CGAffineTransform  CGAffineTransformValue;
  void *             voidPtrValue;  
};


enum FSMapType {FSMapArgument, FSMapReturnValue, FSMapDereferencedPointer, FSMapIVar};

void FSMapFromObject(void *valuePtr, NSUInteger index, char fsEncodedType, id object, enum FSMapType mapType, NSUInteger argumentNumber, SEL selector, NSString *ivarName, FSObjectPointer **mappedFSObjectPointerPtr);

id FSMapToObject(void *valuePtr, NSUInteger index, char fsEncodedType, const char *foundationStyleEncodedType, NSString *unsuportedTypeErrorMessage, NSString *ivarName);

struct res_exec execute(FSCNBase *codeNode, FSSymbolTable *symbolTable); // may raise 

struct res_exec executeForBlock(FSCNBase *codeNode, FSSymbolTable *symbolTable, FSBlock* executedBlock); // may raise

id execute_rec(FSCNBase *codeNode, FSSymbolTable *localSymbolTable, NSInteger *errorFirstCharIndexPtr, NSInteger *errorLastCharIndexPtr);  

id sendMsg(id receiver, SEL selector, NSUInteger argumentCount, id *args,FSPattern* pattern,FSMsgContext *msgContext, Class ancestorToStartWith);

id sendMsgNoPattern(id receiver, SEL selector, NSUInteger argumentCount, id *args,FSMsgContext *msgContext, Class ancestorToStartWith);

id sendMsgPattern(id receiver, SEL selector, NSUInteger argumentCount, id *args,FSPattern* pattern,FSMsgContext *msgContext, Class ancestorToStartWith);
