/*   FSPattern.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class FSArray;

@interface FSPattern:NSObject <NSCoding>
{
  int deep;
  __strong int *level;
  unsigned levelCount;
  FSPattern *nextPattern;
}

+ patternWithDeep:(int)theDeep level:(FSArray *)theLevel nextPattern:(FSPattern*)theNextPattern;
+ patternFromIntermediateRepresentation:(NSArray *)ap;

- initWithDeep:(int)theDeep level:(FSArray *)theLevel nextPattern:(FSPattern*)theNextPatter;
- (int)deep;
- (BOOL)isDoubleLoop;
- (BOOL)isSimpleLoopOnReceiver;
- (int *)level;
- (unsigned int)levelCount;
- (FSPattern *)nextPattern;
- (void) setNextPattern:(FSPattern *)theNextPattern;

- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@end
