/* FSInterpreterPrivate.h Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 

#import "FSInterpreter.h"
#import "FSObjectBrowserButtonCtxBlock.h"

@interface FSInterpreter(FSInterpreterPrivate)

- (FSObjectBrowserButtonCtxBlock *)objectBrowserButtonCtxBlockFromString:(NSString *)source;

@end
