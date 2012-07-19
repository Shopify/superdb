//  FSArrayEnumerator.h Copyright (c) 2003-2009 Philippe Mougin.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>

@class FSArray;

@interface FSArrayEnumerator : NSEnumerator 
{
  FSArray *array;
  NSUInteger next;
  NSUInteger last;
  char increment;
  BOOL iterationCompleted;
}

- (void) dealloc;
- (FSArrayEnumerator *)initWithArray:(FSArray *)theArray reverse:(BOOL)reverse;
- (id)nextObject;
- (FSArray *)allObjects;

@end
