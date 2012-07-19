/* FSInterpreterResultPrivate.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import "FSInterpreterResult.h"

@interface FSInterpreterResult (FSInterpreterResultPrivate)

// This method may return an object initialized with other values than the ones provided. This happens when an error occurs while trying to retain the "theResult" parameter. In this case, this method returns an object representing an F-Script execution error.
+ (FSInterpreterResult *)interpreterResultWithStatus:(enum e_status)theStatus result:(id)theResult errorRange:(NSRange)theErrorRange errorMessage:(NSString *)theErrorMessage callStack:(NSArray *)theCallStack;

// This method may return an object initialized with other values than the ones provided. This happens when an error occurs while trying to retain the "theResult" parameter. In this case, this method returns an object representing an F-Script execution error.
- (FSInterpreterResult *)initWithStatus:(enum e_status)theStatus result:(id)theResult errorRange:(NSRange)theErrorRange errorMessage:(NSString *)theErrorMessage callStack:(NSArray *)theCallStack;


@end
