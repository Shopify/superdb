/* StrBuffer.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

/* 
A circular storage for NSString objects.

The capacity is fixed at instance initialization and can't change.

Each instance keeps an internal "cursor" pointing to a position of its storage.
This cursor can be moved to a desired position with various methods. The cursor moves 
in a circular way: if you move the cursor forward enough then you will reach your 
starting point again. 

The method -getStr returns the string at the position designed by the cursor.

A string is added with the -addStr: method. Strings are always added with a FIFO scheme.
The cursor concept applies only for getting string, not for adding. Also note that getting
a string does not remove it from the storage. Strings are removed from the store following
the FIFO scheme: when the store is full and a new string is added, then the "oldest" string in the
store is removed.

*/

#import <Foundation/Foundation.h>

@interface FSCommandHistory : NSObject <NSCoding>
{
  NSMutableArray *array;  // an array of NSString
  NSInteger head, queue, cursor;
}

- addStr:(NSString *)str; // adds a string
- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)coder;
- goToFirst;              // move the cursor to the most recently added string
- goToLast;               // move the cursor to the least recently added string               
- goToNext;               // move the cursor forward
- goToPrevious;           // move the cursor backward
- (NSString *)getMostRecentlyInsertedStr; // get the most recently inserted (i.e. added) string
- (NSString *)getStr;     // get the string for at the current cursor position
- init;
- (id)initWithCoder:(NSCoder *)coder;
- initWithUIntSize:(NSUInteger)size;  // designated initializer. The capacity of the receiver is
                                        // set to the value of the argument. The receiver is filled
                                        // with empty strings.
- (NSInteger)size;

@end
