/* FSKeyedArchiver.h Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.            */

#import <Foundation/Foundation.h>

@interface FSKeyedArchiver : NSKeyedArchiver 
{}

- (void)encodeObject:(id)object;
- (void)encodeObject:(id)object forKey:(NSString *)key;
- (void)encodeValueOfObjCType:(const char *)valueType at:(const void *)address;

@end

