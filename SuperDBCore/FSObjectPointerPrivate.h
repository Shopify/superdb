/*   FSObjectPointerPrivate.h Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.    */  

#import "FSObjectPointer.h"

@interface FSObjectPointer (Private)
- (void) autoreleaseAll;
- (id)   initWithCPointer:(void *)p  count:(size_t)c; // designated initializer
- (NSArray *)memoryContent;
- (void) retainAll;
@end
