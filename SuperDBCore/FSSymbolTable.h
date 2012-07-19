/*   FSSymbolTable.h Copyright (c) 1998-2008 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class FSArray;

enum FSContext_symbol_status {DEFINED, UNDEFINED};

@interface SymbolTableValueWrapper : NSObject <NSCopying , NSCoding>
{
@public
  enum FSContext_symbol_status status;
  id value;
  NSString *symbol;
  NSUInteger retainCount;
}   

- (id)copy;

- (id)copyWithZone:(NSZone *)zone;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)initWithCoder:(NSCoder *)coder;

- initWrapperWithValue:(id)theValue symbol:(NSString *)theSymbol;

- initWrapperWithValue:(id)theValue symbol:(NSString *)theSymbol status:(enum FSContext_symbol_status)theStatus;
// symbol is not copied.

- (void)setValue:(id)theValue;

- (enum FSContext_symbol_status)status;

- (NSString *)symbol;

- (id)value;
@end

struct FSContextIndex
{
 int index;
 int level;
}; 

struct FSContextValueWrapper
{
  enum FSContext_symbol_status status;
  id value;
  NSString *symbol;
};

@interface FSSymbolTable : NSObject <NSCopying , NSCoding>
{
@package
  __strong struct FSContextValueWrapper *locals;
  NSUInteger localCount;
  BOOL receiverRetained; // When entering a method, the symbol table for this method does not retain the object associated with the "self" symbol 
                         // (i.e., the receiver), as it might not be initialized yet (if we are entering in a init... method). This BOOL will
                         // be set to NO. The F-Script run-time will then retain the receiver as soon as it determine that it is okay and set this 
                         // boolean to YES in order to remember the job has been done and thus avoid over retaining.  

@private
  NSUInteger retainCount;
  FSSymbolTable *parent;
  BOOL tryToAttachWhenDecoding;
}

+ (void)initialize;
+ symbolTable;

- (FSArray *)allDefinedSymbols;

- (BOOL) containsSymbolAtFirstLevel:(NSString *)theKey;

- (id)copy;
- (id)copyWithZone:(NSZone *)zone;

- (void)dealloc;

- (void) didSendDeallocToSymbolAtIndex:(struct FSContextIndex)index;

- (void)encodeWithCoder:(NSCoder *)coder;

- (struct FSContextIndex)findOrInsertSymbol:(NSString*)theKey; 
// Find the symbol or insert it in the highest parent possible (or in self if we don't have a parent)

- (struct FSContextIndex)indexOfSymbol:(NSString *)theKey;
// Note : field "index" of the result is set to -1 if symbol is not found

- init;
- initWithParent:(FSSymbolTable *)theParent;
- initWithParent:(FSSymbolTable *)theParent tryToAttachWhenDecoding:(BOOL)shouldTry;
- initWithParent:(FSSymbolTable *)theParent tryToAttachWhenDecoding:(BOOL)shouldTry locals:(struct FSContextValueWrapper *)theLocals localCount:(NSUInteger)theLocalCount;

- (id)initWithCoder:(NSCoder *)coder;

- (struct FSContextIndex)insertSymbol:(NSString*)theKey object:(id)theObject;
                                   
- (struct FSContextIndex)insertSymbol:(NSString*)theKey object:(id)theObject status:(enum FSContext_symbol_status)theStatus; // theKey is not copied

- (BOOL) isEmpty;

- objectForIndex:(struct FSContextIndex)index isDefined:(BOOL *)isDefined;

- (id)objectForSymbol:(NSString *)symbol found:(BOOL *)found; // foud may be passed as NULL

- (FSSymbolTable *) parent;

- (void)removeAllObjects;

- (void)setObject:(id)object forSymbol:(NSString *)symbol;

- (void)setParent:(FSSymbolTable *)theParent;

- (void)setToNilSymbolsFrom:(NSUInteger)ind;

- setObject:(id)theValue forIndex:(struct FSContextIndex)theIndex;

- (NSString *)symbolForIndex:(struct FSContextIndex)index;

- (void) undefineSymbolAtIndex:(struct FSContextIndex)index;

- (void) willSendReleaseToSymbolAtIndex:(struct FSContextIndex)index;

@end
