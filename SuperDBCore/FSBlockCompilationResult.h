/*   FSBlockCompilationResult.m Copyright (c) 2006 Philippe Mougin.  */
/*   This software is open source. See the license.  */  


#import <Foundation/Foundation.h>

enum FSBlockCompilationResultType {FSOKBlockCompilationResultType, FSErrorBlockCompilationResultType};

@interface FSBlockCompilationResult : NSObject 
{
@public
  enum FSBlockCompilationResultType type;
  NSString *errorMessage;
  NSInteger errorFirstCharacterIndex;
  NSInteger errorLastCharacterIndex;
} 


+ blockCompilationResultWithType:(enum FSBlockCompilationResultType)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last;

- (void)dealloc;
- initWithType:(enum FSBlockCompilationResultType)theType errorMessage:(NSString *)theErrorMessage errorFirstCharacterIndex:(NSInteger)first errorLastCharacterIndex:(NSInteger)last;

@end
