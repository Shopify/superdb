/*   FSCompiler.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCompiler.h"
#import "FSNumber.h"
#import "FSBoolean.h"
#import "FSCompilationResult.h"
#import "FSArray.h" 
#import "FSBlock.h"
#import "MessagePatternCodeNode.h"
#import <Foundation/Foundation.h>
#import "FSSymbolTable.h"
#import <objc/objc.h> // sel_getName()
#import <objc/runtime.h>
#import "FSConstantsInitialization.h"
#import "FSMethod.h"
#import "FSCNClassDefinition.h"
#import "FSCNCategory.h"
#import "FSCNIdentifier.h"
#import "FSCNSuper.h"
#import "FSPattern.h"
#import "FSCNUnaryMessage.h"
#import "FSCNBinaryMessage.h"
#import "FSCNKeywordMessage.h"
#import "FSCNCascade.h"
#import "FSCNStatementList.h"
#import "FSCNPrecomputedObject.h"
#import "FSCNArray.h"
#import "FSCNBlock.h"
#import "FSCNAssignment.h"
#import "FSCNMethod.h"
#import "FSCNReturn.h"
#import "BlockRep.h"
#import "FSMiscTools.h"
#import "FSVoid.h"
#import "FSCNDictionary.h"


#define isnonascii(c) ((((unsigned int)(c)) & 0x80) != 0)

enum e_type_compilation {TC_STATEMENT_LIST, TC_BLOCK /*, TC_METHOD*/};

static NSString * symbol_operator_tab[256];
static NSMutableDictionary * symbol_operator_dict;

static NSMutableDictionary *constant_dict;
static char * keywords[] = {"false", "true", "NO", "YES", "nil", "super"};                               
static enum e_token_type keyword_type[] = {KW_FALSE, KW_TRUE, KW_FALSE, KW_TRUE, KW_NIL, KW_SUPER};

struct codeNodePatternElementPair
{
  FSCNBase *codeNode;
  id patternElement; 
};

struct compilationContext
{
  FSSymbolTable *symbolTable;
  NSString    *className;
  BOOL isInClassMethod;
};

static BOOL isHexadecimalDigit(char digit)
{
  switch (digit) 
  {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4': 
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':  
    case 'A':
    case 'B':
    case 'C':
    case 'D':
    case 'E':  
    case 'F':  
      return YES;
    default:
      return NO;
  }
}

static struct codeNodePatternElementPair makeCodeNodePatternElementPair(FSCNBase *codeNode, id patternElement)
{
  struct codeNodePatternElementPair r;
  
  r.codeNode = codeNode;
  r.patternElement = patternElement;
  return r;
}

static NSMutableString *operator_name(NSString *op_elements) //ex: "++" -> "_plus_plus"
{  
  char i,nb;
  NSMutableString *r = [NSMutableString stringWithCapacity:[op_elements length]*7];
  const char *op_elements_cstr = [op_elements UTF8String];
  
  for (i = 0, nb = [op_elements length]; i < nb; i++)
  {
    [r appendString:@"_"]; 
    [r appendString:symbol_operator_tab[(unsigned char)op_elements_cstr[(short)i]]];
  }
  return r;
}    

// returns nil if no mapping exists
static NSString *FSOperatorFromObjCOperatorName(NSString *operatorName)  // ex: "operator_plus_plus:" --> "++"
{
  NSScanner *scanner = [NSScanner scannerWithString:operatorName]; 
  NSString *subObjCOperatorName, *subFSOperator;
  NSMutableString *r = [NSMutableString stringWithCapacity:1];
  NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"_:"];
  
  /* first we test that the selector is in a form acceptable for an F-Script operator */
  
  [scanner setCaseSensitive:YES];   
  if (![operatorName hasPrefix:@"operator_"]) return nil;
  [scanner scanUpToString:@":" intoString:NULL];
  if (![scanner scanString:@":" intoString:NULL]) return nil;
  if ([scanner isAtEnd] == NO) return nil;
   
  /* Now, we try to construct the name of the F-Script operator from the Objective-C selector string */
  
  [scanner setScanLocation:0];
  [scanner scanString:@"operator" intoString:NULL];
  
  while ([scanner scanString:@"_" intoString:NULL])
  {  
    [scanner scanUpToCharactersFromSet:charSet intoString:&subObjCOperatorName];
    if (!(subFSOperator = [symbol_operator_dict objectForKey:subObjCOperatorName])) return nil;
    [r appendString:subFSOperator];
  } 
  return r;
}   

@interface FSCompiler(InternalMethodsFSCompiler)

- (FSCNBase *) statementListWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNBase *) statementWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNReturn *) returnStatementWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNBase *) expWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNKeywordMessage *) keywordSelWithCompilationContext:(struct compilationContext)compilationContext receiver:(FSCNBase *)receiver patternElement:(id)pattern_elt;
- (struct codeNodePatternElementPair) exp1WithCompilationContext:(struct compilationContext)compilationContext;
- (struct codeNodePatternElementPair) exp1RemainingWithCompilationContext:(struct compilationContext)compilationContext left:(FSCNBase *)left patternElement:(id)pattern_elt;
- (struct codeNodePatternElementPair) exp2WithCompilationContext:(struct compilationContext)compilationContext;
- (struct codeNodePatternElementPair) exp2RemainingWithCompilationContext:(struct compilationContext)compilationContext left:(FSCNBase *)left patternElement:(id)pattern_elt;
- (FSCNBase *) exp3WithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNPrecomputedObject *) number;
- (FSCNIdentifier *) identifierWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNArray *) arrayWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNBlock *) blockWithCompilationContext:(struct compilationContext)compilationContext parentSymbolTable:(FSSymbolTable *)symbTab;
- (FSCNDictionary *) dictionaryWithCompilationContext:(struct compilationContext)compilationContext;
- (id) patternElt;
- (FSCNMethod *)methodWithCompilationContext:(struct compilationContext)compilationContext;
- (NSString *)typeWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNBase *)methodBodyWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNClassDefinition *)classDefinitionWithCompilationContext:(struct compilationContext)compilationContext;
- (FSCNCategory *)categoryWithCompilationContext:(struct compilationContext)compilationContext;

@end 


@implementation FSCompiler

+ compiler
{
  return [[[self alloc] init] autorelease];
}

// This method returns an FSCNMethod equivalent to: - (void)dealloc { super dealloc }
+ (FSMethod *)dummyDeallocMethodForClassNamed:(NSString *)className
{
  FSSymbolTable *symbolTable = [FSSymbolTable symbolTable];
  FSCNSuper   *receiver = [[[FSCNSuper alloc] initWithLocationInContext:[symbolTable insertSymbol:@"self" object:nil status:UNDEFINED] className:className isInClassMethod:NO] autorelease];
  FSCNMessage *code     = [[[FSCNUnaryMessage alloc] initWithReceiver:receiver selectorString:@"dealloc" pattern:nil] autorelease];
  FSMethod    *method   = [[[FSMethod alloc] initWithSelector:@selector(dealloc) fsEncodedTypes:@"v@:" types:@"v@:" typesByArgument:[NSArray arrayWithObjects:@"@", @":", nil] argumentCount:2 code:code symbolTable:symbolTable] autorelease]; 
  return method;
}

+ (BOOL)isValidIdentifier:(NSString *)str
{
  const char *cstr = [str UTF8String];
  
  if (*cstr == '\0') return NO; // because must be at least one character
  
  if (isalpha(cstr[0]) || cstr[0] == '_')
  {
    cstr++;
    while (*cstr != '\0' && (isalnum(*cstr) || *cstr == '_')) cstr++;
  }    

  return *cstr == '\0';  
}

+ (void)initialize
{
  static BOOL tooLate = NO;
  if (!tooLate) 
  {
    tooLate = YES;

    if ( self == [FSCompiler class] ) 
    {
      NSInteger i;
      for(i = 0; i < 255; i++)
      {
        symbol_operator_tab[i] = nil;
      }
      symbol_operator_tab['+']  = @"plus";
      symbol_operator_tab['-']  = @"hyphen";
      symbol_operator_tab['<']  = @"less";
      symbol_operator_tab['>']  = @"greater";
      symbol_operator_tab['=']  = @"equal";
      symbol_operator_tab['*']  = @"asterisk";
      symbol_operator_tab['/']  = @"slash";
      symbol_operator_tab['?']  = @"question";
      symbol_operator_tab['~']  = @"tilde";  
      symbol_operator_tab['!']  = @"exclam";
      symbol_operator_tab['%']  = @"percent";
      symbol_operator_tab['&']  = @"ampersand";  
      symbol_operator_tab['|']  = @"bar";
      symbol_operator_tab['\\'] = @"backslash";
    
      symbol_operator_dict = [[NSMutableDictionary alloc] init];
      [symbol_operator_dict setObject:@"+"  forKey:@"plus"];
      [symbol_operator_dict setObject:@"-"  forKey:@"hyphen"];
      [symbol_operator_dict setObject:@"<"  forKey:@"less"];
      [symbol_operator_dict setObject:@">"  forKey:@"greater"];
      [symbol_operator_dict setObject:@"="  forKey:@"equal"];
      [symbol_operator_dict setObject:@"*"  forKey:@"asterisk"];
      [symbol_operator_dict setObject:@"/"  forKey:@"slash"];
      [symbol_operator_dict setObject:@"?"  forKey:@"question"];
      [symbol_operator_dict setObject:@"~"  forKey:@"tilde"];
      [symbol_operator_dict setObject:@"!"  forKey:@"exclam"];
      [symbol_operator_dict setObject:@"%"  forKey:@"percent"];
      [symbol_operator_dict setObject:@"&"  forKey:@"ampersand"];
      [symbol_operator_dict setObject:@"|"  forKey:@"bar"];
      [symbol_operator_dict setObject:@"\\" forKey:@"backslash"];
      
      constant_dict = [[NSMutableDictionary alloc] initWithCapacity:8500];
      FSConstantsInitialization(constant_dict);
    }
  }
}

+ (NSString *)stringFromSelector:(SEL)selector
{
  const char *rawCString = sel_getName(selector);
  NSString *rawString;
  NSString *r;

  NSAssert(rawCString, @"sel_get_name() returned NULL !");
  if (!rawCString) return @"FS_NULL_SELECTOR";
  
  rawString = [NSString stringWithUTF8String:rawCString];
  if ((strncmp(rawCString,"operator_", 9) == 0) && (r = FSOperatorFromObjCOperatorName(rawString)))
    return r;
  else
    return rawString;
}
 
+ (SEL)selectorFromString:(NSString *)selectorStr
{
  const char *cstr = [selectorStr UTF8String];
  if (isalpha(cstr[0]) || (cstr[0] == '_'))
    return sel_getUid(cstr);
  else if ( strcmp(cstr,"<null selector>") == 0)
    return (SEL)0;
  else
    return sel_getUid([[NSString stringWithFormat:@"operator%@:",operator_name(selectorStr)] UTF8String]);
}

- init
{
  // NSLog(@"FSCompiler init");
  
  if ((self = [super init]))
  {
    return self;
  }
  return nil;
}

- (void)dealloc
{
  // NSLog(@"FSCompiler dealloc");
  
  [errorStr release];
  [super dealloc];
}

- (void)syntaxError:(NSString *)c firstCharIndex:(NSInteger)firstCharIndex lastCharIndex:(NSInteger)lastCharIndex
{
  [errorStr autorelease]; 
  errorStr = [[@"syntax error: " stringByAppendingString:c] retain];
  errorFirstCharIndex = firstCharIndex; 
  errorLastCharIndex = lastCharIndex;
  longjmp(error_handler, 1);
}

- (void)syntaxError:(NSString *)c
{
  [self syntaxError:c firstCharIndex:token_first_char_index lastCharIndex:string_index];
}

- (void)goToNextToken
{
  while(isspace(string[string_index]) && string_index != string_size)
    string_index++;
      
  while(1)
  {
    if (isspace(string[string_index]))    
      string_index++;
    else if (string[string_index]=='\"')
    {
      string_index++;
      while (string[string_index] != '\"' && string_index != string_size)
        string_index++;
      if (string[string_index] == '\"')
        string_index++;
    }
    else break;
  }      
}    

- (void)scan
{  
  NSInteger j, k, firstDigitIndex;
  char * buf;
  
  [self goToNextToken];
  token_first_char_index = string_index;
  
  if (string_index == string_size)
  {
    rs.type = END;
    return;
  }
  
  // Check for non-ASCII characters here, that would be an error
  if (isnonascii(string[string_index])) [self syntaxError:@"Non ASCII character detected"];
  
  if (isalpha(string[string_index]) || string[string_index] == '_')
  {
    j = string_index;
    string_index++;
    while( string_index < string_size && (isalnum(string[string_index]) || string[string_index] == '_') )
      string_index++;
         
    buf = malloc(string_index-j+1);
    memcpy(buf,&(string[j]),string_index-j);
    buf[string_index-j] = '\0';
      
    for(k = 0; k < (NSInteger)(sizeof(keywords) / sizeof(char *)) && strcmp(buf, keywords[k]) != 0; k++);

    if(k == sizeof(keywords)/sizeof(char *))/*This is not a keyword */
    {
      id predefinedObject;
      rs.value = [NSMutableString stringWithUTF8String:buf];
      free(buf);
      
      // Is this a predefined constant ? 
      if ((predefinedObject = [constant_dict objectForKey:rs.value]) != nil)
      {
        // This is a predefined constant
        rs.type = PREDEFINED_OBJECT;
        rs.value = predefinedObject; 
      }
      else // This is not a predefined constant           
      {
        rs.type = NAME;
      }
    }    
    else                           /* This is a keyword */
    {
      rs.type = keyword_type[k];
      free(buf);
    }
    return;          
  }
  
  switch (string[string_index])
  {
  case '[' :rs.type = OPEN_BRACKET     ; string_index++; return;
  case ']' :rs.type = CLOSE_BRACKET    ; string_index++; return;
  case '(' :rs.type = OPEN_PARENTHESE  ; string_index++; return;
  case ')' :rs.type = CLOSE_PARENTHESE ; string_index++; return;
  case '{' :rs.type = OPEN_BRACE       ; string_index++; return;
  case '}' :rs.type = CLOSE_BRACE      ; string_index++; return;
  case ',' :rs.type = COMMA            ; string_index++; return;
  case ';' :rs.type = SEMICOLON        ; string_index++; return;
  case '@' :rs.type = AT               ; string_index++; return;
  case '.' :rs.type = PERIOD           ; string_index++; return;
  case '^' :rs.type = CARET            ; string_index++; return;
  case '#' :
  {
    j = string_index;
    string_index++;
    
    if (string[string_index] == '{')
    {
      rs.type = DICTIONARY_BEGIN;
      string_index++; 
      return;
    }
    else 
    {
      if (symbol_operator_tab[(unsigned char)string[string_index]])
      {
        if (string[string_index] == '<' && strncmp(string+string_index, "<null selector>", 15) == 0)
          string_index += 15;
        else 
          while (symbol_operator_tab[(unsigned char)string[string_index]])
            string_index++;    
      }
      else if (isalpha(string[string_index]) || string[string_index] == '_')
      {
        string_index++;
        //HH: changed ordering, might be incorrect !
        while ( string_index < string_size && (isalnum(string[string_index]) || string[string_index] == '_' || string[string_index] == ':') )
          string_index++;
      }
      else [self syntaxError:@"open brace or method selector expected"];
        
      rs.type = COMPACT_BLOCK;
      buf =  malloc(1+string_index-j);
      memcpy(buf,&(string[j]),string_index-j);
      buf[string_index-j] = '\0';
      rs.value = [NSMutableString stringWithUTF8String:buf];
      free(buf); 
      return;
    }           
  }
  case ':' :
    if (string[string_index+1] == '=')
    {
      rs.type = SASSIGNMENT ;
      string_index += 2; return; 
    }
    else         
    {
      rs.type = COLON;
      string_index ++  ; return; 
    }
  case '\'': 
    string_index++;
    j = string_index;
    while(string_index < string_size)
    {
      if (string[string_index] == '\\')
        string_index += 2;
      else if (string[string_index] == '\'')
       if (string[string_index+1] == '\'') string_index += 2;
       else                                break;
      else
        string_index++;    
    }  
    if (string_index < string_size)
    {
      rs.type = SSTRING;
      buf =  malloc(string_index-j+1);
      
      k = 0;
      while(j < string_index)
      {
        if (string[j] == '\\')
        {
          j++;
          switch (string[j])
          {
          case 'a' : buf[k] = '\a'; break;
          case 'b' : buf[k] = '\b'; break;
          case 'f' : buf[k] = '\f'; break;
          case 'n' : buf[k] = '\n'; break;
          case 'r' : buf[k] = '\r'; break;
          case 't' : buf[k] = '\t'; break;
          case 'v' : buf[k] = '\v'; break;
          case '\\': buf[k] = '\\'; break;
          case '\'': buf[k] = '\''; break;
          default  : buf[k] = '\\'; k++; buf[k] = string[j]; break;
          } 
        }  
        else if (string[j] == '\'')
        {
          NSAssert(string[j+1] == '\'', @"");
          buf[k] = string[j];
          j++;
        }
        else
          buf[k] = string[j];
        
        j++; k++;       
      }
      buf[k] = '\0';
      
      
      rs.value = [NSMutableString stringWithUTF8String:buf];
      free(buf);
   
      string_index++; 
      return;
    }
    else
    {
      [self syntaxError:@"end of string (\') missing"];
    }     
  } // end_switch
  
  if (symbol_operator_tab[(unsigned char)string[string_index]])
  {
     char ch;
  
     rs.value = [NSMutableString stringWithFormat:@"%c",string[string_index]];
     string_index++;
     ch = string[string_index];
     while(symbol_operator_tab[(unsigned char)ch])
     {
       [rs.value appendFormat:@"%c",ch];
       string_index++;
       ch = string[string_index];
     }  
     rs.type = OPERATOR;  
  }
  else if (isdigit(string[string_index]))
  {
    NSInteger exponentLetterIndex = -1;
    NSInteger hexadecimalRadixSpecifierIndex = -1;
    firstDigitIndex = string_index;
    string_index++;
    while( string_index < string_size && (isdigit(string[string_index])) )
      string_index++;
    
    if (string_index < string_size)
    {
      if (string[string_index] == 'r')
      {    
        if (string_index == firstDigitIndex+2 && string[firstDigitIndex] == '1' && string[firstDigitIndex+1] == '6')
        {
          hexadecimalRadixSpecifierIndex = firstDigitIndex;
          string_index++;
        
          if (string_index == string_size || !isHexadecimalDigit(string[string_index]))
            [self syntaxError:@"invalid number literal"];      
        
          while( string_index < string_size && (isHexadecimalDigit(string[string_index])) )
            string_index++;
        }
      }
      else
      {
        if (string[string_index] == '.' && isdigit(string[string_index+1]))
        {
          string_index++;
          while( string_index < string_size && (isdigit(string[string_index])) )
            string_index++;
        }
        
        if (string_index < string_size && (string[string_index] == 'e'|| string[string_index] == 'd' || string[string_index] == 'q'))
        {
          exponentLetterIndex = string_index;
          string_index++;
          if (string_index == string_size || (!isdigit(string[string_index]) && string[string_index] != '+' && string[string_index] != '-'))
            [self syntaxError:@"invalid number literal"];
          if (string[string_index] == '+' || string[string_index] == '-')
            string_index++;
          if (string_index == string_size || !isdigit(string[string_index]))
            [self syntaxError:@"invalid number literal"];      
          while( string_index < string_size && (isdigit(string[string_index])) )
            string_index++;
        }
      }  
    }      
    
    rs.type = SNUMBER;
    buf = malloc(string_index-firstDigitIndex+1);
    memcpy(buf, &(string[firstDigitIndex]), string_index-firstDigitIndex);
    buf[string_index-firstDigitIndex] = '\0';
    
    // Translate into a format understood by the strtod() C function used latter to get a double from the string representation of the number
    if (hexadecimalRadixSpecifierIndex != -1)
    {
      buf[hexadecimalRadixSpecifierIndex - firstDigitIndex] = '0';
      buf[1 + hexadecimalRadixSpecifierIndex - firstDigitIndex] = 'x'; 
      buf[2 + hexadecimalRadixSpecifierIndex - firstDigitIndex] = '0'; 
    }
    
    if (exponentLetterIndex != -1) buf[exponentLetterIndex - firstDigitIndex] = 'e'; 
    
    rs.value = [NSMutableString stringWithUTF8String:buf];
    free(buf);
  }        
  else
  {
    [self syntaxError:[NSString stringWithFormat:@"unknown character '%c'", string[string_index]]];    
  }                                         
}  

- (void)checkLValue:(FSCNBase *)codeNode 
{
  switch (codeNode->nodeType) 
  {
  case IDENTIFIER :
  {
    if ( [((FSCNIdentifier *)codeNode)->identifierString isEqualToString:@"sys"] ) 
    {
      [self syntaxError:@"assigment to \"sys\" is not permitted"];
    }
    break;
  }
  case ARRAY :
  {
    for (NSUInteger i = 0; i < ((FSCNArray *)codeNode)->count; i++) 
    {
      [self checkLValue:((FSCNArray *)codeNode)->elements[i]];
    }
    break;
  }
  default :
  {
    [self syntaxError:@"the left hand side of an assignment must be an identifier or an array of identifiers"];
    break;
  }
  }
}

- (void)checkToken:(enum e_token_type)type :(NSString *)str
{
  if (rs.type != type)
    [self syntaxError:str];
}  

- (FSCompilationResult *) compileCode:(const char *)utf8str withParentSymbolTable:(FSSymbolTable *)symbol_table typeCompilation:(enum e_type_compilation)typeCompilation
{
  NSInteger val; 
  FSCNBase *code;
  struct compilationContext compilationContext = {symbol_table, nil, NO};
    
  string = utf8str;
  string_index = 0;
  string_size = strlen(string);
    
  if ((val = setjmp(error_handler)) == 0)
  {
    [self scan];
    
    switch(typeCompilation)
    {
    case TC_STATEMENT_LIST:   code = [self statementListWithCompilationContext:compilationContext];
                              break;

    case TC_BLOCK:            code = [self blockWithCompilationContext:compilationContext parentSymbolTable:symbol_table];
                              break;
                              
    /*case TC_METHOD:           compilationContext = (struct compilationContext){nil};
                              code = [self methodWithCompilationContext:compilationContext];
                              break;*/
                          
                          
    default:                  code = nil; assert(0); // Not supposed to happend. It's here to supress a compilation warning.
    }         
                    
    /* NO SYNTAX ERROR */
    if (rs.type == END) 
       return [FSCompilationResult compilationResultWithType:OK errorMessage:nil errorFirstCharacterIndex:-1 errorLastCharacterIndex:-1 code:code];       
    else
    {
      errorStr = @"end of command expected";
      errorFirstCharIndex = string_index-1;
      errorLastCharIndex  = string_index;
    }          
  }
  
 /* SYNTAX ERROR DETECTED */
    
  return [FSCompilationResult compilationResultWithType:ERROR errorMessage:errorStr errorFirstCharacterIndex:errorFirstCharIndex errorLastCharacterIndex:errorLastCharIndex code:nil];
} 

- (FSCompilationResult *) compileCode:(const char *)utf8str withParentSymbolTable:(FSSymbolTable *)symbol_table
{
  return [self compileCode:utf8str withParentSymbolTable:symbol_table typeCompilation:TC_STATEMENT_LIST];
}

- (FSCompilationResult *) compileCodeForBlock:(const char *)utf8str withParentSymbolTable:(FSSymbolTable *)symbol_table
{
  return [self compileCode:utf8str withParentSymbolTable:symbol_table typeCompilation:TC_BLOCK];
}


- (FSCNBase *) statementListWithCompilationContext:(struct compilationContext)compilationContext

{
  NSMutableArray *statements = [NSMutableArray array];
  
  do
  {
    [statements addObject:[self statementWithCompilationContext:compilationContext]];
    
    if (rs.type == PERIOD) [self scan]; 
    else                   break;
  } 
  while (rs.type != CLOSE_BRACKET && rs.type != CLOSE_BRACE && rs.type != END);
  
  if (rs.type == CLOSE_BRACE)
  {
    if ( ((FSCNBase *)[statements lastObject])->nodeType == RETURN )
    {
      // If the return statement is the last statement of the method, we compile it at a simple expression 
      // in order to optimize out the non-local return machinery which is unneeded in this case 
      // (it is also unneeded in other cases, but they are not as easy to detect)

      [statements replaceObjectAtIndex:[statements count]-1 withObject:((FSCNReturn *)[statements lastObject])->expression];
    }
    else
    {
      [statements addObject: [[[FSCNPrecomputedObject alloc] initWithObject:[FSVoid fsVoid]] autorelease]];
    }
  }
  
  if ([statements count] == 1) 
    return [statements objectAtIndex:0];
  else
  {
    FSCNStatementList *result = [[[FSCNStatementList alloc] initWithStatements:statements] autorelease];
    [result setFirstCharIndex:((FSCNBase *)[statements objectAtIndex:0])->firstCharIndex lastCharIndex:((FSCNBase *)[statements lastObject])->lastCharIndex];
    return result;
  }
} 


- (FSCNBase *) statementWithCompilationContext:(struct compilationContext)compilationContext
{
  if (rs.type == CARET) 
    return [self returnStatementWithCompilationContext:compilationContext];
  else                  
    return [self expWithCompilationContext:compilationContext];
}

- (FSCNReturn *) returnStatementWithCompilationContext:(struct compilationContext)compilationContext
{
  int32_t firstCharIndex = token_first_char_index;
  
  [self checkToken:CARET :@"\"^\" expected"];
  [self scan];
  
  FSCNBase *expression = [self expWithCompilationContext:compilationContext];
  
  FSCNReturn *returnNode = [[[FSCNReturn alloc] initWithExpression:expression] autorelease];
  [returnNode setFirstCharIndex:firstCharIndex lastCharIndex:expression->lastCharIndex];
  
  return returnNode;
}

- (FSCNBase *) expWithCompilationContext:(struct compilationContext)compilationContext
{   
  struct codeNodePatternElementPair exp1_res;
  FSCNBase *node;
  BOOL messageToSuper = (rs.type == KW_SUPER);
      
  exp1_res = [self exp1WithCompilationContext:compilationContext];
  
  if (rs.type == NAME || rs.type == COLON)
  { 
    node = [self keywordSelWithCompilationContext:compilationContext receiver:exp1_res.codeNode patternElement:exp1_res.patternElement] ; 
  }
  else if (messageToSuper && exp1_res.codeNode->nodeType != UNARY_MESSAGE && exp1_res.codeNode->nodeType != BINARY_MESSAGE && exp1_res.codeNode->nodeType != KEYWORD_MESSAGE)
  {
    [self syntaxError:@"message expected"]; assert(0); return nil;
  }
  else if (rs.type == SASSIGNMENT)
  {
    int32_t firstCharIndex = token_first_char_index;
    int32_t lastCharIndex  = string_index;
    
    [self checkLValue:exp1_res.codeNode];
    [self scan];
    
    FSCNBase *right = [self expWithCompilationContext:compilationContext];
    
    FSCNAssignment *assignmentNode = [[[FSCNAssignment alloc] initWithLeft:exp1_res.codeNode right:right] autorelease];
    [assignmentNode setFirstCharIndex:firstCharIndex lastCharIndex:lastCharIndex];
    
    return assignmentNode;
  }
  else node = exp1_res.codeNode;
  
  if (rs.type == SEMICOLON)
  {
    if (node->nodeType != UNARY_MESSAGE && node->nodeType != BINARY_MESSAGE && node->nodeType != KEYWORD_MESSAGE) 
      [self syntaxError:@"no cascade expected here"];

    int32_t firstCharIndex = token_first_char_index;
    NSMutableArray *messages = [NSMutableArray arrayWithObject:node];
    FSCNBase *message;
    
    do
    {
      NSArray *patternElement;
      
      [self scan];
      patternElement = [self patternElt];
      
      switch (rs.type)
      {
      case NAME:
        if (string[string_index] == ':')  message = [self keywordSelWithCompilationContext:compilationContext receiver:nil patternElement:patternElement];
        else                              
        {
          struct codeNodePatternElementPair unaryMsg = [self exp2RemainingWithCompilationContext:compilationContext left:nil patternElement:patternElement];
          if (unaryMsg.patternElement != [NSNull null]) [self syntaxError:@"no pattern specification expected here"];
          message = unaryMsg.codeNode;  
        }
        break;
        
      case OPERATOR:
      {
        struct codeNodePatternElementPair operatorMsg = [self exp1RemainingWithCompilationContext:compilationContext left:nil patternElement:patternElement];
        if (operatorMsg.patternElement != [NSNull null]) [self syntaxError:@"no pattern specification expected here"];
        message = operatorMsg.codeNode;  
        break;
      }
      default:
        [self syntaxError:@"cascade expected"]; 
        return nil; // to suppress a useless warning
      }
      [messages addObject:message];
      
    } while (rs.type == SEMICOLON);

    FSCNCascade *cascadeNode = [[[FSCNCascade alloc] initWithReceiver:((FSCNMessage *)node)->receiver messages:messages] autorelease]; 
    [cascadeNode setFirstCharIndex:firstCharIndex lastCharIndex:message->lastCharIndex];
   
    return cascadeNode;    
  }
  else return node;  
}

- (FSCNKeywordMessage *) keywordSelWithCompilationContext:(struct compilationContext)compilationContext receiver:(FSCNBase *)receiver patternElement:(id)pattern_elt // pattern_elt may be an NSArray or [NSNull null]
{
  FSCNKeywordMessage *msg;
  NSMutableString *selstr;
  FSCNBase *argument = nil;  // = nil to avoid the "may be used uninitialized" warning
  NSMutableArray *patternElements = [NSMutableArray arrayWithObject:pattern_elt];
  FSPattern *pattern;
  int32_t firstCharIndex;
  NSInteger i, pattern_count;
  FSArray *args = (id)[FSArray array];
  NSNull * nsnull;
      
  firstCharIndex = token_first_char_index; 
  selstr = [NSMutableString stringWithCapacity:0];
  
  if (rs.type == NAME)
  {
    [selstr appendString:rs.value];
    [self scan];
    [self checkToken:COLON :@"\":\" expected"];
  }    
  
  while (rs.type == COLON)
  {
    [selstr appendString:@":"];
    [self scan];
    [patternElements addObject:[self patternElt]];
    argument = [self exp1WithCompilationContext:compilationContext].codeNode;
    [args addObject:argument];
    if (rs.type == NAME)
    {
      [selstr appendString:rs.value];
      [self scan];
      [self checkToken:COLON :@"\":\" expected"];
    }    
  }    

  for (i = 0, pattern_count = [patternElements count], nsnull = [NSNull null]; i < pattern_count; i++)
  {
    if ([patternElements objectAtIndex:i] != nsnull) break; 
  }
  
  if (i == pattern_count)
    pattern = nil;
  else
    pattern = [FSPattern patternFromIntermediateRepresentation:patternElements];  
  
  msg = [[[FSCNKeywordMessage alloc] initWithReceiver:receiver selectorString:selstr pattern:pattern arguments:args] autorelease];  
  [msg setFirstCharIndex:firstCharIndex lastCharIndex:argument->lastCharIndex];
  return msg;
}

- (struct codeNodePatternElementPair) exp1WithCompilationContext:(struct compilationContext)compilationContext
{
  struct codeNodePatternElementPair exp2_res = [self exp2WithCompilationContext:compilationContext];
  
  if (rs.type == OPERATOR)
    return [self exp1RemainingWithCompilationContext:compilationContext left:exp2_res.codeNode patternElement:exp2_res.patternElement];
  else
    return exp2_res;
}    

- (struct codeNodePatternElementPair) exp1RemainingWithCompilationContext:(struct compilationContext)compilationContext left:(FSCNBase *)left patternElement:(id)pattern_elt // pattern_elt may be an NSArray or [NSNull null]
{ 
  FSCNBinaryMessage *r;
  FSPattern *pattern; 
  NSMutableString *selectorString;
  id pattern_elt_next; // pattern_elt_next may be an NSArray or [NSNull null]
  struct codeNodePatternElementPair exp2_res;
  long firstCharIndex, lastCharIndex;
  
  [self checkToken:OPERATOR :@"operator expected"];
  firstCharIndex = token_first_char_index;
  lastCharIndex = string_index;
  
  selectorString = operator_name(rs.value);
  [selectorString insertString:@"operator" atIndex:0];
  [selectorString appendString:@":"];
  [self scan];
  pattern_elt_next = [self patternElt];
   
  if (pattern_elt == [NSNull null] && pattern_elt_next == [NSNull null])
    pattern = nil;
  else
    pattern = [FSPattern patternFromIntermediateRepresentation:[NSArray arrayWithObjects:pattern_elt, pattern_elt_next, nil]];
  
  exp2_res = [self exp2WithCompilationContext:compilationContext];          

  r = [[[FSCNBinaryMessage alloc] initWithReceiver:left selectorString:selectorString pattern:pattern argument:exp2_res.codeNode] autorelease];
  [r setFirstCharIndex:firstCharIndex lastCharIndex:lastCharIndex];
          
  if (rs.type == OPERATOR) return [self exp1RemainingWithCompilationContext:compilationContext left:r patternElement:exp2_res.patternElement];
  else                     return makeCodeNodePatternElementPair(r,exp2_res.patternElement);
}

- (struct codeNodePatternElementPair) exp2WithCompilationContext:(struct compilationContext)compilationContext
{
  FSCNBase  *exp3Node = [self exp3WithCompilationContext:compilationContext];
  NSArray *pattern_elt = [self patternElt];

  if (rs.type == NAME && string[string_index] != ':') return [self exp2RemainingWithCompilationContext:compilationContext left:exp3Node patternElement:pattern_elt];
  else                                                return makeCodeNodePatternElementPair(exp3Node, pattern_elt);
}

- (struct codeNodePatternElementPair) exp2RemainingWithCompilationContext:(struct compilationContext)compilationContext left:(FSCNBase *)left patternElement:(id)pattern_elt // pattern_elt may an NSArray or [NSNull null]
{ 
  FSCNUnaryMessage *r;
  FSPattern *pattern; 
  NSArray *pattern_elt_next;
  
  [self checkToken:NAME :@"unary message expected"];
  
  if (pattern_elt == [NSNull null]) pattern = nil;
  else                              pattern = [FSPattern patternFromIntermediateRepresentation:[NSArray arrayWithObject:pattern_elt]];
  
  r = [[[FSCNUnaryMessage alloc] initWithReceiver:left selectorString:rs.value pattern:pattern] autorelease];

  [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
  [self scan];
  
  pattern_elt_next = [self patternElt];
          
  if (rs.type == NAME && string[string_index] != ':') return [self exp2RemainingWithCompilationContext:compilationContext left:r patternElement:pattern_elt_next];
  else                                                return makeCodeNodePatternElementPair(r, pattern_elt_next);
}

/*
- (CompiledCodeNode*)exp3
{
  CompiledCodeNode  *exp4Node = [self exp4];
  
  if (rs.type == OPEN_BRACKET) return [self exp3_remaining:exp4Node];
  else                         return exp4Node;
}

- (CompiledCodeNode *) exp3_remaining:(CompiledCodeNode *)left
{
  CompiledCodeNode *indexNode;
  CompiledCodeNode *r = [CompiledCodeNode compiledCodeNode];
  
  [r setFirstCharIndex:token_first_char_index];
  [self checkToken:OPEN_BRACKET :@"\"[\" expected"];
  [self scan];
  indexNode = [self exp];
  [self checkToken:CLOSE_BRACKET :@"\"]\" expected"];
  [r setLastCharIndex:token_first_char_index];
  [r setMessageWithReceiver: left 
                   selector: @"at:"
            operatorSymbols: nil]; 
  [r addSubnode:indexNode];
  [self scan];
  
  if (rs.type == OPEN_BRACKET) return [self exp3_remaining:r];
  else                         return r;
} 
*/

- (FSCNBase *)exp3WithCompilationContext:(struct compilationContext)compilationContext
{
  FSCNBase *r ;
  
  switch (rs.type)
  {
  case NAME :
     {
        BOOL classDefinition = NO;
        
        // We determine if this is the begining of a class definition or addition, or just an identifier 
        
        // Save the scanner state
        int32_t string_index_beforeLookAhead           = string_index;
        int32_t token_first_char_index_beforeLookAhead = token_first_char_index;
        struct res_scan rs_beforeLookAhead          = rs;
        
        [self scan];
        
        if (rs.type == OPEN_BRACE)
        {
          // Restore the scanner state
          string_index           = string_index_beforeLookAhead;
          token_first_char_index = token_first_char_index_beforeLookAhead;
          rs                     = rs_beforeLookAhead;
          
          return [self categoryWithCompilationContext:compilationContext];
        }
        else
        {
          if (rs.type == COLON)
          {
            [self scan];
            if (rs.type == NAME || rs.type == KW_NIL)
            {
              [self scan];
              if (rs.type == OPEN_BRACE)
                classDefinition = YES;
            }
          }
        
          // Restore the scanner state
          string_index           = string_index_beforeLookAhead;
          token_first_char_index = token_first_char_index_beforeLookAhead;
          rs                     = rs_beforeLookAhead;

          if (classDefinition) return [self classDefinitionWithCompilationContext:compilationContext];
          else                 return [self identifierWithCompilationContext:compilationContext];      
        }
      }    
  case OPEN_PARENTHESE :
      [self scan];
      r = [self expWithCompilationContext:compilationContext];
      [self checkToken:CLOSE_PARENTHESE :@"\")\" expected"];
      [self scan];
      return r;
  
  case SNUMBER :
      return [self number]; 
      
  case OPERATOR:
      if ([rs.value isEqualToString:@"-"])
        return [self number];
      else
        [self syntaxError:[NSString stringWithFormat:@"symbol \"%@\" not valid here",rs.value]];
      return nil; // W        
  
  case COMPACT_BLOCK:
  case OPEN_BRACKET:
      return [self blockWithCompilationContext:compilationContext parentSymbolTable:compilationContext.symbolTable];
        
  case SSTRING:
      r = [[[FSCNPrecomputedObject alloc] initWithObject:[[rs.value copy] autorelease]] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r;
      
  case OPEN_BRACE:
      return [self arrayWithCompilationContext:compilationContext];
      
  case DICTIONARY_BEGIN:
      return [self dictionaryWithCompilationContext:compilationContext];
      
  case KW_NIL:
      r = [[[FSCNPrecomputedObject alloc] initWithObject:nil] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r;
  
  case KW_TRUE:
      r = [[[FSCNPrecomputedObject alloc] initWithObject:[FSBoolean fsTrue]] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r;

  case KW_FALSE:
      r = [[[FSCNPrecomputedObject alloc] initWithObject:[FSBoolean fsFalse]] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r;
 
  case KW_SUPER:
      if (compilationContext.className == nil) [self syntaxError:@"\"super\" mustn't be used outside a method definition"];   
      r = [[[FSCNSuper alloc] initWithLocationInContext:[compilationContext.symbolTable findOrInsertSymbol:@"self"] className:compilationContext.className isInClassMethod:compilationContext.isInClassMethod] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r;
  
  case PREDEFINED_OBJECT:
      r = [[[FSCNPrecomputedObject alloc] initWithObject:rs.value] autorelease];
      [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index];
      [self scan];
      return r; 
  
  default : [self syntaxError:@"expression expected"]; return nil; // W
  }                
}

- (FSCNPrecomputedObject *) number
{
  BOOL negative;
  FSCNPrecomputedObject *r;
  double val;
  int32_t firstCharIndex;
  
  if ((negative = [rs.value isEqualToString:@"-"]))
  { 
    firstCharIndex = token_first_char_index;
    [self scan];
  }
  else
    firstCharIndex = token_first_char_index;
    
  [self checkToken:SNUMBER :@"number expected"];
  val = strtod([rs.value UTF8String],(char**)NULL);
  if (val == HUGE_VAL)  [self syntaxError:@"a number literal is too big"];
  if (negative)  val = -val;
  r  = [[[FSCNPrecomputedObject alloc] initWithObject:[FSNumber numberWithDouble:val]] autorelease];
  [r setFirstCharIndex:firstCharIndex lastCharIndex:string_index];
  [self scan];
  return r;
}

- (FSCNIdentifier *) identifierWithCompilationContext:(struct compilationContext)compilationContext
{
  FSSymbolTable *currentSymbolTable;
  struct FSContextIndex index;
  FSCNIdentifier *r;
    
  [self checkToken:NAME :@"identifier expected"];    
  currentSymbolTable = compilationContext.symbolTable;
  index = [currentSymbolTable findOrInsertSymbol:rs.value]; 
  r = [[[FSCNIdentifier alloc] initWithIdentifierString:rs.value locationInContext:index] autorelease];
  [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index-1];
  [self scan];
  return r;
}    

- (FSCNArray *) arrayWithCompilationContext:(struct compilationContext)compilationContext
{
  NSMutableArray *elements = [NSMutableArray array];
  int32_t firstCharIndex = token_first_char_index;
  FSCNArray *r;
  
  [self checkToken:OPEN_BRACE :@"\"{\" expected"];
  [self scan];
  
  if (rs.type == CLOSE_BRACE)
  {
    r = [[[FSCNArray alloc] initWithElements:elements] autorelease];
    [r setFirstCharIndex:firstCharIndex lastCharIndex:string_index];  
    [self scan];
    return r;
  }    
  else [elements addObject:[self expWithCompilationContext:compilationContext]];
        
  while (rs.type == COMMA)
  {
    [self scan];
    [elements addObject:[self expWithCompilationContext:compilationContext]];
  }
  
  [self checkToken:CLOSE_BRACE :@"\"}\" expected"];
  
  r = [[[FSCNArray alloc] initWithElements:elements] autorelease];
  [r setFirstCharIndex:firstCharIndex lastCharIndex:token_first_char_index];

  [self scan];
    
  return r;
}      

- (FSCNBlock *)blockWithCompilationContext:(struct compilationContext)compilationContext parentSymbolTable:(FSSymbolTable *)symbTab
{
  FSCNBase *code;
  FSCNBlock *r;
  BlockRep *blr;
  struct BlockSignature signature = {0,YES};
  int32_t start_source_string_index = string_index-1;
  //int sign = 0;
  NSMutableString *source;
  BOOL hasArguments = NO;
  BOOL hasTemporaries = NO;
  //NSMutableArray *argumentsNames = nil;
  
  if (rs.type == COMPACT_BLOCK)
  {  
    const char *source_cstr    = [rs.value UTF8String];
    NSString   *selectorString = [rs.value substringFromIndex:1];
     
    if (isalpha(source_cstr[1]))
    {
      NSInteger i = 2;
      signature.argumentCount++;
      while(source_cstr[i])
      {
        if (source_cstr[i] == ':')
          signature.argumentCount++;
        i++;      
      }
    }
    else if (source_cstr[1] == '<' && strcmp(source_cstr, "#<null selector>") == 0)
    {
      signature.argumentCount = 0;
    }
    else
    {
      signature.argumentCount = 2;
    }
    
    signature.hasLocals = NO;
    blr = [[[BlockRep alloc] initWithCode:nil 
                              symbolTable:symbTab
                                signature:signature
                                   source:rs.value
                               isCompiled:YES
                                isCompact:YES
                                      sel:[FSCompiler selectorFromString:selectorString]
                                   selStr:selectorString] autorelease];
           
    r = [[[FSCNBlock alloc] initWithBlockRep:blr] autorelease];                          
    [r setFirstCharIndex:token_first_char_index lastCharIndex:string_index-1];   
    [self scan];
    return r;
  }
  
  [self checkToken:OPEN_BRACKET :@"\"[\" or \"#\" expected "];
  [self scan];

  if (rs.type == COLON)
  {
    symbTab = [[[FSSymbolTable alloc] initWithParent:symbTab] autorelease];
    compilationContext.symbolTable = symbTab;
    hasArguments = YES;
  
    while (rs.type == COLON)
    {
      [self scan];
      [self checkToken:NAME :@"argument name expected"];
      if ([symbTab containsSymbolAtFirstLevel:rs.value]) [self syntaxError:[NSString stringWithFormat:@"identifier \"%@\" already defined in this block",rs.value]];
      [symbTab insertSymbol:rs.value object:nil status:UNDEFINED];
      signature.argumentCount++;
      [self scan];
    }
  }

  if (hasArguments)
  {
    if (rs.type == OPERATOR)
    {
      if ([rs.value isEqualToString:@"|"]) [self scan];
      else if ([rs.value isEqualToString:@"||"]) hasTemporaries = YES;
      else [self syntaxError:@"\"|\"(end of block header) expected"];
    }
    else [self syntaxError:@"\"|\"(end of block header) expected"];
  } 
    
  if (!hasTemporaries && rs.type == OPERATOR && [rs.value isEqualToString:@"|"]) 
    hasTemporaries = YES;
    
  if (hasTemporaries)
  {
    if (!hasArguments) // When hasArguments is true, the folowing has already been done earlier
    {
      symbTab = [[[FSSymbolTable alloc] initWithParent:symbTab] autorelease];
      compilationContext.symbolTable = symbTab;
    }
    
    [self scan];
    while (rs.type == NAME)
    {
      if ([symbTab containsSymbolAtFirstLevel:rs.value]) [self syntaxError:[NSString stringWithFormat:@"identifier \"%@\" already defined in this block", rs.value]];
      [symbTab insertSymbol:rs.value object:nil status:UNDEFINED];
      [self scan];
    }
    if (rs.type == OPERATOR && [rs.value isEqualToString:@"|"])  
      [self scan];
    else
      [self syntaxError:@"\"|\"(end of local variables declaration) expected"];
  }
  
  signature.hasLocals = hasTemporaries || hasArguments;
                             
  code = [self statementListWithCompilationContext:compilationContext];
  [code translateCharRange:-start_source_string_index];  
  source = [[[NSMutableString alloc] initWithBytes:&string[start_source_string_index] 
                                            length:(string_index - start_source_string_index)                                         
                                          encoding:NSUTF8StringEncoding] autorelease];
    
  blr = [[[BlockRep alloc] initWithCode:code 
                           symbolTable:symbTab
                           signature:signature
                           source:source
                           isCompiled:YES
                           isCompact:NO
                           sel:(SEL)0
                           selStr:nil] autorelease];
    
  r = [[[FSCNBlock alloc] initWithBlockRep:blr] autorelease];                          
  [r setFirstCharIndex:start_source_string_index lastCharIndex:string_index];   

  [self checkToken:CLOSE_BRACKET :@"\"]\"(end of block) expected"];
  [self scan];
  return r;
} 

- (FSCNDictionary *) dictionaryWithCompilationContext:(struct compilationContext)compilationContext
{
  NSMutableArray *entries = [NSMutableArray array];
  int32_t firstCharIndex = token_first_char_index;
  FSCNDictionary *r;
  
  [self checkToken:DICTIONARY_BEGIN :@"\"#{\" expected"];
  [self scan];
  
  if (rs.type == CLOSE_BRACE)
  {
    r = [[[FSCNDictionary alloc] initWithEntries:entries] autorelease];
    [r setFirstCharIndex:firstCharIndex lastCharIndex:string_index];  
    [self scan];
    return r;
  }    
  else [entries addObject:[self expWithCompilationContext:compilationContext]];
        
  while (rs.type == COMMA)
  {
    [self scan];
    [entries addObject:[self expWithCompilationContext:compilationContext]];
  }
  
  [self checkToken:CLOSE_BRACE :@"\"}\" expected"];
  
  r = [[[FSCNDictionary alloc] initWithEntries:entries] autorelease];
  [r setFirstCharIndex:firstCharIndex lastCharIndex:token_first_char_index];

  [self scan];
    
  return r;
}      

- (id) patternElt
{
  NSMutableArray *r;

  if (rs.type != AT) return [NSNull null];
  
  r = (id)[NSMutableArray array];
  
  while (rs.type == AT)
  {
    if (! isdigit(string[string_index]))
    {
      [r addObject:[FSNumber numberWithDouble:1]];
      [self scan];
    }
    else
    {  
      [self scan];
      if (rs.type == SNUMBER)
      {
        FSNumber *n = [self number]->object;
        if ([n hasFrac_bool])
          [self syntaxError:@"integer expected"];
        [r addObject:n];
      }
      else
        [r addObject:[FSNumber numberWithDouble:1]];
    }    
  }
  
  return r;
}

- (FSCNMethod *)methodWithCompilationContext:(struct compilationContext)compilationContext
{
  NSMutableString *selectorString;
  unsigned short argumentCount = 2; // accounts for the 2 hidden arguments
  NSMutableString *types = [NSMutableString string];
  NSMutableString *fsEncodedTypes = [NSMutableString string];
  NSMutableArray *typesByArgument = [NSMutableArray array];
  int32_t startIndex = token_first_char_index;
  FSSymbolTable *parentSymbolTable = [FSSymbolTable symbolTable]; // Will contains identifiers other than arguments and locals variables.
                                                                  // Then, when the method gets executed, this symbol table will not be provided (we remove it in instruction (1)),
                                                                  // letting the interpreter look for instance variables, classes names, etc.   
  FSSymbolTable *symbolTable = [[[FSSymbolTable alloc] initWithParent:parentSymbolTable] autorelease];    
  [symbolTable insertSymbol:@"self" object:nil];
  //[symbolTable insertSymbol:@"_cmd" object:nil];
  
  compilationContext.symbolTable = symbolTable;
  // TODO: what about "sys" ?

  //*************** Handle the starting - or + *********** 
  [self checkToken:OPERATOR :@"method definition expected (note that method definition must start with \"-\" or \"+\")"];
  
  if      ([rs.value hasPrefix:@"-"]) compilationContext.isInClassMethod = NO;
  else if ([rs.value hasPrefix:@"+"]) compilationContext.isInClassMethod = YES;
  else                                [self syntaxError:@"method definition expected (note that method definition must start with \"-\" or \"+\")"];
  
  if ([rs.value length] > 1) [rs.value deleteCharactersInRange:NSMakeRange(0,1)];
  else [self scan];
  //******************************************************
  
  //*************** Handle the optional return type declaration **************** 
  if (rs.type == OPEN_PARENTHESE) 
  {
    NSString *type = [self typeWithCompilationContext:compilationContext];
    char fsEncodedType = FSEncode([type UTF8String]);
    
    [fsEncodedTypes appendString:[[[NSString alloc] initWithBytes:&fsEncodedType length:1 encoding:NSUTF8StringEncoding] autorelease]];
    [types          appendString:type];
  }
  else 
  {
    [fsEncodedTypes appendString:@"@"];
    [types          appendString:@"@"];
  }
  //****************************************************************************
  
  // Add the types for the two hidden parameters (self and _cmd)
  [fsEncodedTypes  appendString:@"@:"];
  [types           appendString:@"@:"];
  [typesByArgument addObject:@"@"];
  [typesByArgument addObject:@":"];

  //*************** Handle the method name and arguments **************** 
  if (rs.type == OPERATOR)
  {
    selectorString = operator_name(rs.value);   
    [selectorString insertString:@"operator" atIndex:0];
    [selectorString appendString:@":"];
    argumentCount = 3;
    [self scan];
  
    if (rs.type == OPEN_PARENTHESE) 
    {
      NSString *type = [self typeWithCompilationContext:compilationContext];
      char fsEncodedType = FSEncode([type UTF8String]);
      
      if (fsEncodedType == 'v') [self syntaxError:@"invalid type \"void\" used for argument"];      
      
      [fsEncodedTypes  appendString:[[[NSString alloc] initWithBytes:&fsEncodedType length:1 encoding:NSUTF8StringEncoding] autorelease]];    
      [types           appendString:type];
      [typesByArgument addObject:   type];
    }
    else
    {
      [fsEncodedTypes  appendString:@"@"];
      [types           appendString:@"@"];
      [typesByArgument addObject:   @"@"];
    }  

    [self checkToken:NAME :@"argument name expected"];
    if ([symbolTable containsSymbolAtFirstLevel:rs.value]) [self syntaxError:[NSString stringWithFormat:@"identifier \"%@\" already defined in this method", rs.value]];
    [symbolTable insertSymbol:rs.value object:nil status:UNDEFINED];
    [self scan];
  }   
  else if (rs.type == NAME)
  {
    selectorString = rs.value;
    [self scan];
    
    while (rs.type == COLON)
    {
      [selectorString appendString:@":"];
      argumentCount++;
      [self scan];

      if (rs.type == OPEN_PARENTHESE)
      {
        NSString *type = [self typeWithCompilationContext:compilationContext];
        char fsEncodedType = FSEncode([type UTF8String]);
        
        if (fsEncodedType == 'v') [self syntaxError:@"invalid type \"void\" used for argument"];      
        
        [fsEncodedTypes  appendString:[[[NSString alloc] initWithBytes:&fsEncodedType length:1 encoding:NSUTF8StringEncoding] autorelease]];            
        [types           appendString:type];
        [typesByArgument addObject:   type];
      }
      else
      {
        [fsEncodedTypes  appendString:@"@"];
        [types           appendString:@"@"];
        [typesByArgument addObject:   @"@"];
      }  
      
      [self checkToken:NAME :@"argument name expected"];
      if ([symbolTable containsSymbolAtFirstLevel:rs.value]) [self syntaxError:[NSString stringWithFormat:@"identifier \"%@\" already defined in this method", rs.value]];
      [symbolTable insertSymbol:rs.value object:nil status:UNDEFINED];
      [self scan];
      if (rs.type == NAME)
      {
        [selectorString appendString:rs.value];
        [self scan];
        [self checkToken:COLON :@"\":\" expected"];          
      }
    }
    if ([selectorString isEqualToString:@"retain"])
    {
      [self syntaxError:@"overriding the \"retain\" method is not supported in F-Script"];
    }
    if ([selectorString isEqualToString:@"release"])
    {
      [self syntaxError:@"overriding the \"release\" method is not supported in F-Script"];
    }
  }
  else 
  {
    [self syntaxError:@"method definition expected"]; 
    assert(0); return nil;
  }
  
  //*************** Handle the method body ****************
  
  [self checkToken:OPEN_BRACE :@"method body expected"];
  
  int32_t methodCodeFirstCharIndex = token_first_char_index + 1; // excludes the opening brace
  
  [self scan];
  
  if (rs.type == OPERATOR && [rs.value isEqualToString:@"|"]) 
  {    
    [self scan];
    while (rs.type == NAME)
    {
      if ([compilationContext.symbolTable containsSymbolAtFirstLevel:rs.value]) [self syntaxError:[NSString stringWithFormat:@"identifier \"%@\" already defined in this method", rs.value]];
      [compilationContext.symbolTable insertSymbol:rs.value object:nil status:DEFINED];
      [self scan];
    }
    if (rs.type == OPERATOR && [rs.value isEqualToString:@"|"])  
      [self scan];
    else
      [self syntaxError:@"\"|\"(end of local variables declaration) expected"];
  }
  
  FSCNBase *methodCode = [self statementListWithCompilationContext:compilationContext];
  
  [self checkToken:CLOSE_BRACE :@"\"}\"(end of method) expected"];
  
  int32_t lastCharIndex = token_first_char_index;
  
  [self scan];
      
  [methodCode translateCharRange:-methodCodeFirstCharIndex];
      
  [symbolTable setParent:nil]; // (1)
  
  SEL selector = NSSelectorFromString(selectorString);
  if (!FSIsIgnoredSelector(selector))
  {
    // We are not in presence of an "ignored selector", so we can safely call blockWithSelector:
    // (Under GC, selectors for retain, release, autorelease, retainCount and dealloc are all represented by the same special non-functional "ignored" selector)     
    [symbolTable setObject:[FSBlock blockWithSelector:NSSelectorFromString(selectorString)] forSymbol:@"_cmd"];
  }
  
  FSMethod *method = [[[FSMethod alloc] initWithSelector:NSSelectorFromString(selectorString) fsEncodedTypes:fsEncodedTypes types:types typesByArgument:typesByArgument argumentCount:argumentCount code:methodCode symbolTable:symbolTable] autorelease];
  
  FSCNMethod *r = [[[FSCNMethod alloc] initWithMethod:method isClassMethod:compilationContext.isInClassMethod] autorelease];        
  [r setFirstCharIndex:startIndex lastCharIndex:lastCharIndex];  // +1 to include the closing brace 
      
  return r;
}

- (NSString *)typeWithCompilationContext:(struct compilationContext)compilationContext
{
  NSMutableString *typeBeforePointerMarks = [NSMutableString string];
  NSMutableString *encodedtype            = [NSMutableString string];
  char *encoded;
  BOOL isCustomClass = NO;

  [self checkToken:OPEN_PARENTHESE :@"type declaration expected"];
  [self scan];
  [self checkToken:NAME :@"type declaration expected"];
  
  [typeBeforePointerMarks appendString:rs.value];
  [self scan];
  
  while (rs.type == NAME)
  {
    [typeBeforePointerMarks appendString:@" "];
    [typeBeforePointerMarks appendString:rs.value];
    [self scan];
  }
  
  if      ([typeBeforePointerMarks isEqualToString:@"id"])                        encoded = @encode(id); 
  else if ([typeBeforePointerMarks isEqualToString:@"Class"])                     encoded = @encode(Class);
  else if ([typeBeforePointerMarks isEqualToString:@"void"])                      encoded = @encode(void);
  else if ([typeBeforePointerMarks isEqualToString:@"SEL"])                       encoded = @encode(SEL);
  else if ([typeBeforePointerMarks isEqualToString:@"BOOL"])                      encoded = @encode(BOOL);
  else if ([typeBeforePointerMarks isEqualToString:@"_Bool"])                     encoded = @encode(_Bool);
  else if ([typeBeforePointerMarks isEqualToString:@"char"])                      encoded = @encode(char);
  else if ([typeBeforePointerMarks isEqualToString:@"unsigned char"])             encoded = @encode(unsigned char);
  else if ([typeBeforePointerMarks isEqualToString:@"short"])                     encoded = @encode(short);
  else if ([typeBeforePointerMarks isEqualToString:@"unsigned short"])            encoded = @encode(unsigned short);
  else if ([typeBeforePointerMarks isEqualToString:@"int"])                       encoded = @encode(int);
  else if ([typeBeforePointerMarks isEqualToString:@"unsigned int"])              encoded = @encode(unsigned int);
  else if ([typeBeforePointerMarks isEqualToString:@"long"])                      encoded = @encode(long);
  else if ([typeBeforePointerMarks isEqualToString:@"unsigned long"])             encoded = @encode(unsigned long);
  else if ([typeBeforePointerMarks isEqualToString:@"long long"])                 encoded = @encode(long long);
  else if ([typeBeforePointerMarks isEqualToString:@"unsigned long long"])        encoded = @encode(unsigned long long);
  else if ([typeBeforePointerMarks isEqualToString:@"NSInteger"])                 encoded = @encode(NSInteger);
  else if ([typeBeforePointerMarks isEqualToString:@"NSUInteger"])                encoded = @encode(NSUInteger);
  else if ([typeBeforePointerMarks isEqualToString:@"float"])                     encoded = @encode(float);
  else if ([typeBeforePointerMarks isEqualToString:@"double"])                    encoded = @encode(double);
  else if ([typeBeforePointerMarks isEqualToString:@"CGFloat"])                   encoded = @encode(CGFloat);
  else if ([typeBeforePointerMarks isEqualToString:@"NSRange"])                   encoded = @encode(NSRange);
  else if ([typeBeforePointerMarks isEqualToString:@"CGPoint"])                   encoded = @encode(CGPoint);
  else if ([typeBeforePointerMarks isEqualToString:@"CGRect"])                    encoded = @encode(CGRect);
  else if ([typeBeforePointerMarks isEqualToString:@"CGSize"])                    encoded = @encode(CGSize);
#if !TARGET_OS_IPHONE
  else if ([typeBeforePointerMarks isEqualToString:@"NSPoint"])                   encoded = @encode(NSPoint);
  else if ([typeBeforePointerMarks isEqualToString:@"NSRect"])                    encoded = @encode(NSRect);
  else if ([typeBeforePointerMarks isEqualToString:@"NSSize"])                    encoded = @encode(NSSize);
#endif
  else if ([typeBeforePointerMarks isEqualToString:@"CGAffineTransform"])         encoded = @encode(CGAffineTransform);
  else if (NSClassFromString(typeBeforePointerMarks) != nil || [typeBeforePointerMarks isEqualToString:compilationContext.className])
  {  
    if (rs.type != OPERATOR || ![rs.value hasPrefix:@"*"]) 
      [self syntaxError:[NSString stringWithFormat:@"missing \"*\" after class name \"%@\"", typeBeforePointerMarks]];
    
    isCustomClass = YES;
    encoded = @encode(id);
  }
  else
  {
    encoded = nil; // supress a warning
    [self syntaxError:[NSString stringWithFormat:@"unknown type \"%@\"", typeBeforePointerMarks]];
  }  
  
  [encodedtype appendString:[NSString stringWithUTF8String:encoded]];
  
  while (rs.type == OPERATOR)
  {
    for (NSUInteger i = (isCustomClass ? 1 : 0), length = [rs.value length]; i < length; i++)
    {
      if ([rs.value characterAtIndex:i] == '*') 
        [encodedtype insertString:@"^" atIndex:0];
      else 
        [self syntaxError:[NSString stringWithFormat:@"invalid character \"%C\" in type specification", [rs.value characterAtIndex:i]]];
    }
    [self scan];
  }
  
  [self checkToken:CLOSE_PARENTHESE :@"\")\" expected"];
  [self scan];  
  return encodedtype;
}

- (FSCNClassDefinition *)classDefinitionWithCompilationContext:(struct compilationContext)compilationContext
{
  NSString *className;
  NSString *superclassName;
  NSMutableArray *civarNames  = [NSMutableArray array];
  NSMutableArray *ivarNames   = [NSMutableArray array];
  NSMutableArray *methodNodes = [NSMutableArray array];
  FSCNClassDefinition *r;
  int32_t firstCharIndex = token_first_char_index;
  
  [self checkToken:NAME :@"class name expected"];
  className = rs.value;
  compilationContext.className = rs.value;
  
  [self scan];
  
  if (rs.type == COLON)
  {
    [self scan];
    if      (rs.type == NAME)   superclassName = rs.value;
    else if (rs.type == KW_NIL) superclassName = nil;
    else 
    {
      [self syntaxError:@"class name expected"]; 
      assert(0); return nil;
    }
    [self scan];
  }
  else superclassName = @"NSObject";
  
  [self checkToken:OPEN_BRACE :@"\"{\" expected"];
    
  [self scan];
  
  // Instance variables and class instance variables
  while (rs.type == NAME)
  { 
    NSString *name = rs.value; 
    [self scan];
       
    if (rs.type == OPEN_PARENTHESE)
    {
      [self scan];
      
      BOOL validAttribute = NO;
      
      if (rs.type == NAME && [rs.value isEqualToString:@"class"])
      {
        [self scan];
        if (rs.type == NAME && [rs.value isEqualToString:@"instance"])
        {
          [self scan];
          if (rs.type == NAME && [rs.value isEqualToString:@"variable"])
          {
            [self scan];
            if (rs.type == CLOSE_PARENTHESE)
            {
              validAttribute = YES;
              if ([civarNames containsObject:name]) [self syntaxError:[NSString stringWithFormat:@"duplicate definition of class instance variable \"%@\"", name]];
              [civarNames addObject:name];
              [self scan];
            }
          }
        }
      }
      
      if (!validAttribute)
      {
        [self syntaxError:[NSString stringWithFormat:@"invalid attribute in definition of variable \"%@\"", name]];
      }  
      
    }
    else
    {
      if ([ivarNames containsObject:name]) [self syntaxError:[NSString stringWithFormat:@"duplicate definition of instance variable \"%@\"", name]];
      [ivarNames addObject:name];
    }
  }
  
  compilationContext.symbolTable = nil;  // Code in method does not have access to identifiers defined outside the class
  
  // Method definitions
  
  while (rs.type == OPERATOR)
  {    
    FSCNMethod *newMethodNode = [self methodWithCompilationContext:compilationContext];
    
    for (FSCNMethod *methodNode in methodNodes)
    {
      if (newMethodNode->method->selector == methodNode->method->selector && newMethodNode->isClassMethod == methodNode->isClassMethod)
        [self syntaxError:[NSString stringWithFormat:@"duplicate definition of method \"%@\"", NSStringFromSelector(methodNode->method->selector)] firstCharIndex:newMethodNode->firstCharIndex lastCharIndex:newMethodNode->lastCharIndex]; 
    }
    
    [methodNodes addObject:newMethodNode];
  }
  
  [self checkToken:CLOSE_BRACE :@"method definition or \"}\" expected"];
  
  r = [[[FSCNClassDefinition alloc] initWithClassName:className superclassName:superclassName civarNames:civarNames ivarNames:ivarNames methods:methodNodes] autorelease];
  [r setFirstCharIndex:firstCharIndex lastCharIndex:token_first_char_index];
      
  [self scan];
  
  return r;
}

- (FSCNCategory *)categoryWithCompilationContext:(struct compilationContext)compilationContext
{
  NSString *className;
  FSCNCategory *r;
  int32_t firstCharIndex = token_first_char_index;
  int32_t lastCharIndex;
  NSMutableArray *methods = [NSMutableArray array];
  
  [self checkToken:NAME :@"class name expected"];
  className = rs.value;
  compilationContext.className = rs.value;
  [self scan];
  [self checkToken:OPEN_BRACE :@"\"{\" expected"];
    
  [self scan];
   
  if (rs.type == NAME) 
    [self syntaxError:@"instance variable definition not allowed here (instance variable definitions can only appear in class definitions)" firstCharIndex:token_first_char_index lastCharIndex:string_index-1]; 
        
  // Method definitions
  while (rs.type == OPERATOR)
  {
    [methods addObject:[self methodWithCompilationContext:compilationContext]];
  }
  
  [self checkToken:CLOSE_BRACE :@"method definition or \"}\" expected"];
              
  [self scan];
  
  lastCharIndex = token_first_char_index-1;

  r = [[[FSCNCategory alloc] initWithClassName:className methods:methods] autorelease];  
  [r setFirstCharIndex:firstCharIndex lastCharIndex:lastCharIndex];

  return r;
}

@end
