/*   CompilationResult.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSCNBase.h"

enum CompilationResult_type {OK,ERROR};

@interface FSCompilationResult : NSObject
{
@public
  enum CompilationResult_type type;
  NSString  *errorMessage;
  NSInteger  errorFirstCharacterIndex;
  NSInteger  errorLastCharacterIndex;
  FSCNBase  *code;
} 

+ compilationResultWithType:(enum CompilationResult_type)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last code:(FSCNBase *)theCode;

- (void)dealloc;
- initWithType:(enum CompilationResult_type)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last code:(FSCNBase *)theCode;
 
@end
