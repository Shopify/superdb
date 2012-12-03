/*   FSNSFileHandle.m Copyright (c) 2009 Philippe Mougin.  */
/*   This software is open source. See the license.        */  

#import "FSNSFileHandle.h"
#import "FScriptFunctions.h"

@implementation NSFileHandle (FSNSFileHandle)

- (void) print:(NSString *)string
{
  FSVerifClassArgsNoNil(@"print:", 1, string, [NSString class]);
  [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
