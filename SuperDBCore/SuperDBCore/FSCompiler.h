/*   FSCompiler.h Copyright (c) 1998-2009 Philippe Mougin. */
/*   This software is open source. See the license.   */


#import <Foundation/Foundation.h>
#import "FSCompilationResult.h"

@class FSSymbolTable, FSMethod;

enum e_token_type { KW_FALSE, KW_TRUE, KW_NIL, KW_SUPER, OPEN_BRACKET, CLOSE_BRACKET, NAME, END, SNUMBER, SDATE, OPEN_PARENTHESE
                  , CLOSE_PARENTHESE, COMMA, SEMICOLON, PERIOD, SSTRING, OPEN_BRACE, CLOSE_BRACE, OPERATOR, COLON
                  , SASSIGNMENT, AT, COMPACT_BLOCK, PREDEFINED_OBJECT, CARET, DICTIONARY_BEGIN};

struct res_scan
{
  enum e_token_type type;
  NSMutableString *value;
};


@interface FSCompiler:NSObject
{
  struct res_scan rs;             // current result of the lexical parsing (scanning)
  __strong const char *string;    // string to compile
  int32_t string_index;           // in order to scan the string to compile 
  int32_t token_first_char_index; // index in the string of the first character of the current token
  int32_t string_size;            // size of the string to compile 
  jmp_buf error_handler;
  NSString *errorStr;
  NSInteger errorFirstCharIndex;
  NSInteger errorLastCharIndex;
}  

+ compiler;
+ (FSMethod *)dummyDeallocMethodForClassNamed:(NSString *)className;
+ (BOOL)isValidIdentifier:(NSString *)str;
+ (NSString *)stringFromSelector:(SEL)selector;
+ (SEL)selectorFromString:(NSString *)selectorStr;

- (void) dealloc;
- init;
- (FSCompilationResult *) compileCode:(const char *)utf8str withParentSymbolTable:(FSSymbolTable *)symbol_table;
- (FSCompilationResult *) compileCodeForBlock:(const char *)utf8str withParentSymbolTable:(FSSymbolTable *)symbol_table;
//- (CompilationResult *) compileCodeForMethod:(const char *)utf8strs;

@end
