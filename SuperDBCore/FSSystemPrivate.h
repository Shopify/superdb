/*   FSSystemPrivate.h Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.       */  

#import "FSSystem.h"
#import "FSInterpreter.h"

@interface FSSystem (FSSystemPrivate)

- (FSInterpreter *)interpreter; // Will return nil if the associated interpreter no longer exists

@end
