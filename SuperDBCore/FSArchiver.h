/* FSArchiver.h Copyright (c) 2001-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
@interface FSArchiver : NSKeyedArchiver 
#else
@interface FSArchiver : NSArchiver 
#endif
{}

- (void)encodeValueOfObjCType:(const char *)valueType at:(const void *)address;

@end
