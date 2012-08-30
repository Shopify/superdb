/* FSTranscript.h Copyright (c) 2008-2009 Philippe Mougin. */ 
/* This software is open source. See the license. */

#import "FSTranscript.h"

static FSTranscript *sharedTranscript = nil;

@implementation FSTranscript

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate ) 
  {
    tooLate = YES;
    sharedTranscript = [[FSTranscript alloc] init];
  }
}

+ (FSTranscript *)sharedTranscript
{
  return sharedTranscript;
}

@end
