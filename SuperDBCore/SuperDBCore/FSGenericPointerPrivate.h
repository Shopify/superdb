/*   FSGenericPointerPrivate.h Copyright (c) 2004-2009 Philippe Mougin.   */
/*   This software is open source. See the license.    */  

#import "FSGenericPointer.h"

@interface FSGenericPointer (Private)
- (id) initWithCPointer:(void *)p freeWhenDone:(BOOL)free type:(const char *)t;  // designated initializer. t is copied.
- (NSArray *)memoryContent;
- (NSString *)memoryContentUTF8;
@end
